locals {
  # Config 规则要求运行中 ECS 的 Image.SecurityEnhancementStrategy 为 Active。
  security_enhancement_strategy = "Active"

  launch_template_tags = [
    for key in sort(keys(var.tags)) : {
      key   = key
      value = var.tags[key]
    }
  ]
}

# CloudControl 的 ECS Instance 资源当前不暴露 security_enhancement_strategy。
# ECS Launch Template 暴露同名创建参数，因此本模板把合规创建参数固化到启动模板版本中。
resource "volcenginecc_ecs_launch_template" "security_agent" {
  launch_template_name         = var.launch_template_name
  launch_template_project_name = var.project_name
  launch_template_tags         = toset(local.launch_template_tags)

  launch_template_version = {
    version_description           = "Config rule baseline: enable ECS security agent"
    instance_name                 = var.instance_name
    instance_type_id              = var.instance_type_id
    instance_charge_type          = var.instance_charge_type
    image_id                      = var.image_id
    zone_id                       = var.zone_id
    vpc_id                        = var.vpc_id
    project_name                  = var.project_name
    key_pair_name                 = var.key_pair_name
    security_enhancement_strategy = local.security_enhancement_strategy
    spot_strategy                 = "NoSpot"
    unique_suffix                 = false
    user_data                     = var.user_data

    network_interfaces = toset([
      {
        subnet_id          = var.subnet_id
        security_group_ids = var.security_group_ids
      }
    ])

    volumes = toset([
      {
        volume_type                     = var.system_volume_type
        size                            = var.system_volume_size
        delete_with_instance            = true
        extra_performance_iops          = 0
        extra_performance_throughput_mb = 0
        extra_performance_type_id       = ""
        snapshot_id                     = ""
      }
    ])

    tags = toset(local.launch_template_tags)
  }

  lifecycle {
    precondition {
      condition     = length(var.security_group_ids) > 0
      error_message = "至少需要传入一个安全组 ID。"
    }

    precondition {
      condition     = local.security_enhancement_strategy == "Active"
      error_message = "安全加固创建参数必须保持为 Active。"
    }
  }
}
