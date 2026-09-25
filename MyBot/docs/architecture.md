# Architecture

## 数据流

```text
Flutter Web
    │ HTTPS / WebSocket over Tailscale
    ▼
MyBot Server on Raspberry Pi
    ├── SQLite: libraries, conversations, messages, tasks, event summaries
    ├── WebSocket: browser event stream
    └── WebSocket: connected Mac Agents
             │ outbound connection from Mac
             ▼
        MyBot Mac Agent
             ├── validates configured workspace paths
             ├── starts one Codex process per active conversation
             └── codex exec --json / exec resume / --ephemeral
```

## 服务端所有权

Pi 是业务状态的唯一来源。浏览器断线不会终止任务；Mac Agent 断线会让运行任务进入 `connectionLost`，而尚未领取的任务继续保持 `queued`。Mac Agent 重连后先提交自身能力和正在运行的进程，再由服务端决定恢复、失败或重新领取。

## 并发规则

- 每个 conversation 最多一个 `running` task。
- 每个 Mac Agent 有可配置的全局并发上限，首版默认为 1。
- 同一 library 可以有多个 conversation，但它们仍受 Agent 全局并发限制。
- 排队顺序由 Pi 按创建时间维护，不依赖 WebSocket 到达顺序。

## 数据表边界

| 表 | 关键字段 |
| --- | --- |
| `libraries` | id、name、agentId、workspacePath、memoryMode、createdAt、updatedAt |
| `conversations` | id、libraryId?、kind、title、codexSessionId?、createdAt、updatedAt |
| `messages` | id、conversationId、role、content、createdAt |
| `tasks` | id、conversationId、agentId?、state、promptMessageId、startedAt?、finishedAt?、errorCode? |
| `task_events` | id、taskId、sequence、kind、summary、createdAt |
| `agents` | id、name、state、capabilities、lastSeenAt |

原始 Codex JSONL 不永久完整保存。首版只保存用户可见消息、结构化状态和必要事件摘要，避免数据库无限增长或意外记录敏感输出。

## 连接身份

首版是单用户，但浏览器和 Mac Agent 仍使用不同的随机凭据。凭据由 Pi 初始化并保存在权限受限的配置中，通过 Tailscale 传输。未来增加认证时，不改变任务和消息数据模型。
