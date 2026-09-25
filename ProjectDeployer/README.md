# ProjectDeployer

ProjectDeployer 是面向单台轻量项目部署管理工具。它通过 Flutter Web 提供管理界面，由运行在 Linux 上的 Swift 服务监视远程 Git 分支、构建版本、创建容器、执行生命周期操作和汇集日志。

## 技术边界

| 部分         | 技术              | 职责                                             |
|--------------|-------------------|--------------------------------------------------|
| 管理台       | Flutter Web       | 项目列表、Git 来源、部署操作、状态与日志         |
| 控制服务     | Swift             | Git 观察、API、校验、状态机、持久化、Docker 调度 |
| 项目运行环境 | Docker            | 隔离项目、限制资源、提供生命周期与日志能力       |
| 系统托管     | systemd           | 启动和守护 ProjectDeployer 自身                  |
| 数据         | SQLite + 文件目录 | 元数据、Git mirror、release 和持久卷             |

## 目标环境

- Raspberry Pi OS Lite 64-bit
- Debian 12 Bookworm 或 Debian 13 Trixie
- `arm64` / `aarch64`
- Docker Engine
- 单机、单管理员、Tailscale 私网访问

## 当前可用范围

Swift 控制服务与 Flutter Web 管理台均已可用。管理台提供总览、项目配置、同步与部署、容器生命周期、版本、部署记录和日志界面；控制服务负责持久化配置、轮询远程 Git 分支、按路径规则构建并部署 Docker 容器。系统还包含 SSH 凭据管理、历史清理、磁盘保护、Docker 对账与一致性备份。安装后直接访问 `http://pi.local:10000/`。安装与更新方式见 [Raspberry Pi 安装与更新](docs/installation.md)，接口调用见 [HTTP API](docs/api.md)，实机结果见 [Raspberry Pi 实机验收](docs/acceptance.md)。

## 规划目录

```text
ProjectDeployer/
├── service/                 # Swift Package：控制服务
├── console/                 # Flutter Web：管理台
├── deploy/                  # systemd、安装和升级文件
├── docs/
│   ├── architecture.md
│   ├── console-ui.md
│   ├── git-deployment.md
│   ├── manifest-v1.md
│   └── roadmap.md
└── README.md
```

共享代码只在出现真实重复后提取。
