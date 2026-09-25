// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'MyBot';

  @override
  String get libraries => '工作库';

  @override
  String get newLibrary => '新建工作库';

  @override
  String get newConversation => '新对话';

  @override
  String get noLibraries => '还没有工作库';

  @override
  String get noLibrariesHint => '添加一个 Mac 工作目录，开始与 Codex 对话。';

  @override
  String get noConversation => '选择或创建一个对话';

  @override
  String get noMessages => '发送第一条消息';

  @override
  String get messageHint => '给 Codex 一个任务…';

  @override
  String get send => '发送';

  @override
  String get cancel => '取消';

  @override
  String get create => '创建';

  @override
  String get libraryName => '名称';

  @override
  String get workspacePath => 'Mac 工作目录';

  @override
  String get memoryMode => '记忆模式';

  @override
  String get codexDefault => 'Codex 默认';

  @override
  String get libraryMemory => '工作库记忆';

  @override
  String get noMemory => '无工作库记忆';

  @override
  String get conversationTitle => '对话标题';

  @override
  String get queued => '已排队，等待 Mac Agent';

  @override
  String get offline => 'Mac Agent 离线';

  @override
  String get retry => '重试';

  @override
  String get required => '此项不能为空';

  @override
  String get temporary => '临时对话';

  @override
  String get temporaryUnavailable => '临时对话将在 Mac Agent 接入后开放';
}
