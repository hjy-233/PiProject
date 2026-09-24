# ProjectDeployer

ProjectDeployer 是面向单台 Raspberry Pi 的轻量项目部署管理工具。它通过 Flutter Web 提供管理界面，由运行在 Raspberry Pi OS Lite 上的 Swift 服务监视远程 Git 分支、构建版本、创建容器、执行生命周期操作和汇集日志。

## 产品目标

首个可用版本需要完成一条真实部署链路：

1. 注册一个远程 Git 仓库、目标分支和自动部署条件。
2. 主动检测目标分支的新 commit，不要求把 Pi 管理端口暴露到公网。
3. 条件匹配后签出精确 commit，保存为不可变 release 并构建容器镜像。
4. 启动、停止和重启项目容器，并展示当前状态与实时日志。
5. 新版本启动失败时恢复上一个可用版本。
6. Raspberry Pi 或 ProjectDeployer 重启后恢复真实状态。

## 技术边界

| 部分 | 技术 | 职责 |
| --- | --- | --- |
| 管理台 | Flutter Web | 项目列表、Git 来源、部署操作、状态与日志 |
| 控制服务 | Swift | Git 观察、API、校验、状态机、持久化、Docker 调度 |
| 项目运行环境 | Docker | 隔离项目、限制资源、提供生命周期与日志能力 |
| 系统托管 | systemd | 启动和守护 ProjectDeployer 自身 |
| 数据 | SQLite + 文件目录 | 元数据、Git mirror、release 和持久卷 |

ProjectDeployer 只负责部署，不承载 MyBot、谜题解题器等产品的业务接口。其他项目是独立容器、独立数据和独立发布单元。

## 目标环境

- Raspberry Pi OS Lite 64-bit
- Debian 12 Bookworm 或 Debian 13 Trixie
- `arm64` / `aarch64`
- Docker Engine
- 单机、单管理员、Tailscale 私网访问

## 规划目录

```text
ProjectDeployer/
├── service/                 # Swift Package：控制服务
├── console/                 # Flutter Web：管理台
├── deploy/                  # systemd、安装和升级文件
├── docs/
│   ├── architecture.md
│   ├── git-deployment.md
│   ├── manifest-v1.md
│   └── roadmap.md
└── README.md
```

共享代码只在出现真实重复后提取，不预先创建通用框架。

## 当前状态

Phase 1 的服务骨架已经完成：Swift 服务具备配置加载、健康检查、统一错误结构、Git 来源配置校验和 manifest v1 校验，并已通过 macOS build、lint 与测试。在 Raspberry Pi OS Lite 64-bit（Debian 13、`aarch64`）上，Swift 6.4 release build、13 项测试、release 二进制启动、`/health` 与 Git 来源配置接口均已验证通过。Flutter 管理台尚未生成。
