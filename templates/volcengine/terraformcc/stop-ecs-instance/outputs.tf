# 回显输入的目标 ECS，便于确认本次操作对象。
output "target_instance_id" {
  description = "实验目标 ECS 实例 ID。"
  value       = var.instance_id
}

output "stop_summary" {
  description = "停止 ECS 的执行结果摘要。"
  value       = terraform_data.stop_instance.output
}
