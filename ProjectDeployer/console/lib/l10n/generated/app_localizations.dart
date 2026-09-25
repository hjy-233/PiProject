import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'ProjectDeployer'**
  String get appTitle;

  /// No description provided for @overview.
  ///
  /// In zh, this message translates to:
  /// **'总览'**
  String get overview;

  /// No description provided for @projects.
  ///
  /// In zh, this message translates to:
  /// **'项目'**
  String get projects;

  /// No description provided for @refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get refresh;

  /// No description provided for @newProject.
  ///
  /// In zh, this message translates to:
  /// **'新建项目'**
  String get newProject;

  /// No description provided for @totalProjects.
  ///
  /// In zh, this message translates to:
  /// **'项目总数'**
  String get totalProjects;

  /// No description provided for @running.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get running;

  /// No description provided for @stopped.
  ///
  /// In zh, this message translates to:
  /// **'已停止'**
  String get stopped;

  /// No description provided for @needsAttention.
  ///
  /// In zh, this message translates to:
  /// **'需要处理'**
  String get needsAttention;

  /// No description provided for @emptyProjects.
  ///
  /// In zh, this message translates to:
  /// **'还没有项目'**
  String get emptyProjects;

  /// No description provided for @emptyProjectsHint.
  ///
  /// In zh, this message translates to:
  /// **'创建第一个 Git 自动部署项目。'**
  String get emptyProjectsHint;

  /// No description provided for @recentProjects.
  ///
  /// In zh, this message translates to:
  /// **'项目状态'**
  String get recentProjects;

  /// No description provided for @branch.
  ///
  /// In zh, this message translates to:
  /// **'分支'**
  String get branch;

  /// No description provided for @lastUpdated.
  ///
  /// In zh, this message translates to:
  /// **'最近更新'**
  String get lastUpdated;

  /// No description provided for @details.
  ///
  /// In zh, this message translates to:
  /// **'详情'**
  String get details;

  /// No description provided for @deployments.
  ///
  /// In zh, this message translates to:
  /// **'部署记录'**
  String get deployments;

  /// No description provided for @releases.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get releases;

  /// No description provided for @logs.
  ///
  /// In zh, this message translates to:
  /// **'日志'**
  String get logs;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @sync.
  ///
  /// In zh, this message translates to:
  /// **'立即同步'**
  String get sync;

  /// No description provided for @start.
  ///
  /// In zh, this message translates to:
  /// **'启动'**
  String get start;

  /// No description provided for @stop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get stop;

  /// No description provided for @restart.
  ///
  /// In zh, this message translates to:
  /// **'重启'**
  String get restart;

  /// No description provided for @rollback.
  ///
  /// In zh, this message translates to:
  /// **'回滚'**
  String get rollback;

  /// No description provided for @deploy.
  ///
  /// In zh, this message translates to:
  /// **'部署'**
  String get deploy;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @deleteProject.
  ///
  /// In zh, this message translates to:
  /// **'删除项目'**
  String get deleteProject;

  /// No description provided for @purgeVolumes.
  ///
  /// In zh, this message translates to:
  /// **'同时删除 Docker volume（不可恢复）'**
  String get purgeVolumes;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @projectId.
  ///
  /// In zh, this message translates to:
  /// **'项目 ID'**
  String get projectId;

  /// No description provided for @projectName.
  ///
  /// In zh, this message translates to:
  /// **'项目名称'**
  String get projectName;

  /// No description provided for @repositoryUrl.
  ///
  /// In zh, this message translates to:
  /// **'Git 仓库 URL'**
  String get repositoryUrl;

  /// No description provided for @credentialId.
  ///
  /// In zh, this message translates to:
  /// **'SSH 凭据 ID（可选）'**
  String get credentialId;

  /// No description provided for @pollSeconds.
  ///
  /// In zh, this message translates to:
  /// **'轮询间隔（秒）'**
  String get pollSeconds;

  /// No description provided for @automatic.
  ///
  /// In zh, this message translates to:
  /// **'自动部署'**
  String get automatic;

  /// No description provided for @manual.
  ///
  /// In zh, this message translates to:
  /// **'手动部署'**
  String get manual;

  /// No description provided for @status.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get status;

  /// No description provided for @currentCommit.
  ///
  /// In zh, this message translates to:
  /// **'当前 commit'**
  String get currentCommit;

  /// No description provided for @runtimeState.
  ///
  /// In zh, this message translates to:
  /// **'容器状态'**
  String get runtimeState;

  /// No description provided for @desiredState.
  ///
  /// In zh, this message translates to:
  /// **'期望状态'**
  String get desiredState;

  /// No description provided for @error.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'正在加载…'**
  String get loading;

  /// No description provided for @operationSucceeded.
  ///
  /// In zh, this message translates to:
  /// **'操作完成'**
  String get operationSucceeded;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @noLogs.
  ///
  /// In zh, this message translates to:
  /// **'暂无日志'**
  String get noLogs;

  /// No description provided for @serviceOnline.
  ///
  /// In zh, this message translates to:
  /// **'服务在线'**
  String get serviceOnline;

  /// No description provided for @unknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get unknown;

  /// No description provided for @editProject.
  ///
  /// In zh, this message translates to:
  /// **'编辑项目'**
  String get editProject;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'上一步'**
  String get back;

  /// No description provided for @next.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get next;

  /// No description provided for @saveOnly.
  ///
  /// In zh, this message translates to:
  /// **'仅保存'**
  String get saveOnly;

  /// No description provided for @saveAndSync.
  ///
  /// In zh, this message translates to:
  /// **'保存并立即同步'**
  String get saveAndSync;

  /// No description provided for @basicInformation.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get basicInformation;

  /// No description provided for @gitSource.
  ///
  /// In zh, this message translates to:
  /// **'Git 来源'**
  String get gitSource;

  /// No description provided for @manifest.
  ///
  /// In zh, this message translates to:
  /// **'部署清单'**
  String get manifest;

  /// No description provided for @deploymentPolicy.
  ///
  /// In zh, this message translates to:
  /// **'部署策略'**
  String get deploymentPolicy;

  /// No description provided for @environmentAndReview.
  ///
  /// In zh, this message translates to:
  /// **'变量与确认'**
  String get environmentAndReview;

  /// No description provided for @basicInformationHint.
  ///
  /// In zh, this message translates to:
  /// **'先给项目命名。项目 ID 会自动生成，用于容器、镜像和数据目录。'**
  String get basicInformationHint;

  /// No description provided for @projectIdHint.
  ///
  /// In zh, this message translates to:
  /// **'小写字母、数字和短横线；创建后不可修改。'**
  String get projectIdHint;

  /// No description provided for @gitSourceHint.
  ///
  /// In zh, this message translates to:
  /// **'填写远程仓库并测试真实连接。ProjectDeployer 会读取分支和部署清单，但此时不会创建项目。'**
  String get gitSourceHint;

  /// No description provided for @credential.
  ///
  /// In zh, this message translates to:
  /// **'SSH deploy key'**
  String get credential;

  /// No description provided for @noCredential.
  ///
  /// In zh, this message translates to:
  /// **'不使用凭据（公开仓库）'**
  String get noCredential;

  /// No description provided for @manifestPath.
  ///
  /// In zh, this message translates to:
  /// **'部署清单路径'**
  String get manifestPath;

  /// No description provided for @manifestPathHint.
  ///
  /// In zh, this message translates to:
  /// **'相对于仓库根目录，默认 project-deployer.json'**
  String get manifestPathHint;

  /// No description provided for @gitAndManifestReady.
  ///
  /// In zh, this message translates to:
  /// **'Git 连接和部署清单均有效'**
  String get gitAndManifestReady;

  /// No description provided for @manifestNeedsAttention.
  ///
  /// In zh, this message translates to:
  /// **'Git 已连接，但部署清单需要处理'**
  String get manifestNeedsAttention;

  /// No description provided for @manifestMissingHint.
  ///
  /// In zh, this message translates to:
  /// **'目标分支里没有部署清单。填写下面的运行信息并复制生成的 JSON，将文件提交并 push 到仓库后重新检测。'**
  String get manifestMissingHint;

  /// No description provided for @manifestInvalidHint.
  ///
  /// In zh, this message translates to:
  /// **'仓库中的部署清单无效或与项目 ID 不匹配。可参考下面生成的 JSON 修复，提交并 push 后重新检测。'**
  String get manifestInvalidHint;

  /// No description provided for @build.
  ///
  /// In zh, this message translates to:
  /// **'Docker 构建'**
  String get build;

  /// No description provided for @dockerfile.
  ///
  /// In zh, this message translates to:
  /// **'Dockerfile 路径'**
  String get dockerfile;

  /// No description provided for @buildContext.
  ///
  /// In zh, this message translates to:
  /// **'构建上下文'**
  String get buildContext;

  /// No description provided for @command.
  ///
  /// In zh, this message translates to:
  /// **'容器启动命令'**
  String get command;

  /// No description provided for @commandHint.
  ///
  /// In zh, this message translates to:
  /// **'每行一个参数，例如第一行 /app/server'**
  String get commandHint;

  /// No description provided for @publishPort.
  ///
  /// In zh, this message translates to:
  /// **'发布容器端口'**
  String get publishPort;

  /// No description provided for @containerPort.
  ///
  /// In zh, this message translates to:
  /// **'容器端口'**
  String get containerPort;

  /// No description provided for @hostPort.
  ///
  /// In zh, this message translates to:
  /// **'树莓派端口'**
  String get hostPort;

  /// No description provided for @persistentVolume.
  ///
  /// In zh, this message translates to:
  /// **'使用持久化数据卷'**
  String get persistentVolume;

  /// No description provided for @volumeName.
  ///
  /// In zh, this message translates to:
  /// **'数据卷名称'**
  String get volumeName;

  /// No description provided for @containerPath.
  ///
  /// In zh, this message translates to:
  /// **'容器内路径'**
  String get containerPath;

  /// No description provided for @readOnly.
  ///
  /// In zh, this message translates to:
  /// **'只读'**
  String get readOnly;

  /// No description provided for @healthCheck.
  ///
  /// In zh, this message translates to:
  /// **'启用 HTTP 健康检查'**
  String get healthCheck;

  /// No description provided for @healthPath.
  ///
  /// In zh, this message translates to:
  /// **'健康检查路径'**
  String get healthPath;

  /// No description provided for @environmentDeclarations.
  ///
  /// In zh, this message translates to:
  /// **'环境变量声明'**
  String get environmentDeclarations;

  /// No description provided for @addEnvironmentVariable.
  ///
  /// In zh, this message translates to:
  /// **'添加环境变量'**
  String get addEnvironmentVariable;

  /// No description provided for @variableName.
  ///
  /// In zh, this message translates to:
  /// **'变量名'**
  String get variableName;

  /// No description provided for @required.
  ///
  /// In zh, this message translates to:
  /// **'必填'**
  String get required;

  /// No description provided for @secret.
  ///
  /// In zh, this message translates to:
  /// **'敏感'**
  String get secret;

  /// No description provided for @memoryMiB.
  ///
  /// In zh, this message translates to:
  /// **'内存限制（MiB）'**
  String get memoryMiB;

  /// No description provided for @cpuPercent.
  ///
  /// In zh, this message translates to:
  /// **'CPU 限制（%）'**
  String get cpuPercent;

  /// No description provided for @restartPolicy.
  ///
  /// In zh, this message translates to:
  /// **'重启策略'**
  String get restartPolicy;

  /// No description provided for @copyJson.
  ///
  /// In zh, this message translates to:
  /// **'复制 JSON'**
  String get copyJson;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get copied;

  /// No description provided for @commitManifestHint.
  ///
  /// In zh, this message translates to:
  /// **'将 JSON 保存为上面指定的部署清单路径，commit 并 push 后点击“重新检测”。'**
  String get commitManifestHint;

  /// No description provided for @testAgain.
  ///
  /// In zh, this message translates to:
  /// **'测试连接并检测'**
  String get testAgain;

  /// No description provided for @deploymentPolicyHint.
  ///
  /// In zh, this message translates to:
  /// **'选择何时部署新 commit，并可按变更路径过滤。'**
  String get deploymentPolicyHint;

  /// No description provided for @automaticHint.
  ///
  /// In zh, this message translates to:
  /// **'发现符合条件的新 commit 后自动构建并切换容器。'**
  String get automaticHint;

  /// No description provided for @manualHint.
  ///
  /// In zh, this message translates to:
  /// **'只构建 ready release，需要你在管理台手动点击部署。'**
  String get manualHint;

  /// No description provided for @includePaths.
  ///
  /// In zh, this message translates to:
  /// **'包含路径'**
  String get includePaths;

  /// No description provided for @excludePaths.
  ///
  /// In zh, this message translates to:
  /// **'排除路径'**
  String get excludePaths;

  /// No description provided for @pathsHint.
  ///
  /// In zh, this message translates to:
  /// **'每行一个路径或 glob，例如 service/**'**
  String get pathsHint;

  /// No description provided for @environmentValues.
  ///
  /// In zh, this message translates to:
  /// **'环境变量值'**
  String get environmentValues;

  /// No description provided for @environmentValuesHint.
  ///
  /// In zh, this message translates to:
  /// **'变量来自仓库中的部署清单。敏感值只写入 Pi 的本地数据库，不会返回到列表接口。'**
  String get environmentValuesHint;

  /// No description provided for @noEnvironmentVariables.
  ///
  /// In zh, this message translates to:
  /// **'部署清单没有声明环境变量。'**
  String get noEnvironmentVariables;

  /// No description provided for @secretValueHint.
  ///
  /// In zh, this message translates to:
  /// **'敏感值将隐藏显示'**
  String get secretValueHint;

  /// No description provided for @review.
  ///
  /// In zh, this message translates to:
  /// **'创建前确认'**
  String get review;

  /// No description provided for @invalidBasicInformation.
  ///
  /// In zh, this message translates to:
  /// **'请填写项目名称，并使用有效的小写项目 ID。'**
  String get invalidBasicInformation;

  /// No description provided for @invalidPollInterval.
  ///
  /// In zh, this message translates to:
  /// **'轮询间隔必须在 15 到 3600 秒之间。'**
  String get invalidPollInterval;

  /// No description provided for @completeGitInformation.
  ///
  /// In zh, this message translates to:
  /// **'请完整填写仓库、分支和部署清单路径。'**
  String get completeGitInformation;

  /// No description provided for @requiredEnvironmentMissing.
  ///
  /// In zh, this message translates to:
  /// **'请填写所有必填环境变量。'**
  String get requiredEnvironmentMissing;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
