# 只读目标 ECS。安全 Agent 的安装动作不由 CloudControl Provider 执行。
data "volcenginecc_ecs_instance" "target" {
  id = var.instance_id
}

locals {
  is_running = data.volcenginecc_ecs_instance.target.status == "RUNNING"

  config_rule = {
    expected_configuration_path = "ConfigurationItem.Configuration.Image.SecurityEnhancementStrategy"
    expected_value              = "Active"
    non_compliant_annotation    = "Running ECS instance should have security enhancement enabled to ensure protection agent is installed"
  }

  security_center_console_url = "https://console.volcengine.com/security-center"
  install_agent_api = {
    service = "seccenter"
    action  = "InstallAgentClient"
    version = "2024-05-08"
    host    = "seccenter.volcengineapi.com"
    body = var.agent_id == null ? null : jsonencode({
      AgentIDs = [var.agent_id]
    })
  }

  manual_install_command = coalesce(
    var.manual_install_command,
    "从云安全中心控制台的“客户端安装引导”复制目标操作系统对应的部署命令，并在实例内以管理员/root 权限执行。",
  )
}

# 该资源不安装 Agent，只把运行态校验挂到 Plan 上，避免对已停止实例生成误导性修复。
resource "terraform_data" "manual_install_guard" {
  input = {
    instance_id   = data.volcenginecc_ecs_instance.target.instance_id
    instance_name = data.volcenginecc_ecs_instance.target.instance_name
    status        = data.volcenginecc_ecs_instance.target.status
  }

  lifecycle {
    precondition {
      condition     = local.is_running
      error_message = "目标 ECS 必须处于 RUNNING 状态后才能手动安装并启用云安全中心 Agent。"
    }
  }
}
