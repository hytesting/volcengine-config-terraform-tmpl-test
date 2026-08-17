variable "region" {
  description = "火山引擎地域。"
  type        = string
  default     = "cn-guilin-boe"
}

variable "cloud_control_endpoint" {
  description = "CloudControl API 接入地址。"
  type        = string
  default     = "cloudcontrol.cn-guilin-boe.volcengineapi-test.com"
}

variable "launch_template_name" {
  description = "用于创建合规 ECS 的启动模板名称。"
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]{1,128}$", var.launch_template_name))
    error_message = "launch_template_name 必须为 1 到 128 位，只能包含英文、数字和 .-_。"
  }
}

variable "project_name" {
  description = "启动模板和未来 ECS 实例所属 IAM Project。"
  type        = string
  default     = "default"
}

variable "instance_name" {
  description = "未来通过启动模板创建 ECS 时使用的实例名称。"
  type        = string
}

variable "instance_type_id" {
  description = "ECS 实例规格，例如 ecs.g4i.large。"
  type        = string
}

variable "instance_charge_type" {
  description = "实例计费类型。"
  type        = string
  default     = "PostPaid"

  validation {
    condition     = contains(["PostPaid", "PrePaid"], var.instance_charge_type)
    error_message = "instance_charge_type 只能是 PostPaid 或 PrePaid。"
  }
}

variable "image_id" {
  description = "ECS 镜像 ID。SecurityEnhancementStrategy=Active 仅对公共镜像生效。"
  type        = string

  validation {
    condition     = startswith(var.image_id, "image-")
    error_message = "image_id 必须是以 image- 开头的镜像 ID。"
  }
}

variable "zone_id" {
  description = "ECS 可用区 ID。"
  type        = string
}

variable "vpc_id" {
  description = "未来 ECS 所属 VPC ID。"
  type        = string

  validation {
    condition     = startswith(var.vpc_id, "vpc-")
    error_message = "vpc_id 必须是以 vpc- 开头的 VPC ID。"
  }
}

variable "subnet_id" {
  description = "未来 ECS 主网卡所属子网 ID。"
  type        = string

  validation {
    condition     = startswith(var.subnet_id, "subnet-")
    error_message = "subnet_id 必须是以 subnet- 开头的子网 ID。"
  }
}

variable "security_group_ids" {
  description = "未来 ECS 主网卡关联的安全组 ID 列表。"
  type        = set(string)

  validation {
    condition = alltrue([
      for security_group_id in var.security_group_ids : startswith(security_group_id, "sg-")
    ])
    error_message = "security_group_ids 中的每个值都必须是以 sg- 开头的安全组 ID。"
  }
}

variable "system_volume_type" {
  description = "系统盘类型。"
  type        = string
  default     = "ESSD_PL0"
}

variable "system_volume_size" {
  description = "系统盘大小，单位 GB。"
  type        = number
  default     = 50

  validation {
    condition     = var.system_volume_size >= 20 && var.system_volume_size <= 2048
    error_message = "system_volume_size 必须在 20 到 2048 之间。"
  }
}

variable "key_pair_name" {
  description = "未来 ECS 绑定的密钥对名称；为空时不在启动模板中指定。"
  type        = string
  default     = null
}

variable "user_data" {
  description = "未来 ECS 的 UserData；Linux 场景通常传入 Base64 编码内容。"
  type        = string
  default     = null
}

variable "tags" {
  description = "启动模板和未来 ECS 实例标签。"
  type        = map(string)
  default = {
    config-rule = "ecs-security-agent-enabled"
  }
}
