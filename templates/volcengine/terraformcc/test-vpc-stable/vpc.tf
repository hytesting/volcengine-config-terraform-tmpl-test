terraform {
  required_version = "= 1.11.8"

  required_providers {
    volcenginecc = {
      source  = "volcengine/volcenginecc"
      version = "= 0.0.57"
    }
  }
}

# ------------------------------
# 变量提取（全部可配置）
# ------------------------------
variable "region" {
  type        = string
  description = "地域"
  default     = "cn-guilin-boe"
}

variable "endpoint" {
  type        = string
  description = "自定义API endpoints"
  default     = "volcengineapi-boe-stable.byted.org"
}

variable "vpc_name" {
  type        = string
  description = "VPC名称"
  default     = "vpc-demo"
}

variable "cidr_block" {
  type        = string
  description = "VPC网段"
  default     = "192.168.0.0/24"
}

variable "description" {
  type        = string
  description = "描述"
  default     = "VpcDemo Example"
}

variable "project_name" {
  type        = string
  description = "项目名称"
  default     = "default"
}

variable "tags" {
  type = list(object({
    key   = string
    value = string
  }))
  description = "标签"
  default = [
    {
      key   = "env"
      value = "test"
    }
  ]
}

# ------------------------------
# Provider 配置（已修复！）
# ------------------------------
provider "volcenginecc" {
  region   = var.region

  # 这里修复成正确语法
  endpoints = {
    cloudcontrolapi = var.endpoint
  }
}

# ------------------------------
# 创建 VPC
# ------------------------------
resource "volcenginecc_vpc_vpc" "VpcDemo" {
  vpc_name              = var.vpc_name
  description           = var.description
  cidr_block            = var.cidr_block
  support_ipv_4_gateway = false
  project_name          = var.project_name
  tags                  = var.tags
}

# ------------------------------
# 查询 VPC
# ------------------------------
data "volcenginecc_vpc_vpc" "VpcDataSource" {
  id = volcenginecc_vpc_vpc.VpcDemo.id
}

# ------------------------------
# ✅ output 已添加
# ------------------------------
output "vpc_id" {
  value       = volcenginecc_vpc_vpc.VpcDemo.id
  description = "VPC ID"
}

output "vpc_name" {
  value       = volcenginecc_vpc_vpc.VpcDemo.vpc_name
  description = "VPC 名称"
}

output "vpc_cidr_block" {
  value       = volcenginecc_vpc_vpc.VpcDemo.cidr_block
  description = "VPC 网段"
}

output "status" {
  value       = data.volcenginecc_vpc_vpc.VpcDataSource.status
  description = "VPC 状态"
}
