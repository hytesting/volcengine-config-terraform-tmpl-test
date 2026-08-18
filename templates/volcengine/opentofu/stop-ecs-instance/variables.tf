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

# 这是一个已经存在的 ECS 实例，不是本模板准备创建的新实例。
# imports.tf 会在同一个 Plan 中将该实例绑定到 volcenginecc_ecs_instance.target。
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
