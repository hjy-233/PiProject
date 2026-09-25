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
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'MyBot'**
  String get appName;

  /// No description provided for @libraries.
  ///
  /// In zh, this message translates to:
  /// **'工作库'**
  String get libraries;

  /// No description provided for @newLibrary.
  ///
  /// In zh, this message translates to:
  /// **'新建工作库'**
  String get newLibrary;

  /// No description provided for @newConversation.
  ///
  /// In zh, this message translates to:
  /// **'新对话'**
  String get newConversation;

  /// No description provided for @noLibraries.
  ///
  /// In zh, this message translates to:
  /// **'还没有工作库'**
  String get noLibraries;

  /// No description provided for @noLibrariesHint.
  ///
  /// In zh, this message translates to:
  /// **'添加一个 Mac 工作目录，开始与 Codex 对话。'**
  String get noLibrariesHint;

  /// No description provided for @noConversation.
  ///
  /// In zh, this message translates to:
  /// **'选择或创建一个对话'**
  String get noConversation;

  /// No description provided for @noMessages.
  ///
  /// In zh, this message translates to:
  /// **'发送第一条消息'**
  String get noMessages;

  /// No description provided for @messageHint.
  ///
  /// In zh, this message translates to:
  /// **'给 Codex 一个任务…'**
  String get messageHint;

  /// No description provided for @send.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get send;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get create;

  /// No description provided for @libraryName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get libraryName;

  /// No description provided for @workspacePath.
  ///
  /// In zh, this message translates to:
  /// **'Mac 工作目录'**
  String get workspacePath;

  /// No description provided for @memoryMode.
  ///
  /// In zh, this message translates to:
  /// **'记忆模式'**
  String get memoryMode;

  /// No description provided for @codexDefault.
  ///
  /// In zh, this message translates to:
  /// **'Codex 默认'**
  String get codexDefault;

  /// No description provided for @libraryMemory.
  ///
  /// In zh, this message translates to:
  /// **'工作库记忆'**
  String get libraryMemory;

  /// No description provided for @noMemory.
  ///
  /// In zh, this message translates to:
  /// **'无工作库记忆'**
  String get noMemory;

  /// No description provided for @conversationTitle.
  ///
  /// In zh, this message translates to:
  /// **'对话标题'**
  String get conversationTitle;

  /// No description provided for @queued.
  ///
  /// In zh, this message translates to:
  /// **'已排队，等待 Mac Agent'**
  String get queued;

  /// No description provided for @offline.
  ///
  /// In zh, this message translates to:
  /// **'Mac Agent 离线'**
  String get offline;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @required.
  ///
  /// In zh, this message translates to:
  /// **'此项不能为空'**
  String get required;

  /// No description provided for @temporary.
  ///
  /// In zh, this message translates to:
  /// **'临时对话'**
  String get temporary;

  /// No description provided for @temporaryUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'临时对话将在 Mac Agent 接入后开放'**
  String get temporaryUnavailable;
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
