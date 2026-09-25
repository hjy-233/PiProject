# HTTP API

部署脚本将 ProjectDeployer 固定监听在 `0.0.0.0:10000`，局域网中可直接访问：

```bash
curl --fail http://pi.local:10000/health
```

通过 Tailscale 时可将 `pi.local` 换成 Pi 的 Tailscale 设备名或 `100.x.x.x` 地址。当前版本没有认证层，不应将端口转发到公网。

## 创建项目

```bash
curl --fail-with-body \
  --request POST \
  --header 'Content-Type: application/json' \
  --data @- \
  http://pi.local:10000/api/v1/projects <<'JSON'
{
  "id": "hello-service",
  "name": "Hello Service",
  "source": {
    "repositoryURL": "ssh://git@github.com/example/hello-service.git",
    "branch": "main",
    "manifestPath": "project-deployer.json",
    "pollIntervalSeconds": 60,
    "credentialId": "github-hello-service",
    "trigger": {
      "mode": "automatic",
      "includePaths": [],
      "excludePaths": ["docs/**"]
    }
  },
  "environment": {}
}
JSON
```

项目 id 创建后不可更改。环境变量的值保存在权限为 `0600` 的本机 SQLite 文件中，列表接口只返回变量名。

## 查询与操作

| 方法 | 路径 | 请求体或参数 |
| --- | --- | --- |
| `GET` | `/health` | 无 |
| `GET` | `/api/v1/projects` | 无 |
| `POST` | `/api/v1/projects` | 项目与 Git 来源 JSON |
| `GET` | `/api/v1/projects/{id}` | 无 |
| `POST` | `/api/v1/projects/{id}/sync` | 无 |
| `POST` | `/api/v1/projects/{id}/deploy` | `{"releaseId":"..."}` |
| `POST` | `/api/v1/projects/{id}/start` | 无 |
| `POST` | `/api/v1/projects/{id}/stop` | 无 |
| `POST` | `/api/v1/projects/{id}/restart` | 无 |
| `POST` | `/api/v1/projects/{id}/rollback` | 无 |
| `GET` | `/api/v1/projects/{id}/logs?lines=200` | `lines` 范围最终限制为 1 到 1000 |

`automatic` 项目在同步完成后直接部署；`manual` 项目只生成 `ready` release，再调用 `deploy`。

## SSH 私钥

私有 SSH 仓库通过 `credentialId` 引用部署密钥：

```bash
install -m 600 ./deploy-key ~/.local/share/project-deployer/credentials/github-hello-service
ssh-keyscan github.com >> ~/.local/share/project-deployer/known_hosts
chmod 600 ~/.local/share/project-deployer/known_hosts
```

密钥建议使用仓库级只读 deploy key。公有 HTTPS 仓库无需 `credentialId`；当前版本尚未接入 HTTPS token。
