variable "region" {
  description = "火山引擎地域 ID，例如 cn-beijing。"
  type        = string
  default     = "cn-guilin-boe"
}

variable "cloud_control_endpoint" {
  description = "CloudControl API 接入地址。"
  type        = string
  default     = "cloudcontrol.cn-guilin-boe.volcengineapi-test.com"
}

variable "instance_id" {
  description = "需要手动安装并启用云安全中心 Agent 的现有 ECS 实例 ID。"
  type        = string

  validation {
    condition     = startswith(var.instance_id, "i-")
    error_message = "instance_id 必须是以 i- 开头的 ECS 实例 ID。"
  }
}

variable "agent_id" {
  description = "可选。云安全中心中的 AgentID；如果已从安装列表取得，可用于输出 InstallAgentClient API 请求体。"
  type        = string
  default     = null
}

variable "manual_install_command" {
  description = "可选。从云安全中心“客户端安装引导”复制的 Linux 或 Windows 部署命令。"
  type        = string
  default     = null
  sensitive   = true
}

variable "operator_note" {
  description = "可选。记录本次手动修复的操作备注。"
  type        = string
  default     = "实例未开启安全 Agent，按云安全中心安装引导手动安装并启用防护。"
}
