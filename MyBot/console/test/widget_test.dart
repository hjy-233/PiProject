import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mybot_console/main.dart';
import 'package:mybot_console/src/api_client.dart';
import 'package:mybot_console/src/home_page.dart';

void main() {
  testWidgets('shows the empty library state', (tester) async {
    final api = ApiClient(
      client: MockClient((request) async => http.Response('[]', 200)),
      baseUri: Uri.parse('http://localhost'),
    );
    await tester.pumpWidget(MyBotApp(home: HomePage(apiClient: api)));
    await tester.pumpAndSettle();
    expect(find.text('No libraries yet'), findsOneWidget);
    expect(find.text('Mac Agent offline'), findsOneWidget);
  });
}
