# ProjectDeployer 路线图

## Phase 0：设计与环境准备

- [x] 确认 Raspberry Pi OS Lite 64-bit 与 Swift Linux 路线可行。
- [x] 确定 Flutter Web + Swift + Docker + systemd 技术边界。
- [x] 固定 MVP、架构、安全边界和 manifest v1 草案。
- [x] 在 Raspberry Pi 上记录系统、Docker、存储与网络基线。

完成条件：设计可以指导实现，尚未承诺未验证的 Pi 环境细节。

## Phase 1：Swift 控制服务骨架

- [x] 创建 Swift Package。
- [x] 实现配置加载和启动校验。
- [x] 实现 `/health`。
- [x] 实现统一错误响应与结构化日志。
- [x] 实现 Git 来源配置模型和安全校验。
- [x] 实现 manifest Codable 模型和完整校验。
- [x] 建立 SwiftFormat、SwiftLint strict、测试和 macOS release build 流程。
- [x] 完成 `linux/arm64` release build 与启动验证。

完成条件：服务在 macOS 测试通过，并在 `linux/arm64` 环境启动成功。

## Phase 2：Git 自动部署纵切

- [x] 持久化远程仓库、分支、凭据引用和自动部署条件。
- [x] 使用 `git ls-remote` 主动检测分支 SHA。
- [x] fetch 到 bare mirror，并把精确 commit 签出为不可变 release。
- [x] 根据 include/exclude 路径条件决定自动部署。
- [x] SQLite 持久化 Project、Release 与 Deployment。
- [x] 通过结构化参数调用 Git 和 Docker，并从 Dockerfile 构建 ARM64 镜像。
- [x] 实现 deploy、start、stop、restart 和有限日志读取。
- [x] 实现健康检查和失败恢复 previous release。
- [x] 重启服务后与 Docker 实际状态对账。

完成条件：向测试仓库的目标分支 push 后，Pi 自动构建并部署真实 ARM64 hello service；错误版本会恢复 previous release。

## Phase 3：Flutter Web 管理台

- [ ] 创建项目并配置 Git 来源、目标分支和触发条件。
- [ ] 展示部署历史与真实状态。
- [ ] 提供生命周期操作。
- [ ] 实时日志 WebSocket。
- [ ] 简体中文和英文资源。
- [ ] 响应式桌面与手机布局。

完成条件：不使用 SSH 即可完成 Phase 2 的全部日常操作。

## Phase 4：Pi 安装与自举

- [ ] 专用系统用户与目录权限。
- [x] `systemd` unit、安装和升级脚本。
- [ ] Tailscale 私网监听与管理员凭据初始化。
- [ ] Docker 日志轮转、磁盘保留策略和备份说明。
- [ ] 断电、重启、磁盘不足和容器异常测试。

完成条件：新刷 Raspberry Pi OS Lite 后，可按照文档稳定安装并恢复运行。

## MVP 之后

- Docker Compose 项目。
- 反向代理、域名与证书。
- 公网 webhook 和 CI/容器仓库推送模式。
- 手动 artifact 上传与离线部署。
- 多节点管理。
- 多用户与细粒度权限。
- 通知、指标和自动更新策略。

这些内容不会进入首个 MVP，以免阻塞最基本的可靠部署链路。
