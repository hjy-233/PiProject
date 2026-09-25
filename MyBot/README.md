# MyBot

MyBot 是运行在 Raspberry Pi 上的单用户个人 AI 中控。Flutter Web 提供聊天界面；Pi 服务负责库、对话、任务、消息与离线队列；Mac Agent 主动连接 Pi，并在 Mac 上调用已经登录的 Codex CLI 完成实际工作。

## 目录

```text
MyBot/
├── console/                 # Flutter Web
├── service/                 # Pi 上运行的 Swift 服务
├── mac-agent/               # macOS Agent，Phase 2 创建
├── docs/
│   ├── architecture.md
│   ├── codex-protocol.md
│   └── roadmap.md
└── GOALS.md
```

## 当前可运行内容

Swift 服务已经提供：

- `GET /health`
- `GET /api/v1/capabilities`
- 库、对话、任务、Mac Agent 与 Codex 事件的共享领域类型

```bash
swift test --package-path service
swift run --package-path service mybot-server
curl http://127.0.0.1:11000/health
```

Flutter 工程可以执行：

```bash
cd console
flutter analyze
flutter test
flutter run -d chrome
```

完整目标和非目标见 [GOALS.md](GOALS.md)。
