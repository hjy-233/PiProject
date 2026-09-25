# Deployment Manifest v1

manifest 位于项目 Git 仓库内，描述如何构建并运行该仓库的一个精确 commit。首版使用 JSON，避免同时维护多种解析格式。

## 示例

```json
{
  "schemaVersion": 1,
  "projectId": "hello-service",
  "platform": "linux/arm64",
  "build": {
    "dockerfile": "Dockerfile",
    "context": "."
  },
  "command": ["/app/hello-service", "--host", "0.0.0.0", "--port", "8080"],
  "environment": [
    {
      "name": "APP_TOKEN",
      "required": true,
      "secret": true
    }
  ],
  "ports": [
    {
      "container": 8080,
      "host": 18080,
      "protocol": "tcp"
    }
  ],
  "volumes": [
    {
      "name": "data",
      "containerPath": "/app/data",
      "readOnly": false
    }
  ],
  "healthCheck": {
    "type": "http",
    "path": "/health",
    "port": 8080,
    "timeoutSeconds": 3,
    "startPeriodSeconds": 10,
    "retries": 3
  },
  "resources": {
    "memoryMiB": 256,
    "cpuPercent": 50
  },
  "restartPolicy": "unless-stopped"
}
```

## 字段规则

| 字段               | 规则                                                  |
|--------------------|-------------------------------------------------------|
| `schemaVersion`    | 必须为整数 `1`                                        |
| `projectId`        | 小写字母、数字和连字符；必须与 URL 中的项目一致       |
| `platform`         | 首版只接受 `linux/arm64`                              |
| `build.dockerfile` | 仓库内 Dockerfile 的安全相对路径                      |
| `build.context`    | 仓库内 build context 的安全相对路径；仓库根目录写 `.` |
| `command`          | 非空参数数组；不接受单个 Shell 字符串                 |
| `environment`      | 只声明变量名称与性质，值由 ProjectDeployer 单独保存   |
| `ports`            | 主机端口必须唯一且处于允许范围                        |
| `volumes`          | 只允许命名持久卷，不接受任意主机绝对路径              |
| `healthCheck`      | 首版支持 `http` 和 `tcp`；必须设置有限超时与次数      |
| `resources`        | 必须设置合理上限，具体默认值由服务配置决定            |
| `restartPolicy`    | 首版接受 `no`、`on-failure` 和 `unless-stopped`       |

## Git release 约定

- manifest 默认路径为仓库根目录的 `project-deployer.json`，也可在项目设置中修改。
- release 始终对应精确 commit SHA，不跟随会继续移动的分支名。
- ProjectDeployer 使用指定 Dockerfile 在 Pi 上构建 `linux/arm64` 镜像。
- Dockerfile 中的基础镜像应使用固定版本；正式使用时推荐进一步固定到 digest。
- 构建不获得 secret、Docker socket、其他项目目录或宿主机任意挂载。
- 手动上传 artifact 作为以后的离线兜底，不是首版主流程。

## 明确不支持

- Shell 管道、重定向、命令替换或 `sh -c`。
- `privileged`、host network、host PID namespace。
- 任意 `/dev` 设备映射。
- 任意主机目录挂载。
- 从 manifest 写入 secret 明文。
- 部署 `linux/amd64` 运行物并依赖模拟执行。
- 远程 Docker build context、特权 build 或构建阶段访问 Docker socket。

这些能力以后只能按明确用例逐项开放，不提供通用逃生口。
