# Codex Execution Protocol

## 新持久对话

Mac Agent 使用参数数组启动进程，不拼接 shell 命令：

```text
codex exec
  --json
  --color never
  --sandbox workspace-write
  --cd <validated-library-directory>
  <prompt>
```

Agent 从 JSONL 的 session/thread 启动事件提取 Codex session ID，并立即回传 Pi。提取不到 session ID 时任务失败，不能假装成为可继续的对话。

## 继续对话

```text
codex exec resume
  --json
  <codex-session-id>
  <prompt>
```

MyBot 不使用 `--last`，因为多个库和对话会并发存在，必须显式绑定 session ID。

## 临时对话

```text
codex exec
  --json
  --ephemeral
  --color never
  --sandbox workspace-write
  --cd <agent-temporary-directory>
  <prompt>
```

临时对话只允许一个 turn。结束后 Agent 清理临时工作目录，Pi 不保存可恢复的 Codex session ID。

## MyBot 与 Mac Agent 消息

所有消息包含 `protocolVersion`、`messageId`、`sentAt`。任务事件还包含 `taskId` 和严格递增的 `sequence`，Pi 以 `(taskId, sequence)` 去重。

主要消息类型：

- `agent.hello`
- `agent.heartbeat`
- `task.offer`
- `task.accepted`
- `task.event`
- `task.completed`
- `task.failed`
- `task.cancel`
- `task.cancelled`

Codex JSONL 必须先解析为 MyBot 的稳定事件类型，再发给网页。Flutter 前端不直接依赖 Codex CLI 的原始事件 schema。

## 进程生命周期

1. 收到任务后验证 Agent ID、库、工作目录和 conversation 并发状态。
2. 使用 `Process` 参数数组启动 Codex，分别读取 stdout JSONL 与 stderr。
3. stdout 每行设置大小上限；解析失败产生受控协议错误。
4. 用户取消时先发送中断信号，宽限期后仍未退出才终止进程。
5. 进程退出、连接中断或 Agent 关闭时必须写入唯一终态。
6. stderr 仅用于受限诊断，不能直接作为聊天消息展示或永久完整保存。
