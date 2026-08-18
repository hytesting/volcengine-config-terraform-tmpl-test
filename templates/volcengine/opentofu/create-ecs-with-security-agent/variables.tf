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
  description = "需要安装并启用云安全中心 Agent 的现有 ECS 实例 ID。"
  type        = string

  validation {
    condition     = startswith(var.instance_id, "i-")
    error_message = "instance_id 必须是以 i- 开头的 ECS 实例 ID。"
  }
}

variable "agent_id" {
  description = "可选。云安全中心安装列表中的 AgentID，便于确认操作对象。"
  type        = string
  default     = null
}

variable "target_private_ip" {
  description = "可选。目标 ECS 在云安全中心列表中展示的私网 IP，便于人工核对。"
  type        = string
  default     = null
}

variable "security_center_host_type" {
  description = "云安全中心“客户端安装引导”中的主机类型。"
  type        = string
  default     = "火山引擎"
}

variable "security_center_default_group" {
  description = "云安全中心“客户端安装引导”中的默认分组。"
  type        = string
  default     = "未分组"
}

variable "install_operating_system" {
  description = "云安全中心“客户端安装引导”中的操作系统。"
  type        = string
  default     = "Linux"

  validation {
    condition     = contains(["Linux", "Windows"], var.install_operating_system)
    error_message = "install_operating_system 只能是 Linux 或 Windows。"
  }
}

variable "auto_enable_protection" {
  description = "云安全中心“客户端安装引导”中的自动启用防护开关，必须为 true。"
  type        = bool
  default     = true
}

variable "agent_install_command" {
  description = "从云安全中心“客户端安装引导”复制的安装命令。"
  type        = string
  sensitive   = true
}

variable "operator_note" {
  description = "可选。记录本次启用防护的操作备注。"
  type        = string
  default     = "实例未开启安全 Agent，按云安全中心安装引导手动安装并启用防护。"
}
