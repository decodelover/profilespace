// This is a basic Flutter widget test for Tspace Portfolio.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package.

import 'package:flutter_test/flutter_test.dart';
import 'package:tspace_portfolio/core/di/service_locator.dart';
import 'package:tspace_portfolio/main.dart';

void main() {
  setUpAll(() async {
    await initServiceLocator();
  });

  testWidgets('TspaceApp renders without crashing', (
    WidgetTester tester,
  ) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const TspaceApp());

    // Verify the app bootstraps — the welcome screen should render.
    expect(find.text('Build Stunning\nPortfolios'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
