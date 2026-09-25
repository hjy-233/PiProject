# Raspberry Pi 实机验收

验收日期：2026-09-25。目标环境为 Raspberry Pi OS Lite 64-bit、Linux ARM64、Docker Engine 29.8.1。

## 已通过

- 使用独立 SSH deploy key 和 ProjectDeployer `known_hosts` 拉取真实 SSH remote。
- 首次 push 构建 ARM64 image、启动容器并通过 HTTP health check。
- 连续 push 两个 commit 时最终部署分支最新 commit，未并发运行两个项目操作。
- 进程立即退出的错误 release 健康检查失败，deployment 标记失败，previous release 自动恢复并继续响应。
- ProjectDeployer 服务重启后读取 SQLite 并与现有 Docker 容器对账，没有重复创建容器。
- 强制删除受管容器后，周期对账从 current release 自动重建容器。
- 自动清理超过保留上限的 release 目录、镜像和数据库记录。
- 编辑项目配置成功；普通删除清理容器、镜像、mirror、release 和记录；显式 `purgeVolumes=true` 清理项目 volume。
- 一致性备份、SHA-256 校验和服务自动恢复通过。
- Mac 可通过 `http://pi.local:10000` 调用 API。

## 尚需人工执行

Docker daemon 和整机重启需要 Pi 的交互式 sudo 密码，本次自动验收无法执行。代码路径已通过更严格的“强制删除容器后自动重建”测试，但发布前仍应执行：

```bash
sudo systemctl restart docker
sudo reboot
```

两次操作后分别确认：

```bash
systemctl --user is-active project-deployer.service
curl --fail http://127.0.0.1:10000/health
docker ps --filter label=dev.dcstudio.project-deployer.managed=true
```

不要在远程连接之外没有恢复手段时执行断电测试。
