import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_deployer_console/api_client.dart';
import 'package:project_deployer_console/l10n/generated/app_localizations.dart';
import 'package:project_deployer_console/project_editor.dart';

void main() {
  testWidgets('missing manifest opens the guided manifest step', (
    tester,
  ) async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/v1/git/credentials') {
        return http.Response('{"credentials":[]}', 200);
      }
      if (request.url.path == '/api/v1/sources/git/inspect') {
        return http.Response(
          '{"branches":["main"],"commit":"0123456789012345678901234567890123456789",'
          '"manifestExists":false,"manifestValid":false,"manifest":null,"issues":[]}',
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ProjectEditor(api: ApiClient(client: client)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manifest'), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextField, 'Project name'),
      'Hello Service',
    );
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Git repository URL'),
      'https://github.com/example/hello.git',
    );
    await tester.tap(find.text('Test connection and inspect'));
    await tester.pumpAndSettle();

    expect(find.text('Manifest'), findsOneWidget);
    expect(find.text('Copy JSON'), findsOneWidget);
    expect(
      find.textContaining('The target branch has no manifest'),
      findsOneWidget,
    );
  });
}
