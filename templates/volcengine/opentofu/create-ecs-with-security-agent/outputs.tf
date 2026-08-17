output "target_instance" {
  description = "需要手动安装 Agent 的目标 ECS 实例快照。"
  value = {
    id            = data.volcenginecc_ecs_instance.target.instance_id
    name          = data.volcenginecc_ecs_instance.target.instance_name
    status        = data.volcenginecc_ecs_instance.target.status
    region        = var.region
    zone_id       = data.volcenginecc_ecs_instance.target.zone_id
    project_name  = data.volcenginecc_ecs_instance.target.project_name
    image         = data.volcenginecc_ecs_instance.target.image
    operator_note = var.operator_note
  }
}

output "manual_remediation" {
  description = "当目标实例未开启安全 Agent 时的手动修复步骤。"
  value = {
    console_url = local.security_center_console_url
    steps = [
      "登录云安全中心控制台并确认服务已开通。",
      "进入“系统配置 > 安装卸载”或“服务管理 > 防护安装部署”。",
      "在安装列表中筛选或搜索目标 ECS：${data.volcenginecc_ecs_instance.target.instance_id}。",
      "如果目标主机支持一键安装，单击“安装”或“安装并启用”。",
      "如果目标主机需要手动安装，打开“客户端安装引导”，选择火山引擎主机、目标操作系统、默认分组，并开启“自动启用防护”。",
      "复制生成的部署命令，登录实例后以管理员/root 权限执行。",
      "安装后等待心跳上报，再在云安全中心确认状态进入已防护；最后重新触发 Config 规则评估。",
    ]
    install_command = local.manual_install_command
  }
  sensitive = true
}

output "api_request_if_agent_id_known" {
  description = "如果已经取得云安全中心 AgentID，可用该信息调用 InstallAgentClient；否则为 null。"
  value       = local.install_agent_api
}

output "config_rule_baseline" {
  description = "与 Config 规则匹配的安全加固基线。"
  value       = local.config_rule
}
