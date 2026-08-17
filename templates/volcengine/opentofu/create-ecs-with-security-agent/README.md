# OpenTofu：手动安装并启用 ECS 安全 Agent

## 目标

该模板用于处理以下 Config 规则的不合规实例：

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

当运行中的 ECS 未开启安全加固时，修复目标不是创建新实例，也不是创建启动模板，而是对现有实例
安装并启用云安全中心安全客户端。

当前 `volcenginecc` Provider 没有封装云安全中心 Agent 安装资源；云安全中心公开的
`InstallAgentClient` API 使用 `AgentIDs`，不是 ECS `InstanceId`。因此本模板只做三件事：

- 只读目标 ECS，确认实例处于 `RUNNING`；
- 输出针对该实例的手动安装 Runbook；
- 在已取得云安全中心 `AgentID` 时，输出 `InstallAgentClient` API 请求信息。

## 前置条件

- 云安全中心服务已开通；
- 目标 ECS 处于 `RUNNING`，网络连通正常；
- 如实例内安装了第三方安全软件，需先评估是否会阻止云安全中心客户端安装；
- 执行凭证至少拥有 ECS 实例读取权限；
- 手动安装命令必须从云安全中心控制台生成，不要复用其他账号、地域或操作系统的命令。

## 初始化

```bash
cd templates/volcengine/opentofu/create-ecs-with-security-agent
source ../../../../.credentials.env

cp terraform.tfvars.example terraform.tfvars
# 编辑 instance_id；如已取得 AgentID 或安装命令，也可填入 agent_id / manual_install_command。

tofu init
tofu validate
```

也可以不创建 `terraform.tfvars`，直接使用 `TF_VAR_*` 环境变量注入参数：

```bash
export TF_VAR_instance_id="i-xxxxxxxxxxxxxxxx"
```

## Plan

```bash
tofu plan -out=plans/manual-install.tfplan
tofu show -no-color plans/manual-install.tfplan
```

如果目标实例不是 `RUNNING`，Plan 会失败并提示先启动实例。

## 手动安装路径

登录云安全中心控制台：

```text
https://console.volcengine.com/security-center
```

按以下路径处理目标实例：

```text
系统配置 > 安装卸载
```

或：

```text
服务管理 > 防护安装部署
```

处理方式：

- 公共镜像 Linux 且支持一键安装：在安装列表中搜索目标 ECS，单击“安装”或“安装并启用”。
- Windows、自定义镜像或不支持一键安装的实例：打开“客户端安装引导”，选择火山引擎主机、目标操作系统、默认分组，并开启“自动启用防护”；复制生成的部署命令，登录实例后以管理员或 root 权限执行。
- 已安装但未启用：在“待启用”主机列表中单击“启用防护”。

安装完成后等待心跳上报，再回到云安全中心确认目标实例进入已防护状态。随后重新触发 Config 规则评估，
期望 `ConfigurationItem.Configuration.Image.SecurityEnhancementStrategy == "Active"`。

## 已知 AgentID 时的 API 路径

如果已经从云安全中心安装列表取得目标主机的 `AgentID`，可填入：

```hcl
agent_id = "xxxxxxxxxxxxxxxx"
```

然后查看输出：

```bash
tofu output api_request_if_agent_id_known
```

输出会给出 `seccenter` 服务的 `InstallAgentClient` 请求信息。该 API 仍然需要调用方自己完成火山
OpenAPI 签名和请求发送；本模板不在本地执行该 API。

## 输出

```bash
tofu output target_instance
tofu output config_rule_baseline
tofu output -json manual_remediation
```

`manual_remediation` 可能包含从控制台复制的安装命令，因此被标记为 sensitive。

## 清理

本模板不创建云资源，不接管 ECS，也不修改云安全中心状态。若只执行过 Plan，无需清理。

如果执行过 Apply，会在 state 中保存一个 `terraform_data.manual_install_guard` 校验记录，可删除本地
state 或执行：

```bash
tofu destroy
```
