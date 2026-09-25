# HTTP API

部署脚本将 ProjectDeployer 固定监听在 `0.0.0.0:10000`，局域网中可直接访问：

```bash
curl --fail http://pi.local:10000/health
```

通过 Tailscale 时可将 `pi.local` 换成 Pi 的 Tailscale 设备名或 `100.x.x.x` 地址。当前版本没有认证层，不应将端口转发到公网。

## 创建项目

Flutter 管理台的创建向导会先调用 Git inspection 接口，真实连接远程仓库、确认目标分支并读取部署清单。仓库没有部署清单时，向导会根据 Docker 构建、端口、volume、健康检查、资源限制和环境变量声明生成可复制的 `project-deployer.json`；文件提交并 push 后必须重新检测通过，才能创建项目。

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

## 编辑与删除项目

编辑使用完整替换语义，项目 id 不可修改：

```bash
curl --fail-with-body --request PUT \
  --header 'Content-Type: application/json' \
  --data @project-update.json \
  http://pi.local:10000/api/v1/projects/hello-service
```

删除会清理容器、镜像、Git mirror、release 目录和数据库记录，但默认保留 Docker volume：

```bash
curl --fail-with-body --request DELETE \
  http://pi.local:10000/api/v1/projects/hello-service
```

确认业务数据不再需要时才显式清理 volume：

```bash
curl --fail-with-body --request DELETE \
  'http://pi.local:10000/api/v1/projects/hello-service?purgeVolumes=true'
```

`purgeVolumes=true` 不可恢复，执行前应单独备份业务数据。

## 查询与操作

| 方法 | 路径 | 请求体或参数 |
| --- | --- | --- |
| `GET` | `/health` | 无 |
| `GET` | `/api/v1/projects` | 无 |
| `POST` | `/api/v1/projects` | 项目与 Git 来源 JSON |
| `PUT` | `/api/v1/projects/{id}` | 名称、Git 来源与环境变量 JSON |
| `DELETE` | `/api/v1/projects/{id}` | 可选 `purgeVolumes=true` |
| `GET` | `/api/v1/projects/{id}` | 无 |
| `POST` | `/api/v1/projects/{id}/sync` | 无 |
| `POST` | `/api/v1/projects/{id}/deploy` | `{"releaseId":"..."}` |
| `POST` | `/api/v1/projects/{id}/start` | 无 |
| `POST` | `/api/v1/projects/{id}/stop` | 无 |
| `POST` | `/api/v1/projects/{id}/restart` | 无 |
| `POST` | `/api/v1/projects/{id}/rollback` | 无 |
| `GET` | `/api/v1/projects/{id}/logs?lines=200` | `lines` 范围最终限制为 1 到 1000 |
| `GET` | `/api/v1/git/credentials` | 返回已安装 SSH deploy key 的 ID，不返回私钥内容 |
| `POST` | `/api/v1/sources/git/inspect` | `projectId` 与完整 Git source；返回分支、commit 和 manifest 校验结果 |

`automatic` 项目在同步完成后直接部署；`manual` 项目只生成 `ready` release，再调用 `deploy`。

## SSH 私钥

私有 SSH 仓库通过 `credentialId` 引用部署密钥。私钥不经过当前未加密的 HTTP API，请登录 Pi 后管理：

```bash
project-deployer-manage-ssh credential install github-hello-service ./deploy-key
project-deployer-manage-ssh credential list
project-deployer-manage-ssh credential remove github-hello-service
```

管理 Git 主机公钥：

```bash
project-deployer-manage-ssh known-host add github.com
project-deployer-manage-ssh known-host list
project-deployer-manage-ssh known-host remove github.com
```

新增主机后必须通过可信渠道核对显示的公钥指纹，不能只相信本次网络扫描。
密钥建议使用仓库级只读 deploy key。公有 HTTPS 仓库无需 `credentialId`；当前版本尚未接入 HTTPS token。
