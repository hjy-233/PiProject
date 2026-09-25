# Git 自动部署

## 项目来源配置

Git 来源配置保存在 ProjectDeployer 数据库，不写入受部署仓库：

```json
{
  "repositoryURL": "ssh://git@github.com/dcstudio/example.git",
  "branch": "main",
  "manifestPath": "project-deployer.json",
  "pollIntervalSeconds": 60,
  "credentialId": "github-deploy-key",
  "trigger": {
    "mode": "automatic",
    "includePaths": ["Sources/**", "Package.swift"],
    "excludePaths": ["docs/**"]
  }
}
```

- `repositoryURL`：当前接受公开 HTTPS 或 `ssh://`，不允许在 URL 中保存密码或 token。
- `branch`：精确分支名，查询时转换为 `refs/heads/<branch>`，不把输入解释为任意 refspec。
- `manifestPath`：仓库内 manifest 的相对路径。
- `pollIntervalSeconds`：首版允许 15 到 3600 秒。
- `credentialId`：引用 ProjectDeployer 独立保存的 SSH deploy key，不是凭据内容。
- `includePaths`：为空表示任意文件变化都可触发；否则至少有一个匹配才触发。
- `excludePaths`：匹配的变更不计入触发判断。
- `mode`：`automatic` 自动部署，`manual` 只同步并等待确认。

manifest 文件自身发生变化时始终视为有效变更，避免部署规则更新被路径过滤忽略。

## 轮询而不是公网 webhook

首版由 Pi 周期性执行等价于以下查询：

```text
git ls-remote --exit-code <repository> refs/heads/<branch>
```

仓库没有变化时不会 fetch，也不会产生 deployment。这个方案只有出站连接，适合位于家庭网络和 Tailscale 内的 Pi。

Webhook 可以缩短延迟，但 GitHub、GitLab 等公网服务通常无法访问私有 Tailscale 地址。后续可增加 webhook relay 或由 CI 调用经过认证的部署入口，不替换轮询的兜底能力。

## Commit 与 release

```text
observed SHA
    │
    ├── 与 current SHA 相同 → 不操作
    │
    ▼
fetch 到 bare mirror
    │
    ▼
计算 changed paths
    │
    ├── 条件不匹配 → 记录 observed，不部署
    │
    ▼
签出精确 SHA → 校验 manifest → docker build
    │
    ▼
停止旧容器 → 启动新容器 → health check
    │
    ├── 成功 → 更新 successful SHA
    └── 失败 → 恢复 previous release
```

不能使用 `git pull` 直接更新正在运行的目录。bare mirror 只负责保存 Git 对象，每个 release 使用独立目录，因此分支移动、force-push 或构建失败都不会改写已经成功运行的版本。

## 连续 push

一个项目只能存在一个构建或部署操作。当前操作结束后，下一轮轮询会重新读取远端分支的最新 SHA，因此连续 push 不会并发构建同一个项目。

## 私有仓库

- SSH：每个 Git 服务或项目使用只读 deploy key，固定主机公钥，不启用交互式密码提示。
- HTTPS：当前只支持无需身份验证的仓库；HTTPS token 认证尚未实现。
- Git 子模块首版不支持，避免递归凭据和来源范围失控。
