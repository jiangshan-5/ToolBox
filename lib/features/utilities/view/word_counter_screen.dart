import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/dashboard/provider/tools_provider.dart';
import '../../../core/providers/global_clipboard_provider.dart';
import '../../ai/view/ai_text_processor_screen.dart';
import '../../../core/widgets/pipeline_wrapper.dart';
import '../../../core/widgets/dynamic_effects.dart';

class WordCounterScreen extends ConsumerStatefulWidget {
  final String? initialText;
  const WordCounterScreen({super.key, this.initialText});

  @override
  ConsumerState<WordCounterScreen> createState() => _WordCounterScreenState();
}

class _WordCounterScreenState extends ConsumerState<WordCounterScreen> {
  final TextEditingController _controller = TextEditingController();
  int _charWithSpaces = 0;
  int _charNoSpaces = 0;
  int _chineseChars = 0;
  int _englishWords = 0;
  int _numbers = 0;
  int _lines = 0;

  Timer? _logDebounce;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_analyzeText);
    if (widget.initialText != null) {
      _controller.text = widget.initialText!;
    }
  }

  @override
  void dispose() {
    _logDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _analyzeText() {
    final text = _controller.text;
    if (text.isEmpty) {
      setState(() {
        _charWithSpaces = 0;
        _charNoSpaces = 0;
        _chineseChars = 0;
        _englishWords = 0;
        _numbers = 0;
        _lines = 0;
      });
      return;
    }

    setState(() {
      _charWithSpaces = text.length;
      _charNoSpaces = text.replaceAll(RegExp(r'\s+'), '').length;
      _chineseChars = RegExp(r'[\u4e00-\u9fa5]').allMatches(text).length;
      _englishWords = RegExp(r'\b[a-zA-Z]+\b').allMatches(text).length;
      _numbers = RegExp(r'[0-9]').allMatches(text).length;
      _lines = text.split('\n').length;
    });

    // Debounce telemetry logging to avoid spamming on each keystroke
    _logDebounce?.cancel();
    _logDebounce = Timer(const Duration(seconds: 2), () {
      if (_charWithSpaces > 0) {
        ref
            .read(toolsAnalyticsProvider)
            .logUsage(
              toolKey: 'word_counter',
              parameters: {
                'char_count': _charWithSpaces,
                'chinese_chars': _chineseChars,
                'english_words': _englishWords,
              },
              status: 'success',
              durationMs: 0,
            );
      }
    });
  }

  /// Send current text to AI Text Processor via globalClipboardProvider
  void _sendToAiProcessor() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先输入文本内容'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    // Publish text to global clipboard so AI Processor can read it
    ref.read(globalClipboardProvider.notifier).state = text;

    // Navigate directly to AI Text Processor
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiTextProcessorScreen(initialText: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color subTextColor = isDark ? Colors.white70 : Colors.black54;
    final Color faintTextColor = isDark ? Colors.white38 : Colors.black38;
    final Color borderDividerColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);
    final primaryColor = Theme.of(context).colorScheme.primary;

    final double readingTime = _charWithSpaces > 0
        ? (_charWithSpaces / 350).ceilToDouble()
        : 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '字数与字符统计器',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
      body: PipelineWrapper(
        toolKey: 'word_counter',
        controller: _controller,
        child: Stack(
          children: [
            // Theme Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF0C091F),
                          const Color(0xFF140F2D),
                          const Color(0xFF06050C),
                        ]
                      : [
                          primaryColor.withOpacity(0.06),
                          const Color(0xFFFAF9FF),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SafeArea(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // Text Input Area
                  Text(
                    '📝 输入分析文本',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.02)
                          : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: borderDividerColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TextField(
                          controller: _controller,
                          maxLines: 8,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13.5,
                          ),
                          decoration: InputDecoration(
                            hintText: '在此粘贴或输入需要分析的赛博文本...',
                            hintStyle: TextStyle(
                              color: isDark ? Colors.white30 : Colors.black38,
                              fontSize: 13.5,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '当前字数: $_charWithSpaces 字符',
                          style: TextStyle(
                            color: faintTextColor,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Word Count Grid
                  Text(
                    '📊 深度字数统计沙盒',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.25,
                    children: [
                      _buildStatCard('总字符数', '$_charWithSpaces', const Color(0xFF00FF87)),
                      _buildStatCard('无空格数', '$_charNoSpaces', const Color(0xFF60EFFF)),
                      _buildStatCard('汉字个数', '$_chineseChars', const Color(0xFFFF0844)),
                      _buildStatCard('英文单词', '$_englishWords', const Color(0xFFFAD961)),
                      _buildStatCard('数字个数', '$_numbers', const Color(0xFF7000FF)),
                      _buildStatCard('段落行数', '$_lines', const Color(0xFFFF13F0)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Action Tools
                  Text(
                    '⚡ 算子联动链路推荐',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _sendToAiProcessor,
                    child: HoverGlowCard(
                      glowColor: const Color(0xFFE200FF),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.015)
                              : Colors.black.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: borderDividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE200FF).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFFE200FF),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AI 高级写作引擎联动',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '将分析的数据一键流转至 AI 大模型进行专业级论文润色与精简。',
                                    style: TextStyle(
                                      color: subTextColor.withOpacity(0.6),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: faintTextColor,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Reading Estimate
                  HoverGlowCard(
                    glowColor: const Color(0xFF00FF87),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.015)
                            : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: borderDividerColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FF87).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Color(0xFF00FF87),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '阅读时间预估',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _charWithSpaces > 0
                                      ? '按照标准语速 350 字/分钟，预计约需 $readingTime 分钟读完。'
                                      : '输入文本后自动计算预计阅读时间。',
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color borderDividerColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.08);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.015)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderDividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black45,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: isDark ? color : HSLColor.fromColor(color).withLightness(0.35).toColor(),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
