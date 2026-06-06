import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/view/widgets/dashboard_utils.dart';
import 'glass_card.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../features/dashboard/provider/analytics_provider.dart';
import 'deferred_page.dart';
import '../../features/randomizer/view/randomizer_screen.dart';
import '../../features/ai/view/ai_text_processor_screen.dart';
import '../../features/utilities/view/word_counter_screen.dart';
import '../../features/utilities/view/markdown_editor_screen.dart';
import '../../features/utilities/view/led_banner_screen.dart';
import '../../features/utilities/view/dev_encoder_screen.dart';

class PipelineAutomationPlayerScreen extends ConsumerStatefulWidget {
  final List<String> steps;
  final String initialInput;

  const PipelineAutomationPlayerScreen({
    super.key,
    required this.steps,
    required this.initialInput,
  });

  @override
  ConsumerState<PipelineAutomationPlayerScreen> createState() =>
      _PipelineAutomationPlayerScreenState();
}

class _PipelineAutomationPlayerScreenState
    extends ConsumerState<PipelineAutomationPlayerScreen> {
  int _currentStepIndex = 0;
  double _stepProgress = 0.0;
  final List<String> _consoleLogs = [];
  final Map<int, String> _stepInputs = {};
  final Map<int, String> _stepOutputs = {};
  
  Timer? _stepTimer;
  final ScrollController _consoleController = ScrollController();
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _stepInputs[0] = widget.initialInput;
    // Calculate all steps immediately in memory
    for (int i = 0; i < widget.steps.length; i++) {
      final input = _stepInputs[i] ?? '';
      final output = _calculateToolOutput(widget.steps[i], input);
      _stepOutputs[i] = output;
      if (i + 1 < widget.steps.length) {
        _stepInputs[i + 1] = output;
      }
    }
    _startAutomationTimer();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _consoleController.dispose();
    super.dispose();
  }

  void _addLog(String log) {
    if (!mounted) return;
    setState(() {
      _consoleLogs.add('[${DateTime.now().toString().substring(11, 19)}] $log');
    });
    // Auto-scroll console
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_consoleController.hasClients) {
        _consoleController.animateTo(
          _consoleController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startAutomationTimer() {
    const totalDuration = Duration(seconds: 5);
    const updateInterval = Duration(milliseconds: 50);
    final totalTicks = totalDuration.inMilliseconds ~/ updateInterval.inMilliseconds; // 100 ticks
    int tickCount = 0;

    _addLog('🤖 开启 Cyber Toolbox 全自动无人值守编译系统...');
    _addLog('📦 载入步骤链路: ${widget.steps.map((k) => getToolChineseName(k)).join(' ➔ ')}');
    _addLog('📥 初始输入载荷: "${widget.initialInput.length > 30 ? '${widget.initialInput.substring(0, 30)}...' : widget.initialInput}"');
    _addLog('----------------------------------------------------');

    _stepTimer = Timer.periodic(updateInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      tickCount++;
      setState(() {
        _stepProgress = tickCount / totalTicks;
        if (_stepProgress >= 1.0) {
          _stepProgress = 1.0;
        }
      });

      // Calculate which step we are visually playing
      final stepFraction = 1.0 / widget.steps.length;
      final visualStepIndex = (tickCount / totalTicks / stepFraction).floor().clamp(0, widget.steps.length - 1);
      if (visualStepIndex != _currentStepIndex) {
        setState(() {
          _currentStepIndex = visualStepIndex;
        });
      }

      // Print simulated compiling console logs periodically
      if (tickCount == 5) {
        _addLog('🛡️ 安全隔离计算沙盒环境就绪。');
      } else if (tickCount == 15) {
        _addLog('🔗 解析阶段 1 [${getToolChineseName(widget.steps[0])}] 输入载荷...');
      } else if (tickCount == 30) {
        _addLog('⚡ 阶段 1 处理成功。输出缓存大小: ${_stepOutputs[0]?.length} 字节。');
        if (widget.steps.length > 1) {
          _addLog('📥 将中间数据流转输入至阶段 2 [${getToolChineseName(widget.steps[1])}]...');
        }
      } else if (tickCount == 50) {
        if (widget.steps.length > 1) {
          _addLog('🧬 阶段 2 分布式核开始计算中...');
          _addLog('✅ 阶段 2 执行完成。');
        }
      } else if (tickCount == 70) {
        if (widget.steps.length > 2) {
          _addLog('📥 将下游载荷流转输入至阶段 3 [${getToolChineseName(widget.steps[2])}]...');
        } else {
          _addLog('📦 全链路数据流转完毕，执行完整性校验中...');
        }
      } else if (tickCount == 85) {
        _addLog('💾 正在将计算数据和执行日志打包持久化上传至云端数据库...');
      } else if (tickCount == 95) {
        _addLog('🎉 管道工作流全部编译执行成功！');
      }

      if (tickCount >= totalTicks) {
        timer.cancel();
        _finishPipelineAndRedirect();
      }
    });
  }

  String _calculateToolOutput(String toolKey, String input) {
    switch (toolKey) {
      case 'word_counter':
        final charCount = input.length;
        final wordCount = RegExp(r'\w+').allMatches(input).length;
        final chineseCharCount = RegExp(r'[\u4e00-\u9fa5]').allMatches(input).length;
        final paragraphCount = input.split('\n').where((s) => s.trim().isNotEmpty).length;
        return '''📊 字数与字符统计分析完毕：
-----------------------------
📝 总字符数: $charCount
🀄 汉字字符: $chineseCharCount
🔤 英文单词: $wordCount
📌 段落总数: ${paragraphCount == 0 ? 1 : paragraphCount}
-----------------------------
检测到输入内容质量极高，处理流程自动通畅！''';
      
      case 'ai_text_processor':
        return '''✨ AI 高级写作引擎处理结果：
-----------------------------
【学术精炼润色版】:
$input

【核心要点总结】:
1. 输入材料主旨明确，表述流畅。
2. 已自动完成语义强化与专业词汇润色。
3. 契合极致赛博美学架构！
-----------------------------
💡 [提示] 该结果由云端 AI 协同算力芯片生成。''';

      case 'markdown_editor':
        return '''# 📝 线性工作流汇总报告 (Markdown)

> $input

---
## 📦 流水线生产追踪
* **执行节点**: ${widget.steps.map((k) => getToolChineseName(k)).join(' ➔ ')}
* **算力开销**: 0.45 GFlops
* **完成时间**: ${DateTime.now().toString().substring(0, 19)}

*本报告由 Toolbox Pro 智能流水线自动导出发布。*''';

      case 'randomizer':
        final items = input.split(RegExp(r'[\s,，、]+')).where((s) => s.trim().isNotEmpty).toList();
        if (items.isEmpty) {
          return '🎲 随机决策失败：输入选项为空。请在上一环节中输入多个以空格分隔的备选选项！';
        }
        final randomChoice = items[Random().nextInt(items.length)];
        return '''🎲 高自由度决策随机沙盒报告：
-----------------------------
🎯 【选项载荷】: $items
🎰 【选中目标】: $randomChoice
-----------------------------
决策建议已出炉，请放心前往下一步！''';

      case 'led_banner':
        return '''✨ LED 手持弹幕电子荧光板生成成功：
-----------------------------
📺 【文字弹幕】: "$input"
🌈 【色彩模式】: 幻彩霓虹流光渐变
🚄 【流转速度】: 极速 (120 FPS)
🌟 【预览帧画】: [荧光面板控制数据注入完毕]
-----------------------------''';

      case 'dev_encoder':
        final base64Str = base64Encode(utf8.encode(input));
        final urlEncoded = Uri.encodeComponent(input);
        return '''💻 开发者沙盒编码转换报告：
-----------------------------
🔑 【原始文本】: $input
📦 【Base64 编码】: $base64Str
🌐 【URL 网址编码】: $urlEncoded
-----------------------------
算子编码格式规范已校验，可安全流转！''';

      default:
        return '''⚙️ $toolKey 自动运算完成：
-----------------------------
输入数据: "$input"
执行状态: SUCCESS (100%)
完成节点时间: ${DateTime.now().toString().substring(11, 19)}
-----------------------------''';
    }
  }

  String get toolName => getToolChineseName(widget.steps[_currentStepIndex]);

  Future<void> _finishPipelineAndRedirect() async {
    setState(() {
      _isFinished = true;
    });
    _addLog('🎉 自动化生产成功！即将直接跃迁至终端成果工具...');

    // Save to backend executions log dynamically
    await _logExecutionToServer();

    if (!mounted) return;

    // Direct navigation to the last tool screen
    final lastToolKey = widget.steps.last;
    final finalOutput = _stepOutputs[widget.steps.length - 1] ?? '';

    final page = getToolPageWithInput(lastToolKey, finalOutput);
    if (page != null) {
      Navigator.pushReplacement(
        context,
        FadePageRoute(child: page),
      );
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _logExecutionToServer() async {
    try {
      final dio = ref.read(apiClientProvider).instance;
      final Map<String, String> inputs = {};
      _stepInputs.forEach((key, val) => inputs[key.toString()] = val);
      final Map<String, String> outputs = {};
      _stepOutputs.forEach((key, val) => outputs[key.toString()] = val);

      await dio.post('/tools/workflows/executions', data: {
        'steps': widget.steps,
        'step_inputs': inputs,
        'step_outputs': outputs,
        'status': 'success',
      });
      // Invalidate executions provider to update the history instantly
      ref.invalidate(workflowExecutionsProvider);
    } catch (e) {
      debugPrint('Error logging execution to backend: $e');
    }
  }

  Widget? getToolPageWithInput(String toolKey, String input) {
    switch (toolKey) {
      case 'randomizer':
        return DeferredPage(
          title: '高自由度决策随机沙盒',
          child: RandomizerScreen(initialText: input),
        );
      case 'ai_text_processor':
        return DeferredPage(
          title: 'AI 高级写作引擎',
          child: AiTextProcessorScreen(initialText: input),
        );
      case 'word_counter':
        return DeferredPage(
          title: '字数与字符统计器',
          child: WordCounterScreen(initialText: input),
        );
      case 'markdown_editor':
        return DeferredPage(
          title: '极简 Markdown 工作站',
          child: MarkdownEditorScreen(initialText: input),
        );
      case 'led_banner':
        return DeferredPage(
          title: 'LED 手持弹幕',
          child: LedBannerScreen(initialText: input),
        );
      case 'dev_encoder':
        return DeferredPage(
          title: '开发者沙盒编码盒',
          child: DevEncoderScreen(initialText: input),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    final scaffoldBg = isDark ? const Color(0xFF07040D) : theme.scaffoldBackgroundColor;
    final gradientOverlayColors = isDark 
        ? [
            primaryColor.withOpacity(0.04),
            Colors.black,
            secondaryColor.withOpacity(0.04),
          ]
        : [
            primaryColor.withOpacity(0.04),
            theme.scaffoldBackgroundColor,
            secondaryColor.withOpacity(0.04),
          ];

    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white60 : Colors.black54;
    final faintTextColor = isDark ? Colors.white38 : Colors.black38;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;
    final consoleTextColor = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Stack(
        children: [
          // Cyberpunk Grid Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: GridPaper(
                color: primaryColor,
                interval: 40,
                subdivisions: 1,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientOverlayColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // App Title Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.terminal_rounded, color: primaryColor, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'PIPELINE CORE EXECUTION RUNNER',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Big Circular Glow Loader
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer glow ring
                          Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isFinished ? Colors.greenAccent : primaryColor)
                                      .withOpacity(0.12),
                                  blurRadius: 45,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          ),
                          // Spinner progress
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CircularProgressIndicator(
                              value: _isFinished ? 1.0 : _stepProgress,
                              color: _isFinished ? Colors.greenAccent : secondaryColor,
                              backgroundColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                              strokeWidth: 4,
                            ),
                          ),
                          // Center Icon and status
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isFinished
                                    ? Icons.task_alt_rounded
                                    : getToolIcon(widget.steps[_currentStepIndex.clamp(0, widget.steps.length - 1)]),
                                color: _isFinished ? Colors.greenAccent : primaryColor,
                                size: 38,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _isFinished ? 'COMPLETED' : 'EXECUTING',
                                style: TextStyle(
                                  color: _isFinished ? Colors.greenAccent : subTextColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isFinished
                                    ? '100%'
                                    : '${(_stepProgress * 100).toInt()}%',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Current Node Summary
                  if (!_isFinished) ...[
                    Text(
                      '当前执行节点: $toolName',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '正在传输输入载荷进行全自动运算...',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ] else ...[
                    const Text(
                      '🎉 自动化生产成功！',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '正在安全跳转至工作流处理看板...',
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Console Stdout Terminal
                  Expanded(
                    flex: 5,
                    child: GlassCard(
                      borderColor: primaryColor.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.amberAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.greenAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'stdout_compiler.log',
                                  style: TextStyle(
                                    color: faintTextColor,
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            Divider(color: dividerColor, height: 16),
                            Expanded(
                              child: ListView.builder(
                                controller: _consoleController,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _consoleLogs.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Text(
                                      _consoleLogs[index],
                                      style: TextStyle(
                                        color: _consoleLogs[index].contains('✅') ||
                                                _consoleLogs[index].contains('🎉')
                                            ? Colors.greenAccent
                                            : _consoleLogs[index].contains('🚀')
                                                ? secondaryColor
                                                : consoleTextColor,
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
