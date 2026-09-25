# Raspberry Pi 安装与更新

## 前置条件

- Raspberry Pi OS Lite 64-bit，架构为 `aarch64`。
- Swift、Git、Docker Engine、curl 可用。
- 当前用户可以执行 Docker 命令，并且 user systemd 可用。

先确认：

```bash
swift --version
git --version
docker version
systemctl --user status
```

若服务需要在退出 SSH 后和开机时继续运行，执行一次：

```bash
sudo loginctl enable-linger "$USER"
```

## 安装

推荐在 Mac 的 ProjectDeployer 仓库根目录执行：

```bash
./deploy/deploy-from-mac.sh
```

脚本将源码同步到 Pi 的构建缓存目录，在 Pi 上执行 ARM64 release 编译，并且只在编译成功后安装。新二进制通过健康检查后会删除旧二进制版本，只保留当前版本；`~/.local/share/project-deployer/` 内的 SQLite、Git mirror、项目 release 与凭据数据不会被删除。默认目标为 `hjy@pi.local`，需要修改时可设置 `PROJECT_DEPLOYER_TARGET`。

也可以登录 Pi，在仓库根目录直接执行：

```bash
./deploy/install-user.sh
```

安装器会在 Pi 上构建 release 版本，二进制通过构建时写入的 RUNPATH 使用已安装 Swift 工具链的运行库，并安装到
`~/.local/lib/project-deployer/releases/`，原子切换 `current` 软链接，然后启用
`project-deployer.service`。新版本健康检查失败时会恢复旧软链接并重启旧版本。

配置文件位于 `~/.config/project-deployer/environment`，数据位于
`~/.local/share/project-deployer/`。更新时重新拉取仓库后再次运行同一个脚本；
ProjectDeployer 不负责部署自身。

## 检查运行状态

```bash
systemctl --user status project-deployer.service
journalctl --user --unit project-deployer.service --follow
curl --fail http://127.0.0.1:10000/health
curl --fail http://pi.local:10000/health
```

部署脚本将服务监听在 `0.0.0.0:10000`，可通过局域网主机名、IP 或 Tailscale 地址访问。当前版本没有认证层，请勿将该端口暴露到公网。具体请求见 [HTTP API](api.md)。
