# ProjectDeployer 架构

## 1. 设计原则

- ProjectDeployer 自身由 `systemd` 托管，不能依赖自己完成安装或恢复。
- 远端分支出现新 commit 与切换运行版本是两个独立动作；同步不会立即影响当前服务。
- 每个 release 对应精确 commit SHA，一经创建不可修改。
- 首版由 Pi 主动轮询 Git 远端，不开放公网 webhook 接口。
- 所有外部命令使用可执行文件路径与参数数组调用，不拼接 Shell 字符串。
- 同一个项目的部署操作串行执行，避免并发 start、stop、deploy 互相覆盖。
- 数据库记录期望状态，Docker 提供实际状态；启动时必须重新对账。
- 管理接口默认仅对本机或 Tailscale 私网开放。

## 2. 系统结构

```text
Flutter Web Console
        │
        │ HTTPS / JSON / WebSocket
        ▼
Swift Control Service ───── SQLite
        │                       └── project/release/deployment metadata
        ├── outbound poll/fetch ───── Remote Git
        │
        │ structured argv
        ▼
Docker CLI / Engine
        │
        ├── Project A container
        ├── Project B container
        └── Project C container

/var/lib/project-deployer/
├── repositories/
├── projects/
├── volumes/
└── project-deployer.sqlite
```

Swift 服务采用 Hummingbird 作为轻量 HTTP 层，使用 Swift Concurrency 管理任务生命周期。Docker 操作通过 Swift Subprocess 以参数数组调用本机 Docker CLI；首版不直接实现 Docker Engine HTTP 协议。

## 3. 核心模型

### Project

一个长期存在的部署目标，拥有稳定的项目标识、显示名称、Git 来源、部署条件和目标端口。

### Git source

远程仓库 URL、目标分支、manifest 路径、轮询间隔、凭据引用和路径条件。凭据值独立保存，不进入 URL 或项目仓库。

### Release

精确 commit、已校验 manifest 和构建镜像摘要的不可变组合。Release 进入 `ready` 后不再修改。

### Deployment

一次将某个 release 切换为运行版本的操作，记录开始时间、结束时间、结果和失败原因。

### Runtime state

从 Docker 查询得到的事实状态：`created`、`running`、`stopped`、`failed` 或 `unknown`。数据库不能单独作为项目正在运行的依据。

## 4. 部署流程

1. 使用 `git ls-remote` 查询精确分支 ref；SHA 未变化时结束。
2. 将新 commit fetch 到项目的 bare mirror，不对可变工作目录执行 `git pull`。
3. 比较上次成功 commit 与新 commit 的变更路径，判断自动部署条件。
4. 条件匹配后将精确 commit 签出到新的只读 release 目录。
5. 从仓库读取并校验 manifest、Dockerfile 路径、平台、命令、端口、环境变量声明和健康检查。
6. 使用 release 内容构建带 commit 标签的本地镜像，并记录最终 image digest。
7. 串行锁定目标项目，记录 deployment，停止当前容器并启动新容器。
8. 在限定时间内执行健康检查。
9. 成功则把新 release 设为 current；失败则删除失败容器并重新启动 previous release。

首版允许短暂停机，不实现蓝绿部署。这个取舍可以显著降低单机端口切换复杂度，同时仍保证失败可恢复。

## 5. API 草案

所有资源使用 `/api/v1` 前缀：

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| `GET` | `/health` | ProjectDeployer 自身健康检查 |
| `GET` | `/api/v1/projects` | 项目列表及真实运行状态 |
| `POST` | `/api/v1/projects` | 创建项目 |
| `GET` | `/api/v1/projects/{id}` | 项目详情与 release 历史 |
| `POST` | `/api/v1/projects/{id}/sync` | 立即检查远端分支并按策略部署 |
| `POST` | `/api/v1/projects/{id}/deploy` | 手动部署已经同步的指定 release |
| `POST` | `/api/v1/projects/{id}/start` | 启动当前 release |
| `POST` | `/api/v1/projects/{id}/stop` | 停止当前 release |
| `POST` | `/api/v1/projects/{id}/restart` | 重启当前 release |
| `POST` | `/api/v1/projects/{id}/rollback` | 切回上一个可用 release |
| `GET` | `/api/v1/projects/{id}/logs` | 查询有限历史日志 |
| `GET` | `/api/v1/projects/{id}/logs/stream` | WebSocket 实时日志 |

错误响应必须带稳定错误码和可操作说明，不向客户端返回原始密钥、完整环境变量或内部调用栈。

## 6. 安全模型

ProjectDeployer 能控制 Docker，实际拥有接近 root 的系统能力，因此不能作为普通公网应用处理。

- 初期只绑定 loopback 或 Tailscale 地址。
- 即使在 Tailscale 内也使用独立管理员凭据。
- 管理员密码只保存密码哈希；Git deploy key 或 token 必须以受限权限保存，后续接入系统密钥存储或静态加密。
- secret 值不写入 manifest、日志、Git URL 或项目仓库。
- Git HTTPS URL 不嵌入 token；SSH 使用只读 deploy key，并固定已确认的主机密钥。
- 只接受 `https` 和 `ssh` 仓库来源，不接受本机路径或不加密的 `git`、`http` 来源。
- 构建容器不挂载 Docker socket、ProjectDeployer 凭据或其他项目数据。
- Dockerfile 与 build context 必须位于精确 commit 的 release 目录中。
- 容器默认使用只读 release 挂载、非 root 用户、最小 capability 和资源限制。
- 端口必须显式声明并检查冲突。
- Docker socket 不通过 TCP 暴露。

首版不包含多用户、权限角色、公开注册或互联网管理入口。

## 7. 状态与并发

Swift 服务为每个 project 维护一个操作 actor。同一 project 同时只允许一个变更操作，不同 project 可以并行。

部署期间再次检测到更新时只记录最新待处理 SHA；当前部署结束后重新检查，避免同一项目并发构建。连续 push 可以跳过中间 commit，但不会把未通过健康检查的 commit 标记为成功。

服务退出时取消未完成的观察任务；不创建脱离生命周期、无法回收的 `Task`。启动后执行一次 reconciliation：读取数据库，再通过 Docker label 查询实际容器，修正过期状态并记录异常。

每个受管容器至少带有以下 label：

```text
dev.dcstudio.project-deployer.managed=true
dev.dcstudio.project-deployer.project=<project-id>
dev.dcstudio.project-deployer.release=<release-id>
```

## 8. 可观测性

- 控制服务使用结构化日志，并为每次 deployment 生成关联 ID。
- 日志默认隐藏 authorization、secret 与完整环境变量。
- Docker 日志设置轮转上限，避免耗尽 SD 卡。
- `/health` 只说明控制服务是否可用；项目健康状态通过项目 API 返回。

## 9. 前端约束

- Flutter 管理台首版面向桌面浏览器和手机浏览器自适应布局。
- 所有用户可见文本从第一天进入本地化资源，首批语言为简体中文和英文。
- 危险操作明确展示项目名称和目标 release。
- 状态不能仅依靠颜色表达。
- 日志视图必须有暂停自动滚动、复制和有限缓存，避免无界内存增长。

## 10. 验证策略

- Swift：SwiftFormat、SwiftLint strict、单元测试和 Linux release build。
- Flutter：`dart format`、`flutter analyze`、widget tests 和 Web release build。
- Git 来源：非法 URL、分支名、路径条件、凭据隔离、force-push 和连续 push 测试。
- manifest：正常、缺字段、恶意 Dockerfile/context 路径和端口冲突测试。
- Docker：使用隔离的测试项目验证启动、停止、重启、失败回滚和 daemon 重启对账。
- Raspberry Pi：在真实 `linux/arm64` 环境完成最终冒烟测试，Mac 本地成功不代替 Pi 验证。
