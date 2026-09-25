import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_deployer_console/main.dart';

void main() {
  testWidgets('shows loading state while the API request is pending', (
    tester,
  ) async {
    await tester.pumpWidget(const ProjectDeployerApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
