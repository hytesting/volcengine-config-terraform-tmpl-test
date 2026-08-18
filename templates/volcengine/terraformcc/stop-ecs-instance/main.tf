# 第一步：只读查询现有 ECS。
# data 块不会创建或修改实例，它用于取得实例当前状态和计费类型。
data "volcenginecc_ecs_instance" "target" {
  id = var.instance_id
}

locals {
  desired_status = "STOPPED"
}

# 第二步：执行停止动作。
#
# Infra Manager 当前不执行 terraform import，因此不能使用 volcenginecc_ecs_instance
# managed resource 声明存量 ECS，否则空 State 下会触发 CloudControl CREATE。
# 这里使用 terraform_data 记录动作，并通过 Python 标准库直签调用 ECS StopInstance。
resource "terraform_data" "stop_instance" {
  input = {
    instance_id     = data.volcenginecc_ecs_instance.target.instance_id
    instance_name   = data.volcenginecc_ecs_instance.target.instance_name
    previous_status = data.volcenginecc_ecs_instance.target.status
    desired_status  = local.desired_status
    stopped_mode    = var.stopped_mode
    force_stop      = var.force_stop
    charge_type     = data.volcenginecc_ecs_instance.target.instance_charge_type
    region          = var.region
    ecs_endpoint    = var.ecs_endpoint
  }

  triggers_replace = [
    var.instance_id,
    var.stopped_mode,
    tostring(var.force_stop),
  ]

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/stop_ecs_instance.sh"

    environment = {
      INSTANCE_ID     = var.instance_id
      REGION          = var.region
      ECS_ENDPOINT    = var.ecs_endpoint
      ECS_API_VERSION = var.ecs_api_version
      CURRENT_STATUS  = data.volcenginecc_ecs_instance.target.status
      STOPPED_MODE    = var.stopped_mode
      FORCE_STOP      = tostring(var.force_stop)
      CLIENT_TOKEN    = var.client_token
    }
  }

  lifecycle {
    precondition {
      condition     = contains(["RUNNING", "STOPPING", "STOPPED"], data.volcenginecc_ecs_instance.target.status)
      error_message = "目标 ECS 必须处于 RUNNING、STOPPING 或 STOPPED 状态，当前状态不适合执行停止模板。"
    }

    precondition {
      condition = (
        var.stopped_mode == "KeepCharging" ||
        data.volcenginecc_ecs_instance.target.instance_charge_type == "PostPaid"
      )
      error_message = "StopCharging 只适合按量计费实例；包年包月实例请使用 KeepCharging。"
    }
  }
}
