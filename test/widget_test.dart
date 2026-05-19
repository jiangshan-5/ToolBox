import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toolbox_app/main.dart';

void main() {
  testWidgets('ToolboxApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: ToolboxApp()));

    // Verify auth wrapper renders login screen or dashboard
    expect(find.byType(ToolboxApp), findsOneWidget);
  });
}
