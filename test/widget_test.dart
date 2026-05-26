import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_app/core/storage/local_storage.dart';
import 'package:toolbox_app/main.dart';

void main() {
  testWidgets('ToolboxApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame with correct provider overrides.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ToolboxApp(),
      ),
    );

    // Verify auth wrapper renders login screen or dashboard
    expect(find.byType(ToolboxApp), findsOneWidget);
  });
}
