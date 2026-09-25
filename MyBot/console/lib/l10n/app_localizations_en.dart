// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MyBot';

  @override
  String get libraries => 'Libraries';

  @override
  String get newLibrary => 'New library';

  @override
  String get newConversation => 'New conversation';

  @override
  String get noLibraries => 'No libraries yet';

  @override
  String get noLibrariesHint =>
      'Add a Mac workspace to start working with Codex.';

  @override
  String get noConversation => 'Select or create a conversation';

  @override
  String get noMessages => 'Send the first message';

  @override
  String get messageHint => 'Give Codex a task…';

  @override
  String get send => 'Send';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get libraryName => 'Name';

  @override
  String get workspacePath => 'Mac workspace path';

  @override
  String get memoryMode => 'Memory mode';

  @override
  String get codexDefault => 'Codex default';

  @override
  String get libraryMemory => 'Library memory';

  @override
  String get noMemory => 'No library memory';

  @override
  String get conversationTitle => 'Conversation title';

  @override
  String get queued => 'Queued for the Mac Agent';

  @override
  String get offline => 'Mac Agent offline';

  @override
  String get retry => 'Retry';

  @override
  String get required => 'This field is required';

  @override
  String get temporary => 'Temporary chat';

  @override
  String get temporaryUnavailable =>
      'Temporary chat will be available after the Mac Agent is connected';
}
