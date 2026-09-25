# Roadmap

## Phase 1：服务端数据与 API

- [x] 建立 Swift Package、健康接口和能力接口。
- [x] 定义 library、conversation、task、agent 与事件的共享类型。
- [x] SQLite schema、权限与版本化持久化文档。
- [ ] SQLite 跨版本迁移。
- [x] library 和 conversation 创建、列表 API。
- [ ] library 和 conversation 编辑、删除 API。
- [x] 消息持久化与发送 API。
- [ ] 消息分页和标题更新。
- [x] task 排队与单 conversation 并发约束。
- [ ] task 完整状态机。
- [ ] 浏览器 WebSocket 事件流。

完成条件：没有 Mac Agent 时，仍可稳定创建库、对话和排队任务，重启 Pi 后数据不丢失。

## Phase 2：Mac Agent 与 Codex

- [ ] macOS Agent Swift Package。
- [ ] 出站 WebSocket、身份验证、心跳和自动重连。
- [ ] 工作目录注册与路径验证。
- [ ] `codex exec --json` 新会话。
- [ ] `codex exec resume` 持久对话。
- [ ] `--ephemeral` 临时对话。
- [ ] JSONL 解析、事件归一化、取消和进程回收。
- [ ] launchd 安装与升级。

完成条件：Mac 在线时可以完成一轮真实 Codex 任务；离线队列、重连、取消和失败均有稳定终态。

## Phase 3：Flutter Web

- [x] 响应式聊天框架。
- [x] 库与库内对话创建和选择。
- [ ] 临时对话入口。
- [ ] 流式文本、工具/命令事件和任务状态。
- [ ] Mac 真实在线状态与完整队列状态。
- [x] 简体中文和英文资源。

完成条件：手机浏览器可完成首版目标，不需要 SSH 或手动运行 Codex。

## Phase 4：部署与恢复

- [ ] Dockerfile、`project-deployer.json` 和健康检查。
- [ ] 通过 ProjectDeployer 部署到 Pi。
- [ ] Mac Agent 安装脚本与 launchd unit。
- [ ] SQLite 备份、恢复和保留策略。
- [ ] Pi 重启、Mac 重启、断网和连续消息验收。

完成条件：MyBot Server 和 Mac Agent 重启后能够恢复到可解释、可操作的状态。
