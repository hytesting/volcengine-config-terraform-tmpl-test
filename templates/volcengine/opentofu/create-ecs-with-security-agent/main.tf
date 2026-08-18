# 第一步：只读查询现有 ECS。
# data 块不会创建或修改实例，它用于取得实例名称、运行状态、镜像、
# VPC、可用区和 Project，作为云安全中心安装引导的操作对象。
data "volcenginecc_ecs_instance" "target" {
  id = var.instance_id
}

locals {
  is_running = data.volcenginecc_ecs_instance.target.status == "RUNNING"
  normalized_os = lower(var.install_operating_system)

  # 与 Config 规则保持一致：运行中 ECS 需要开启安全增强。
  config_rule = {
    expected_configuration_path = "ConfigurationItem.Configuration.Image.SecurityEnhancementStrategy"
    expected_value              = "Active"
    non_compliant_annotation    = "Running ECS instance should have security enhancement enabled to ensure protection agent is installed"
  }

  # 第二步：整理云安全中心“客户端安装引导”中需要选择或复制的参数。
  # 这些值直接对应控制台弹窗中的主机类型、默认分组、操作系统和自动启用防护。
  security_center_console_url = "https://console.volcengine.com/security-center"
  installation_guide_parameters = {
    host_type              = var.security_center_host_type
    default_group          = var.security_center_default_group
    operating_system       = var.install_operating_system
    auto_enable_protection = var.auto_enable_protection
    agent_id               = var.agent_id
    install_command        = var.agent_install_command
  }

  agent_status_check_command = local.normalized_os == "windows" ? "sc query elkeid-agent" : "systemctl status elkeid-agent"
  agent_log_check_command    = local.normalized_os == "windows" ? "type \"C:\\Program Files\\Elkeid\\log\\elkeid-agent.log\"" : "cat /etc/elkeid/log/elkeid-agent.log"
}

# 第三步：记录本次安全 Agent 启用动作的完整参数。
# OpenTofu 不直接登录实例执行命令；Apply 后通过 output 获取安装引导参数、
# 安装命令和检查命令，再按云安全中心控制台提示执行。
resource "terraform_data" "security_agent_install_guide" {
  input = {
    instance_id                   = data.volcenginecc_ecs_instance.target.instance_id
    instance_name                 = data.volcenginecc_ecs_instance.target.instance_name
    status                        = data.volcenginecc_ecs_instance.target.status
    private_ip                    = var.target_private_ip
    region                        = var.region
    zone_id                       = data.volcenginecc_ecs_instance.target.zone_id
    vpc_id                        = data.volcenginecc_ecs_instance.target.vpc_id
    installation_guide_parameters = local.installation_guide_parameters
    agent_status_check_command    = local.agent_status_check_command
    agent_log_check_command       = local.agent_log_check_command
    operator_note                 = var.operator_note
  }

  lifecycle {
    precondition {
      condition     = local.is_running
      error_message = "目标 ECS 必须处于 RUNNING 状态后才能安装并启用云安全中心 Agent。"
    }

    precondition {
      condition     = var.auto_enable_protection
      error_message = "安装引导必须开启“自动启用防护”。"
    }
  }
}
