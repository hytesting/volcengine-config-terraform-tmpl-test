#!/usr/bin/env bash
set -euo pipefail

: "${INSTANCE_ID:?INSTANCE_ID is required}"
: "${REGION:?REGION is required}"
: "${ECS_ENDPOINT:?ECS_ENDPOINT is required}"

CURRENT_STATUS="${CURRENT_STATUS:-UNKNOWN}"

if [[ "${CURRENT_STATUS}" == "STOPPED" || "${CURRENT_STATUS}" == "STOPPING" ]]; then
  echo "ECS ${INSTANCE_ID} is already ${CURRENT_STATUS}; skip StopInstance."
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to call ecs StopInstance, but it was not found in PATH." >&2
  exit 127
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "${SCRIPT_DIR}/stop_ecs_instance.py"
