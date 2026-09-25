// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'ProjectDeployer';

  @override
  String get overview => '总览';

  @override
  String get projects => '项目';

  @override
  String get refresh => '刷新';

  @override
  String get newProject => '新建项目';

  @override
  String get totalProjects => '项目总数';

  @override
  String get running => '运行中';

  @override
  String get stopped => '已停止';

  @override
  String get needsAttention => '需要处理';

  @override
  String get emptyProjects => '还没有项目';

  @override
  String get emptyProjectsHint => '创建第一个 Git 自动部署项目。';

  @override
  String get recentProjects => '项目状态';

  @override
  String get branch => '分支';

  @override
  String get lastUpdated => '最近更新';

  @override
  String get details => '详情';

  @override
  String get deployments => '部署记录';

  @override
  String get releases => '版本';

  @override
  String get logs => '日志';

  @override
  String get settings => '设置';

  @override
  String get sync => '立即同步';

  @override
  String get start => '启动';

  @override
  String get stop => '停止';

  @override
  String get restart => '重启';

  @override
  String get rollback => '回滚';

  @override
  String get deploy => '部署';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get deleteProject => '删除项目';

  @override
  String get purgeVolumes => '同时删除 Docker volume（不可恢复）';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get save => '保存';

  @override
  String get projectId => '项目 ID';

  @override
  String get projectName => '项目名称';

  @override
  String get repositoryUrl => 'Git 仓库 URL';

  @override
  String get credentialId => 'SSH 凭据 ID（可选）';

  @override
  String get pollSeconds => '轮询间隔（秒）';

  @override
  String get automatic => '自动部署';

  @override
  String get manual => '手动部署';

  @override
  String get status => '状态';

  @override
  String get currentCommit => '当前 commit';

  @override
  String get runtimeState => '容器状态';

  @override
  String get desiredState => '期望状态';

  @override
  String get error => '错误';

  @override
  String get retry => '重试';

  @override
  String get loading => '正在加载…';

  @override
  String get operationSucceeded => '操作完成';

  @override
  String get copy => '复制';

  @override
  String get noLogs => '暂无日志';

  @override
  String get serviceOnline => '服务在线';

  @override
  String get unknown => '未知';

  @override
  String get editProject => '编辑项目';

  @override
  String get back => '上一步';

  @override
  String get next => '下一步';

  @override
  String get saveOnly => '仅保存';

  @override
  String get saveAndSync => '保存并立即同步';

  @override
  String get basicInformation => '基本信息';

  @override
  String get gitSource => 'Git 来源';

  @override
  String get manifest => '部署清单';

  @override
  String get deploymentPolicy => '部署策略';

  @override
  String get environmentAndReview => '变量与确认';

  @override
  String get basicInformationHint => '先给项目命名。项目 ID 会自动生成，用于容器、镜像和数据目录。';

  @override
  String get projectIdHint => '小写字母、数字和短横线；创建后不可修改。';

  @override
  String get gitSourceHint =>
      '填写远程仓库并测试真实连接。ProjectDeployer 会读取分支和部署清单，但此时不会创建项目。';

  @override
  String get credential => 'SSH deploy key';

  @override
  String get noCredential => '不使用凭据（公开仓库）';

  @override
  String get manifestPath => '部署清单路径';

  @override
  String get manifestPathHint => '相对于仓库根目录，默认 project-deployer.json';

  @override
  String get gitAndManifestReady => 'Git 连接和部署清单均有效';

  @override
  String get manifestNeedsAttention => 'Git 已连接，但部署清单需要处理';

  @override
  String get manifestMissingHint =>
      '目标分支里没有部署清单。填写下面的运行信息并复制生成的 JSON，将文件提交并 push 到仓库后重新检测。';

  @override
  String get manifestInvalidHint =>
      '仓库中的部署清单无效或与项目 ID 不匹配。可参考下面生成的 JSON 修复，提交并 push 后重新检测。';

  @override
  String get build => 'Docker 构建';

  @override
  String get dockerfile => 'Dockerfile 路径';

  @override
  String get buildContext => '构建上下文';

  @override
  String get command => '容器启动命令';

  @override
  String get commandHint => '每行一个参数，例如第一行 /app/server';

  @override
  String get publishPort => '发布容器端口';

  @override
  String get containerPort => '容器端口';

  @override
  String get hostPort => '树莓派端口';

  @override
  String get persistentVolume => '使用持久化数据卷';

  @override
  String get volumeName => '数据卷名称';

  @override
  String get containerPath => '容器内路径';

  @override
  String get readOnly => '只读';

  @override
  String get healthCheck => '启用 HTTP 健康检查';

  @override
  String get healthPath => '健康检查路径';

  @override
  String get environmentDeclarations => '环境变量声明';

  @override
  String get addEnvironmentVariable => '添加环境变量';

  @override
  String get variableName => '变量名';

  @override
  String get required => '必填';

  @override
  String get secret => '敏感';

  @override
  String get memoryMiB => '内存限制（MiB）';

  @override
  String get cpuPercent => 'CPU 限制（%）';

  @override
  String get restartPolicy => '重启策略';

  @override
  String get copyJson => '复制 JSON';

  @override
  String get copied => '已复制';

  @override
  String get commitManifestHint =>
      '将 JSON 保存为上面指定的部署清单路径，commit 并 push 后点击“重新检测”。';

  @override
  String get testAgain => '测试连接并检测';

  @override
  String get deploymentPolicyHint => '选择何时部署新 commit，并可按变更路径过滤。';

  @override
  String get automaticHint => '发现符合条件的新 commit 后自动构建并切换容器。';

  @override
  String get manualHint => '只构建 ready release，需要你在管理台手动点击部署。';

  @override
  String get includePaths => '包含路径';

  @override
  String get excludePaths => '排除路径';

  @override
  String get pathsHint => '每行一个路径或 glob，例如 service/**';

  @override
  String get environmentValues => '环境变量值';

  @override
  String get environmentValuesHint =>
      '变量来自仓库中的部署清单。敏感值只写入 Pi 的本地数据库，不会返回到列表接口。';

  @override
  String get noEnvironmentVariables => '部署清单没有声明环境变量。';

  @override
  String get secretValueHint => '敏感值将隐藏显示';

  @override
  String get review => '创建前确认';

  @override
  String get invalidBasicInformation => '请填写项目名称，并使用有效的小写项目 ID。';

  @override
  String get invalidPollInterval => '轮询间隔必须在 15 到 3600 秒之间。';

  @override
  String get completeGitInformation => '请完整填写仓库、分支和部署清单路径。';

  @override
  String get requiredEnvironmentMissing => '请填写所有必填环境变量。';
}
