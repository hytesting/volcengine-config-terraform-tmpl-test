# 通过 ECS OpenAPI 停止现有实例

## 目标

1. 使用 TerraformCC data source 读取现有 ECS 实例。
2. 校验实例状态和停机模式。
3. 通过 Python 标准库直签调用 ECS `StopInstance` OpenAPI。

资源变化：

```text
执行前
ECS instance（不由本模板创建）
└── status = RUNNING

                    Terraform Apply
                           │
              CALL ECS StopInstance OpenAPI
                           │
                           ▼
执行后
ECS instance
└── status = STOPPED 或 STOPPING
```

预期计划：

```text
Plan: 1 to add, 0 to change, 0 to destroy.
```

这里的 `1 to add` 是 `terraform_data.stop_instance` 动作记录，不是创建 ECS。

## 进入目录并加载环境

```bash
cd templates/volcengine/terraformcc/stop-ecs-instance
source ../../../../.credentials.env

export TF_VAR_instance_id="i-xxxxxxxxxxxxxxxx"
```

Terraform 自动把 `TF_VAR_<变量名>` 映射到同名输入变量。每次新开终端需要重新加载
凭证并设置业务参数；BOE 地域和 endpoint 已有默认值。

默认使用普通停机：

```bash
export TF_VAR_stopped_mode="KeepCharging"
```

如果目标实例是按量计费且满足节省停机条件，可改为：

```bash
export TF_VAR_stopped_mode="StopCharging"
```

如需强制停机：

```bash
export TF_VAR_force_stop=true
```

## 初始化

```bash
terraform init
terraform validate
```

模板不声明 Backend。本地执行时 Terraform 默认将资源状态保存在：

```text
terraform.tfstate
```

托管平台执行时，由平台注入 Backend 并持久化 State。

## Plan

```bash
terraform plan -out=plans/apply.tfplan
terraform show -no-color plans/apply.tfplan
```

确认计划只包含：

```text
terraform_data.stop_instance: Create
```

不要接受包含 `volcenginecc_ecs_instance` Create、Replace 或 Destroy 的计划。

## Apply

```bash
terraform apply plans/apply.tfplan
terraform output
```

Apply 时，`terraform_data.stop_instance` 会通过 `scripts/stop_ecs_instance.sh` 调用
`scripts/stop_ecs_instance.py`。脚本使用 Python 标准库直签 ECS `StopInstance`
OpenAPI，不依赖 `ve` CLI 或 Python 第三方包。

如果实例已经处于 `STOPPED` 或 `STOPPING`，脚本会直接跳过。

本模板只执行停止操作，不包含启动实例或删除实例流程。
