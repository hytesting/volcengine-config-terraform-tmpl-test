# Outputs 会写入当前 Workspace 的 State，并可通过 tofu output 查看。
# Config 或 QA 可以用这些输出确认本次操作对象和安装引导参数。
output "target_instance_id" {
  description = "需要开启安全防护的目标 ECS 实例 ID。"
  value       = data.volcenginecc_ecs_instance.target.instance_id
}

output "target_instance_status" {
  description = "目标 ECS 当前运行状态。"
  value       = data.volcenginecc_ecs_instance.target.status
}

output "installation_guide_parameters" {
  description = "云安全中心“客户端安装引导”中需要选择或填写的参数。"
  value = {
    console_url            = local.security_center_console_url
    host_type              = local.installation_guide_parameters.host_type
    default_group          = local.installation_guide_parameters.default_group
    operating_system       = local.installation_guide_parameters.operating_system
    auto_enable_protection = local.installation_guide_parameters.auto_enable_protection
    agent_id               = local.installation_guide_parameters.agent_id
    target_private_ip      = var.target_private_ip
  }
}

output "agent_install_command" {
  description = "从云安全中心“客户端安装引导”复制的安装命令。"
  value       = var.agent_install_command
  sensitive   = true
}

output "agent_check_commands" {
  description = "安装完成后在实例内执行的检查命令。"
  value = {
    status = local.agent_status_check_command
    log    = local.agent_log_check_command
  }
}

output "config_rule_baseline" {
  description = "与 Config 规则匹配的安全加固基线。"
  value       = local.config_rule
}
