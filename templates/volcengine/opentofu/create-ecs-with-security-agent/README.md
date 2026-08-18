# OpenTofu：为现有 ECS 生成安全 Agent 启用参数

## 目标

通过一次 Plan/Apply 完成：

```text
已有 ECS
   │
   ├── READ：读取实例状态和基础信息
   ├── CHECK：确认实例处于 RUNNING
   └── OUTPUT：输出云安全中心安装引导参数、安装命令和检查命令
```

本模板不创建 ECS，也不接管实例生命周期。它把“启用防护”需要的具体参数固定到
OpenTofu State 和 outputs 中，便于 QA 或人工按同一套步骤执行。

## 初始化并指定目标

```bash
cd templates/volcengine/opentofu/create-ecs-with-security-agent
source ../../../../.credentials.env

export TF_VAR_instance_id="i-xxxxxxxxxxxxxxxx"
export TF_VAR_target_private_ip="192.168.0.156"
export TF_VAR_agent_id="xxxxxxxxxxxxxxxx"

export TF_VAR_security_center_host_type="火山引擎"
export TF_VAR_security_center_default_group="未分组"
export TF_VAR_install_operating_system="Linux"
export TF_VAR_auto_enable_protection=true

export TF_VAR_agent_install_command='bash -c "从云安全中心客户端安装引导复制的完整命令"'

tofu init
tofu validate
tofu state list
```

首次执行时 State 为空是正常现象。不要额外运行 `tofu import`。

## 一次 Plan/Apply 生成启用参数

```bash
tofu plan -out=plans/apply.tfplan
tofu show -no-color plans/apply.tfplan
```

必须确认计划包含：

```text
data.volcenginecc_ecs_instance.target              Read
terraform_data.security_agent_install_guide        Create
```

执行保存的计划：

```bash
tofu apply plans/apply.tfplan
tofu output
tofu output -json agent_install_command
```

输出中的 `installation_guide_parameters` 对应云安全中心控制台弹窗：

```text
安装对象：
  主机类型：火山引擎
  默认分组：未分组
  操作系统：Linux 或 Windows
  自动启用防护：true

安装命令：
  agent_install_command

检查安装结果：
  agent_check_commands.status
  agent_check_commands.log
```

最后一次 Plan 应为 `No changes.`。

本模板只生成启用防护所需参数和命令，不包含关闭防护或卸载 Agent 的清理流程。
