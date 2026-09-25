# MyBot 产品目标

## 一句话目标

MyBot 是一个通过网页远程使用 Mac 端 Codex 的单用户私人中控：Pi 持久在线、保存状态并调度任务，Mac 执行 Codex 和本机开发操作。

## 核心边界

| 组件 | 负责 | 不负责 |
| --- | --- | --- |
| Flutter Web | 聊天、库、对话、任务状态、Mac 状态与设置 | 直接运行 Codex 或保存凭据 |
| MyBot Server（Pi） | SQLite、消息、任务队列、WebSocket 转发、单用户会话 | 修改 Mac 文件、替代 Codex、保存 Codex 登录凭据 |
| Mac Agent | 主动连接 Pi、启动和停止 `codex exec`、转发 JSONL 事件 | 保存聊天主数据、对公网开放监听端口 |
| Codex CLI | 代码、文件、Shell、Git、构建及 macOS 开发操作 | 充当 MyBot 数据库或设备连接层 |
| ProjectDeployer | 构建、部署、回滚和守护 MyBot Server | 管理 MyBot 对话或调用 Codex |

## 首版必须完成

1. 单用户 Flutter Web 聊天。
2. 创建库；一个库绑定一个经过 Mac Agent 验证的 Mac 工作目录。
3. 一个库可以包含多个持久对话。
4. 持久对话第一轮使用 `codex exec --json --cd <directory>`，记录返回的 Codex session ID；后续使用 `codex exec resume <session-id> --json`。
5. 临时对话不创建库，使用 `codex exec --ephemeral --json`，结束后不允许继续。
6. Pi 保存消息、任务、运行状态、Codex session ID 和事件摘要。
7. Mac Agent 使用出站 WebSocket 连接 Pi，自动重连；Mac 离线时任务停留在队列中。
8. 页面实时显示 Codex 文本、命令、文件修改、错误、完成和取消事件。
9. 一个对话同一时间最多运行一个 Codex 任务。
10. 支持用户主动停止任务，Mac Agent 终止对应子进程并回传最终状态。

## 库与记忆

每个库独立配置一种记忆模式：

| 模式 | 行为 |
| --- | --- |
| `codexDefault` | 使用目录内现有 `AGENTS.md`、Codex 默认配置和持久 session，不额外注入 MyBot 记忆 |
| `library` | 在 Codex 默认行为之上加载该库的 MyBot 记忆文件 |
| `none` | 不加载库级 MyBot 记忆；同一持久对话仍保留 Codex session 上下文 |

库级记忆保存在库目录内的 `.mybot/memory.md`，由用户明确查看和编辑。MyBot 不自动把完整聊天内容永久写入记忆。

临时对话固定使用 `none`，工作目录由 Mac Agent 放在自己的临时运行根目录，结束后清理。

## 安全要求

- 仅通过 Tailscale 私网访问，不提供公网部署说明。
- Codex 登录状态和凭据只存在于 Mac。
- Mac Agent 不监听入站端口。
- 首版不使用 `--dangerously-bypass-approvals-and-sandbox`。
- 每个库只允许访问配置的工作目录；路径必须由 Mac Agent 解析并验证。
- Pi 不能把任意 shell 字符串发送给 Mac；只发送结构化 Codex 任务。
- 服务端和 Agent 日志不得记录用户消息全文、环境变量值或认证材料。
- 任务必须有稳定 ID、超时、取消状态和可审计的状态变化。

## 首版非目标

- 多用户、团队和共享权限。
- 公网账户注册和密码找回。
- 自己实现 Shell、Git、文件编辑或 IDE 工具。
- 旅行、费用、剪贴板、通知和家庭设备模块。
- Pi 本地模型推理。
- 让 MyBot 或 Codex 自动更新 ProjectDeployer。

这些能力只有在 Codex 远程聊天闭环稳定后才进入后续阶段。

## 完成标准

手机通过 Tailscale 打开 MyBot，选择一个库并发送任务；Mac Agent 收到任务，在正确工作目录运行 Codex；执行事件实时返回网页；刷新页面后仍能查看消息；继续发送消息时恢复同一个 Codex session；Mac 离线时任务保持排队，重连后可安全领取；临时对话结束后不留下可恢复 session。
