import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_app/core/storage/local_storage.dart';
import 'package:toolbox_app/features/dashboard/view/widgets/workbench_tab_view.dart';
import 'package:toolbox_app/features/dashboard/provider/tools_provider.dart';
import 'package:toolbox_app/core/providers/pipeline_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Workbench Tab View Edit Layout and Ordering Test', (WidgetTester tester) async {
    // Enforce high-definition physical viewport size to ensure grid/scrollable elements render
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Initialize Mock Shared Preferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // 2. Pump the WorkbenchTabView within a ProviderScope
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          categoriesProvider.overrideWith((ref) => []),
          savedWorkflowsProvider.overrideWith((ref) => []),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                height: 2000,
                child: WorkbenchTabView(
                  userEmail: 'test@example.com',
                  isWide: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 3. Verify that the initial static tools are rendered
    expect(find.text('随机选择生成器'), findsNWidgets(2)); // in recently used and in grid
    expect(find.text('健康 BMI 计算器'), findsOneWidget);
    expect(find.text('编辑布局'), findsOneWidget);

    // 4. Long press "健康 BMI 计算器" to enter edit mode
    final bmiCard = find.text('健康 BMI 计算器');
    expect(bmiCard, findsOneWidget);
    
    final gesture = await tester.startGesture(tester.getCenter(bmiCard));
    await tester.pump(const Duration(milliseconds: 600)); // Wait for long press timeout
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 100)); // Rebuild after state change

    // 5. Verify we are now in Edit Mode
    expect(find.text('⚙️ 正在编辑布局 (拖动排序/右上角删除)'), findsOneWidget);
    expect(find.text('保存完成'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsWidgets); // Badges should be visible

    // 6. Delete a tool: e.g. the first badge corresponding to "随机选择生成器"
    final deleteBadges = find.byIcon(Icons.close_rounded);
    expect(deleteBadges, findsWidgets);
    await tester.tap(deleteBadges.first);
    await tester.pump(const Duration(milliseconds: 100));

    // Exit edit mode to stop the animation and verify persistence by tapping background/empty space text
    await tester.tap(find.text('欢迎回来，test@example.com'), warnIfMissed: false);
    await tester.pumpAndSettle(); // Safe to pumpAndSettle now since animation stopped

    // Verify it is saved in SharedPreferences (should NOT contain 'randomizer')
    final keysAfterDelete = prefs.getStringList('my_tools_keys');
    expect(keysAfterDelete, isNotNull);
    expect(keysAfterDelete!.contains('randomizer'), isFalse);

    // 7. Test Add Tool Flow via "+" Card
    expect(find.text('添加工具'), findsOneWidget);
    await tester.tap(find.text('添加工具'));
    await tester.pumpAndSettle();

    // Verify the add dialog is showing the deleted tool
    expect(find.text('添加工具至主页'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Dialog), matching: find.text('随机选择生成器')),
      findsOneWidget,
    );

    // Tap the plus button to add it back
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.byIcon(Icons.add_circle_rounded)).first,
    );
    await tester.pumpAndSettle();

    // Verify it is back in active list
    final keysAfterAdd = prefs.getStringList('my_tools_keys');
    expect(keysAfterAdd, isNotNull);
    expect(keysAfterAdd!.contains('randomizer'), isTrue);

    // 8. Reorder items: long-press drag "健康 BMI 计算器" to "标准单位转换器"
    // Trigger edit mode again
    await tester.tap(find.text('编辑布局'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 100));

    final dragGesture = await tester.startGesture(
      tester.getCenter(find.descendant(of: find.byType(GridView), matching: find.text('健康 BMI 计算器'))),
    );
    await tester.pump(const Duration(milliseconds: 600)); // wait for long press
    await dragGesture.moveTo(
      tester.getCenter(find.descendant(of: find.byType(GridView), matching: find.text('标准单位转换器'))),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await dragGesture.up();
    await tester.pump(const Duration(milliseconds: 100));

    // Save and stop animation by tapping background/empty space text
    await tester.tap(find.text('欢迎回来，test@example.com'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Verify we exited edit mode
    expect(find.text('全部工具分类库'), findsOneWidget);
  });
}
