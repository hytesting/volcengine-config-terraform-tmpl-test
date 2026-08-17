# TerraformCC：创建开启安全 Agent 的 ECS 启动模板

## 目标

该模板根据以下 Config 规则生成一个 ECS 创建基线：

```rego
package rules

default compliant := false
default annotation := ""

is_running if {
	input.ConfigurationItem.Configuration.Status == "RUNNING"
}

compliant if {
	not is_running
}

compliant if {
	is_running
	input.ConfigurationItem.Configuration.Image.SecurityEnhancementStrategy == "Active"
}

annotation := "Running ECS instance should have security enhancement enabled to ensure protection agent is installed" if {
	is_running
	input.ConfigurationItem.Configuration.Image.SecurityEnhancementStrategy != "Active"
}
```

火山 ECS 创建接口和启动模板接口都使用 `SecurityEnhancementStrategy` 控制安全加固：

- `Active`：开启安全加固，确保新建实例安装保护 Agent；
- `InActive`：关闭安全加固。

当前 `volcenginecc_ecs_instance` 资源文档没有暴露该字段；同 Provider 的
`volcenginecc_ecs_launch_template` 暴露了
`launch_template_version.security_enhancement_strategy`。因此本模板创建一个启动模板，并把
`security_enhancement_strategy` 固定为 `Active`。

## 前置条件

- 目标地域内已有 VPC、Subnet、安全组和可用公共镜像；
- 执行凭证拥有 ECS LaunchTemplate 的创建、查询和删除权限；
- `SecurityEnhancementStrategy=Active` 仅对公共镜像生效。自定义镜像场景创建后仍需通过云安全中心确认 Agent 状态。

## 初始化

```bash
cd templates/volcengine/terraformcc/create-ecs-with-security-agent
source ../../../../.credentials.env

cp terraform.tfvars.example terraform.tfvars
# 按实际环境编辑 image_id、zone_id、vpc_id、subnet_id、security_group_ids 等参数。

terraform init
terraform validate
```

也可以不创建 `terraform.tfvars`，直接使用 `TF_VAR_*` 环境变量注入参数。

## Plan/Apply

```bash
terraform plan -out=plans/apply.tfplan
terraform show -no-color plans/apply.tfplan
```

必须确认计划中包含：

```text
volcenginecc_ecs_launch_template.security_agent: Create
security_enhancement_strategy = "Active"
```

执行保存的计划：

```bash
terraform apply plans/apply.tfplan
terraform output
```

`config_rule_baseline.expected_value` 应输出 `Active`。

## 清理

本模板只创建启动模板，不创建 ECS 实例。验证完成后可执行：

```bash
terraform destroy
```
