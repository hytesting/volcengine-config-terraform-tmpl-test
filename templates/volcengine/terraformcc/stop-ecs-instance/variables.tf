# 当前模板默认使用 BOE 地域，也允许执行环境覆盖。
variable "region" {
  description = "火山引擎地域。"
  type        = string
  default     = "cn-guilin-boe"
}

variable "cloud_control_endpoint" {
  description = "CloudControl API 接入地址。"
  type        = string
  default     = "cloudcontrol.cn-guilin-boe.volcengineapi-test.com"
}

variable "ecs_endpoint" {
  description = "ECS OpenAPI 接入地址。"
  type        = string
  default     = "ecs.cn-guilin-boe.volcengineapi-test.com"
}

variable "ecs_api_version" {
  description = "ECS OpenAPI 版本。"
  type        = string
  default     = "2020-04-01"
}

# 这是一个已经存在的 ECS 实例，不是本模板准备创建的新实例。
# 本模板只读查询实例后调用 StopInstance，不把 ECS 纳入 Terraform State。
variable "instance_id" {
  description = "需要停止的现有 ECS 实例 ID。"
  type        = string

  validation {
    condition     = startswith(var.instance_id, "i-")
    error_message = "instance_id 必须是以 i- 开头的 ECS 实例 ID。"
  }
}

variable "stopped_mode" {
  description = "停机模式。KeepCharging 为普通停机；StopCharging 为节省停机，需实例满足云产品限制。"
  type        = string
  default     = "KeepCharging"

  validation {
    condition     = contains(["KeepCharging", "StopCharging"], var.stopped_mode)
    error_message = "stopped_mode 只能是 KeepCharging 或 StopCharging。"
  }
}

variable "force_stop" {
  description = "是否强制停止实例。默认 false，优先正常关机。"
  type        = bool
  default     = false
}

variable "client_token" {
  description = "StopInstance 幂等 Token；为空时脚本基于实例 ID 和停机参数自动生成。"
  type        = string
  default     = ""
}
