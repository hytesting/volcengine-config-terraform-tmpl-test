output "launch_template" {
  description = "已创建的 ECS 启动模板。"
  value = {
    id                    = volcenginecc_ecs_launch_template.security_agent.launch_template_id
    name                  = volcenginecc_ecs_launch_template.security_agent.launch_template_name
    latest_version_number = volcenginecc_ecs_launch_template.security_agent.latest_version_number
    project_name          = var.project_name
  }
}

output "config_rule_baseline" {
  description = "与 Config 规则匹配的安全加固基线。"
  value = {
    expected_configuration_path = "ConfigurationItem.Configuration.Image.SecurityEnhancementStrategy"
    expected_value              = local.security_enhancement_strategy
    non_compliant_annotation    = "Running ECS instance should have security enhancement enabled to ensure protection agent is installed"
  }
}
