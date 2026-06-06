import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toolbox_app/core/providers/pipeline_provider.dart';
import 'package:toolbox_app/core/storage/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tool Pipeline System Integration Test', (WidgetTester tester) async {
    // Enforce high-definition physical viewport size to ensure scrollable list elements render
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    // Pump a navigator-enabled ProviderScope container
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Consumer(
                  builder: (context, ref, child) {
                    final session = ref.watch(pipelineSessionProvider);
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Active: ${session.isActive}'),
                        Text('Index: ${session.currentStepIndex}'),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(pipelineSessionProvider.notifier).startSession(
                              steps: ['word_counter', 'led_banner'],
                              initialInput: 'Pipeline Seed Data',
                              context: context,
                            );
                          },
                          child: const Text('Launch Pipeline'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    // 1. Verify initial pipeline is inactive
    expect(find.text('Active: false'), findsOneWidget);
    expect(find.text('Index: 0'), findsOneWidget);

    // 2. Launch the pipeline
    await tester.tap(find.text('Launch Pipeline'));
    await tester.pump(); // Allow microtasks to execute and schedule route push
    await tester.pump(const Duration(seconds: 1)); // Tick route and switcher animations

    // 3. Verify it has successfully navigated to Step 1 (Word Counter)
    expect(find.text('字数与字符统计器'), findsAtLeastNWidgets(1));

    // 4. Verify that the PipelineWrapper has overlaid the progress indicators
    expect(find.text('流水线'), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('👉 下一步: LED 手持弹幕'), findsOneWidget);

    // 5. Verify input data is auto-injected into Step 1's controller
    final wordCounterInput = find.byType(TextField);
    expect(wordCounterInput, findsOneWidget);
    final TextField textField = tester.widget<TextField>(wordCounterInput);
    expect(textField.controller?.text, 'Pipeline Seed Data');

    // 6. Click "Next" to transition to Step 2 (LED Banner)
    await tester.tap(find.text('下一步'));
    await tester.pump(); // Allow microtasks to run
    await tester.pump(const Duration(seconds: 1)); // Tick transition animations

    // 7. Verify we are now on Step 2 (LED Banner)
    expect(find.text('LED 手持弹幕'), findsAtLeastNWidgets(1));
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('🏁 终点站，点击完成'), findsOneWidget);

    // 8. Click "Complete" to finish the pipeline
    await tester.tap(find.text('完成'));
    await tester.pump(); // Allow microtasks to run
    await tester.pump(const Duration(seconds: 1)); // Tick transition animations

    // 9. Verify it successfully lands on the PipelineSummaryScreen showing success metrics
    expect(find.text('⚡ 智能流水线执行完毕 🏁'), findsOneWidget);
    expect(find.text('步骤 1: 字数与字符统计器'), findsOneWidget);
    expect(find.text('步骤 2: LED 手持弹幕'), findsOneWidget);
    expect(find.text('打包复制链数据'), findsOneWidget);
    expect(find.text('返回工作台'), findsOneWidget);
  });
}
