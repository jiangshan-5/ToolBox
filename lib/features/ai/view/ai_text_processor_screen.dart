import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import '../provider/ai_provider.dart';
import '../provider/ai_config_provider.dart';
import '../../../core/providers/global_clipboard_provider.dart';
import '../../utilities/provider/markdown_editor_provider.dart';
import '../../utilities/view/markdown_editor_screen.dart';
import '../../../core/widgets/glass_card.dart';
import 'ai_config_screen.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final Duration speed;
  final VoidCallback? onComplete;

  const TypewriterText({
    super.key,
    required this.text,
    this.speed = const Duration(milliseconds: 10),
    this.onComplete,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  Timer? _timer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startTyping();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _timer?.cancel();
    _currentIndex = 0;
    _displayedText = '';

    if (widget.text.isEmpty) return;

    _timer = Timer.periodic(widget.speed, (timer) {
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        _timer?.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showCursor = _currentIndex < widget.text.length;
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13.5,
          height: 1.5,
        ),
        children: [
          TextSpan(text: _displayedText),
          if (showCursor)
            const TextSpan(
              text: ' ▋',
              style: TextStyle(
                color: Colors.purpleAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class AiTextProcessorScreen extends ConsumerStatefulWidget {
  final String? initialText;

  const AiTextProcessorScreen({super.key, this.initialText});

  @override
  ConsumerState<AiTextProcessorScreen> createState() =>
      _AiTextProcessorScreenState();
}

class _AiTextProcessorScreenState extends ConsumerState<AiTextProcessorScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _hasPromptedConfig = false;
  String _selectedAction = 'polish'; // Actions: polish, translate, summarize
  String _targetLanguage = 'en'; // Defaults to English for translation
  int _charCount = 0;

  // Presets text suggestions to quickly onboarding users
  final List<Map<String, String>> _templates = [
    {
      'title': '🌟 极速润色模板',
      'text':
          'We want to make our toolbox app beautiful. Today we finished the routing and completed many features.',
    },
    {
      'title': '🏢 商业汇报润色',
      'text': '我们在今天对工具箱完成了所有模块 of 升级与重构，当前性能非常平稳，期待下周交付演示。',
    },
  ];

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': '英语 (English)'},
    {'code': 'ja', 'name': '日语 (Japanese)'},
    {'code': 'ko', 'name': '韩语 (Korean)'},
    {'code': 'fr', 'name': '法语 (French)'},
    {'code': 'es', 'name': '西班牙语 (Spanish)'},
    {'code': 'de', 'name': '德语 (German)'},
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill text if passed from another tool (e.g. Word Counter)
    if (widget.initialText != null && widget.initialText!.trim().isNotEmpty) {
      _textController.text = widget.initialText!;
    } else {
      final globalClipboardText = ref.read(globalClipboardProvider);
      if (globalClipboardText != null &&
          globalClipboardText.trim().isNotEmpty) {
        _textController.text = globalClipboardText;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(globalClipboardProvider.notifier).state = null;
        });
      }
    }
    _textController.addListener(() {
      setState(() {
        _charCount = _textController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool _checkAiModelConfigured() {
    final config = ref.read(aiConfigProvider);
    if ((config.provider == 'mock' || config.apiKey.trim().isEmpty) &&
        !_hasPromptedConfig) {
      _showConfigureModelDialog();
      return false;
    }
    return true;
  }

  void _showConfigureModelDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: GlassCard(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.purpleAccent.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.settings_suggest_rounded,
                      color: Colors.purpleAccent,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '配置您的 AI 智能助理',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '目前尚未检测到云端 AI 模型配置。Toolbox AI 助手现已全面接入 FreeModel AI (极速 GPT-5.5)、SiliconFlow、DeepSeek 和 Gemini 等顶尖云端模型。\n\n'
                    '只需一分钟，填入您的 API Key，即可开启真实、极速、无限制的云端模型深度创作！',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _hasPromptedConfig = true;
                            });
                            Navigator.pop(context);
                            _triggerProcessing();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.15),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            '暂不配置',
                            style: TextStyle(
                              color: Colors.white60,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.purpleAccent,
                                Colors.deepPurpleAccent,
                              ],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AiConfigScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              '去配置',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _triggerProcessing() {
    final text = _textController.text;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入需要处理的原始文本'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (!_checkAiModelConfigured()) return;

    ref
        .read(aiTextProcessorProvider.notifier)
        .processText(
          text: text,
          action: _selectedAction,
          targetLanguage: _selectedAction == 'translate'
              ? _targetLanguage
              : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final processorState = ref.watch(aiTextProcessorProvider);

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
          'AI 高级写作引擎',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings_rounded,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AiConfigScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
              size: 20,
            ),
            onPressed: () {
              _textController.clear();
              ref.read(aiTextProcessorProvider.notifier).clearResult();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Theme Background Gradient
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
                // 1. Text input area
                const Text(
                  '📝 待处理文本输入箱',
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
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        controller: _textController,
                        maxLines: 5,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: '在此贴入您希望翻译、润色或提炼摘要的任何文本段落...',
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
                          // Preset Templates selection
                          Row(
                            children: _templates.map((temp) {
                              return GestureDetector(
                                onTap: () {
                                  _textController.text = temp['text']!;
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.08),
                                    ),
                                  ),
                                  child: Text(
                                    temp['title']!,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 9.5,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          Text(
                            '$_charCount 个字符',
                            style: const TextStyle(
                              color: Colors.white30,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Action Choice Buttons
                const Text(
                  '✨ 智能选择运算指令',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildActionChip(
                      'polish',
                      Icons.auto_awesome_rounded,
                      '高级润色',
                    ),
                    const SizedBox(width: 8),
                    _buildActionChip(
                      'translate',
                      Icons.translate_rounded,
                      '多语翻译',
                    ),
                    const SizedBox(width: 8),
                    _buildActionChip(
                      'summarize',
                      Icons.summarize_rounded,
                      '提炼摘要',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Conditional Target Language Selection (Only when action is translate)
                if (_selectedAction == 'translate') ...[
                  const Text(
                    '🌏 翻译目标语言',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _targetLanguage,
                        dropdownColor: const Color(0xFF0F0C29),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.purpleAccent,
                        ),
                        items: _languages.map((lang) {
                          return DropdownMenuItem<String>(
                            value: lang['code'],
                            child: Text(lang['name']!),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _targetLanguage = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 4. Processing Submit trigger
                GestureDetector(
                  onTap: processorState.isLoading ? null : _triggerProcessing,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: processorState.isLoading
                            ? [
                                Colors.grey.withOpacity(0.2),
                                Colors.grey.withOpacity(0.2),
                              ]
                            : [Colors.purpleAccent, Colors.deepPurpleAccent],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (!processorState.isLoading)
                          BoxShadow(
                            color: Colors.purpleAccent.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Center(
                      child: processorState.isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'AI 大脑处理中...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.rocket_launch_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '立即唤起 AI 引擎',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Result Display Area
                const Text(
                  '💡 AI 提纯润色视窗',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (processorState.error != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      '❌ 运算错误: ${processorState.error}',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  )
                else if (processorState.result != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progressive Rollout typewriter
                        TypewriterText(text: processorState.result!),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '⚡ AI 写作节点驱动',
                              style: TextStyle(
                                color: Colors.purpleAccent.withValues(
                                  alpha: 0.5,
                                ),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                // Save to Markdown notes (cross-tool linkage)
                                GestureDetector(
                                  onTap: () {
                                    try {
                                      final timestamp = DateTime.now()
                                          .toString()
                                          .substring(0, 16);
                                      ref
                                          .read(
                                            markdownEditorCacheProvider
                                                .notifier,
                                          )
                                          .appendText(
                                            '## AI 改写结果 ($timestamp)\n\n${processorState.result!}',
                                          );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            '📝 已追加至 Markdown 笔记本',
                                          ),
                                          backgroundColor: const Color(
                                            0xFF1E1B3A,
                                          ),
                                          action: SnackBarAction(
                                            label: '去看看',
                                            textColor: Colors.purpleAccent,
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const MarkdownEditorScreen(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    } catch (_) {}
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.edit_note_rounded,
                                        color: Colors.cyanAccent,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '存入笔记',
                                        style: TextStyle(
                                          color: Colors.cyanAccent,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Copy result
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: processorState.result!,
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('已复制处理后的结果'),
                                        backgroundColor: Color(0xFF0F0C29),
                                      ),
                                    );
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.copy_all_rounded,
                                        color: Colors.purpleAccent,
                                        size: 14,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '复制结果',
                                        style: TextStyle(
                                          color: Colors.purpleAccent,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.01),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: const Center(
                      child: Text(
                        '等待运算输入...',
                        style: TextStyle(color: Colors.white24, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(String action, IconData icon, String label) {
    final isSelected = _selectedAction == action;
    final color = isSelected ? Colors.purpleAccent : Colors.white38;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAction = action;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.purpleAccent.withOpacity(0.12)
                : Colors.white.withOpacity(0.01),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? Colors.purpleAccent.withOpacity(0.4)
                  : Colors.white.withOpacity(0.05),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
