#!/usr/bin/env python3
import datetime
import hashlib
import hmac
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request


SERVICE = "ecs"
METHOD = "GET"
CANONICAL_URI = "/"
ALGORITHM = "HMAC-SHA256"


def require_env(name):
    value = os.environ.get(name, "").strip()
    if not value:
        raise RuntimeError(f"{name} is required")
    return value


def optional_env(name, default=""):
    value = os.environ.get(name, "").strip()
    return value if value else default


def normalize_bool(value):
    return "true" if str(value).lower() == "true" else "false"


def normalize_endpoint(endpoint):
    endpoint = endpoint.strip()
    if endpoint.startswith("https://") or endpoint.startswith("http://"):
        endpoint = urllib.parse.urlparse(endpoint).netloc
    endpoint = endpoint.rstrip("/")
    if "/" in endpoint or not endpoint:
        raise RuntimeError("ECS_ENDPOINT must be a host name, such as ecs.cn-guilin-boe.volcengineapi-test.com")
    return endpoint


def quote(value):
    return urllib.parse.quote(str(value), safe="-_.~")


def canonical_query_string(params):
    return "&".join(f"{quote(key)}={quote(value)}" for key, value in sorted(params.items()))


def sign(key, msg):
    return hmac.new(key, msg.encode("utf-8"), hashlib.sha256).digest()


def signing_key(secret_key, date_stamp, region, service):
    key_date = sign(secret_key.encode("utf-8"), date_stamp)
    key_region = sign(key_date, region)
    key_service = sign(key_region, service)
    return sign(key_service, "request")


def signed_headers(headers):
    normalized = {key.lower(): " ".join(value.strip().split()) for key, value in headers.items()}
    header_names = sorted(normalized)
    canonical_headers = "".join(f"{key}:{normalized[key]}\n" for key in header_names)
    return canonical_headers, ";".join(header_names)


def build_authorization(access_key, secret_key, region, date_stamp, x_date, headers, query):
    canonical_headers, signed_header_names = signed_headers(headers)
    canonical_request = "\n".join(
        [
            METHOD,
            CANONICAL_URI,
            query,
            canonical_headers,
            signed_header_names,
            headers["X-Content-Sha256"],
        ]
    )

    credential_scope = f"{date_stamp}/{region}/{SERVICE}/request"
    string_to_sign = "\n".join(
        [
            ALGORITHM,
            x_date,
            credential_scope,
            hashlib.sha256(canonical_request.encode("utf-8")).hexdigest(),
        ]
    )
    signature = hmac.new(
        signing_key(secret_key, date_stamp, region, SERVICE),
        string_to_sign.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()

    return (
        f"{ALGORITHM} Credential={access_key}/{credential_scope}, "
        f"SignedHeaders={signed_header_names}, Signature={signature}"
    )


def parse_response(body):
    if not body:
        return {}
    try:
        return json.loads(body.decode("utf-8"))
    except json.JSONDecodeError:
        return {"RawBody": body.decode("utf-8", errors="replace")}


def response_metadata(payload):
    metadata = payload.get("ResponseMetadata") if isinstance(payload, dict) else None
    return metadata if isinstance(metadata, dict) else {}


def extract_request_id(payload):
    metadata = response_metadata(payload)
    return metadata.get("RequestId") or metadata.get("RequestID") or ""


def extract_error(payload):
    error = response_metadata(payload).get("Error")
    if isinstance(error, dict):
        code = error.get("Code") or error.get("CodeN") or "UnknownError"
        message = error.get("Message") or ""
        return code, message
    return "", ""


def fail_with_openapi_error(status, payload):
    request_id = extract_request_id(payload)
    code, message = extract_error(payload)
    pieces = [f"StopInstance failed with HTTP {status}"]
    if code:
        pieces.append(f"ErrorCode={code}")
    if request_id:
        pieces.append(f"RequestId={request_id}")
    if message:
        pieces.append(f"Message={message}")
    raise RuntimeError("; ".join(pieces))


def main():
    access_key = require_env("VOLCENGINE_ACCESS_KEY")
    secret_key = require_env("VOLCENGINE_SECRET_KEY")
    session_token = optional_env("VOLCENGINE_SESSION_TOKEN")
    if session_token == "<YOUR_SECURITY_TOKEN>":
        session_token = ""

    instance_id = require_env("INSTANCE_ID")
    region = require_env("REGION")
    endpoint = normalize_endpoint(require_env("ECS_ENDPOINT"))
    version = optional_env("ECS_API_VERSION", "2020-04-01")
    stopped_mode = optional_env("STOPPED_MODE", "KeepCharging")
    force_stop = normalize_bool(optional_env("FORCE_STOP", "false"))
    client_token = optional_env("CLIENT_TOKEN")
    if not client_token:
      token_seed = f"{instance_id}:{stopped_mode}:{force_stop}"
      client_token = "tf-stop-" + hashlib.sha256(token_seed.encode("utf-8")).hexdigest()[:32]

    query_params = {
        "Action": "StopInstance",
        "Version": version,
        "InstanceId": instance_id,
        "StoppedMode": stopped_mode,
        "ForceStop": force_stop,
        "ClientToken": client_token,
    }
    query = canonical_query_string(query_params)

    now = datetime.datetime.utcnow()
    x_date = now.strftime("%Y%m%dT%H%M%SZ")
    date_stamp = now.strftime("%Y%m%d")
    payload_hash = hashlib.sha256(b"").hexdigest()

    headers = {
        "Host": endpoint,
        "X-Date": x_date,
        "X-Content-Sha256": payload_hash,
    }
    if session_token:
        headers["X-Security-Token"] = session_token

    headers["Authorization"] = build_authorization(
        access_key=access_key,
        secret_key=secret_key,
        region=region,
        date_stamp=date_stamp,
        x_date=x_date,
        headers=headers,
        query=query,
    )

    request = urllib.request.Request(f"https://{endpoint}/?{query}", headers=headers, method=METHOD)

    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            payload = parse_response(response.read())
            code, _ = extract_error(payload)
            if code:
                fail_with_openapi_error(response.status, payload)
            request_id = extract_request_id(payload)
            suffix = f" RequestId={request_id}" if request_id else ""
            print(f"StopInstance submitted for ECS {instance_id}.{suffix}")
    except urllib.error.HTTPError as error:
        payload = parse_response(error.read())
        fail_with_openapi_error(error.code, payload)
    except urllib.error.URLError as error:
        raise RuntimeError(f"StopInstance request failed: {error.reason}") from error


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
