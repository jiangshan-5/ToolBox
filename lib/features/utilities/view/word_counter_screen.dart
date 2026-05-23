import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../features/dashboard/provider/tools_provider.dart';
import '../../../core/providers/global_clipboard_provider.dart';
import '../../ai/view/ai_text_processor_screen.dart';

class WordCounterScreen extends ConsumerStatefulWidget {
  const WordCounterScreen({super.key});

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
    final double readingTime = _charWithSpaces > 0
        ? (_charWithSpaces / 350).ceilToDouble()
        : 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '字数与字符统计器',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Theme Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0C091F),
                  Color(0xFF140F2D),
                  Color(0xFF06050C),
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
                const Text(
                  '📝 输入分析文本',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        controller: _controller,
                        maxLines: 8,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: '在此贴入需要统计分析的文本...',
                          hintStyle: TextStyle(
                            color: Colors.white24,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _controller.clear(),
                            child: const Text(
                              '清空文本',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '共 $_charWithSpaces 字符',
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ✨ Send to AI Button (cross-tool linkage)
                if (_charWithSpaces > 0)
                  GestureDetector(
                    onTap: _sendToAiProcessor,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B2FBE), Color(0xFF5C4AE8)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purpleAccent.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '✨ 发送至 AI 写作引擎改写',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Comprehensive Stats Panel
                const Text(
                  '📊 文本多维指标统计',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.count(
                      crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _buildStatCard(
                          '总字符数 (带空格)',
                          _charWithSpaces.toString(),
                          Colors.purpleAccent,
                        ),
                        _buildStatCard(
                          '净字符数 (无空格)',
                          _charNoSpaces.toString(),
                          Colors.cyanAccent,
                        ),
                        _buildStatCard(
                          '中文字数',
                          _chineseChars.toString(),
                          Colors.orangeAccent,
                        ),
                        _buildStatCard(
                          '英文单词数',
                          _englishWords.toString(),
                          Colors.lightGreenAccent,
                        ),
                        _buildStatCard(
                          '数字个数',
                          _numbers.toString(),
                          Colors.amberAccent,
                        ),
                        _buildStatCard(
                          '段落行数',
                          _lines.toString(),
                          Colors.pinkAccent,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Reading time card
                GlassCard(
                  borderColor: Colors.purpleAccent.withValues(alpha: 0.15),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.timer_outlined,
                            color: Colors.purpleAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '⏱️ 预计阅读所需时间',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _charWithSpaces > 0
                                    ? '按照标准语速 350 字/分钟，预计约需 $readingTime 分钟读完。'
                                    : '输入文本后自动计算预计阅读时间。',
                                style: const TextStyle(
                                  color: Colors.white54,
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
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.015),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10.5),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
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
