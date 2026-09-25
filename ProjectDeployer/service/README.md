# Service source layout

`ProjectDeployerService` 仍是一个 SwiftPM executable target，目录只表达职责，不引入额外 module：

```text
Sources/ProjectDeployerService/
├── Application/       # 启动入口、HTTP 路由、配置和运行时装配
├── Domain/            # API/持久化模型、Git 来源与 manifest 规则
├── Deployment/        # 同步、构建、部署、回滚、健康检查和生命周期
└── Infrastructure/    # Git、Docker、SQLite 与子进程适配
    ├── Docker/
    ├── Git/
    ├── Persistence/
    └── Process/
```

测试目录使用相同分类。新增代码放入拥有该行为的最小目录，不因文件数量增加新的抽象层。
