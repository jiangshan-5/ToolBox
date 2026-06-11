import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import '../../../core/widgets/dynamic_effects.dart';
import '../../../core/widgets/dynamic_background.dart';
import '../provider/ai_provider.dart';
import '../provider/ai_config_provider.dart';
import '../../markdown_editor/provider/markdown_editor_provider.dart';
import '../../markdown_editor/view/markdown_editor_screen.dart';
import '../../../core/widgets/glass_card.dart';
import 'ai_config_screen.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final Duration speed;
  final VoidCallback? onComplete;

  const TypewriterText({
    super.key,
    required this.text,
    this.speed = const Duration(milliseconds: 15),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final showCursor = _currentIndex < widget.text.length;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: textColor,
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

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get textColor => isDark ? Colors.white : Colors.black87;
  Color get subTextColor => isDark ? Colors.white70 : Colors.black54;
  Color get faintTextColor => isDark ? Colors.white38 : Colors.black38;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final FocusNode _chatFocusNode;
  bool _hasPromptedConfig = false;

  // Preset Prompt suggestions
  final List<Map<String, String>> _presets = [
    {'emoji': '💡', 'label': '头脑风暴', 'prompt': '帮我想 3 个极具新意且适合移动端应用开发的创意点子。'},
    {'emoji': '🐍', 'label': '算法模型', 'prompt': '请用清晰通俗的语言解释二叉树中“左右旋”的运作原理。'},
    {'emoji': '📝', 'label': '商务公文', 'prompt': '帮我草拟一份向领导申请新增服务器高防节点的申请书邮件。'},
    {'emoji': '🎨', 'label': '文艺创作', 'prompt': '写一段富有诗意且关于“深夜工作台与跳动光标”的开场微散文。'},
  ];

  @override
  void initState() {
    super.initState();
    _chatFocusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
          final isControlOrCommandPressed =
              HardwareKeyboard.instance.isLogicalKeyPressed(
                LogicalKeyboardKey.controlLeft,
              ) ||
              HardwareKeyboard.instance.isLogicalKeyPressed(
                LogicalKeyboardKey.controlRight,
              ) ||
              HardwareKeyboard.instance.isLogicalKeyPressed(
                LogicalKeyboardKey.metaLeft,
              ) ||
              HardwareKeyboard.instance.isLogicalKeyPressed(
                LogicalKeyboardKey.metaRight,
              );
          if (isControlOrCommandPressed) {
            final chatState = ref.read(aiChatProvider);
            if (!chatState.isLoading) {
              _sendCurrentMessage();
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendPreset(String prompt) {
    if (!_checkAiModelConfigured(pendingText: prompt, isPreset: true)) return;
    ref.read(aiChatProvider.notifier).sendMessage(prompt);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);

    // Auto-scroll on new messages
    ref.listen(aiChatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length || next.isLoading) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: subTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI 智能多轮对话助理',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_rounded,
              color: subTextColor,
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
            icon: Icon(
              Icons.cleaning_services_rounded,
              color: subTextColor,
              size: 20,
            ),
            onPressed: () {
              ref.read(aiChatProvider.notifier).clearHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('对话上下文已安全清理'),
                  backgroundColor: isDark ? const Color(0xFF0F0C29) : Colors.purple.shade700,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const DynamicBackground(child: SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                // Top Info Tip Badge
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.purpleAccent.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.tips_and_updates_rounded,
                        color: Colors.purpleAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '💡 AI 引擎已经与云端大语言模型完美通联，支持完整的上下文连续多轮对话！',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chat Messages View Area
                Expanded(
                  child: chatState.messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: chatState.messages.length,
                          itemBuilder: (context, index) {
                            final msg = chatState.messages[index];
                            final isUser = msg.role == 'user';
                            final isLatestBot =
                                !isUser &&
                                index == chatState.messages.length - 1;
                            return _buildMessageBubble(
                              msg,
                              isUser,
                              isLatestBot,
                            );
                          },
                        ),
                ),

                // Active Loading Indicator
                if (chatState.isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.purpleAccent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI 助手正在精准计算中...',
                                style: TextStyle(
                                  color: faintTextColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Optional Preset Suggestions at bottom when history is empty
                if (chatState.messages.isEmpty && !chatState.isLoading)
                  _buildPresetsBar(),

                // Bottom Input Control bar
                _buildInputBar(context, chatState.isLoading),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _presets.length,
        itemBuilder: (context, index) {
          final preset = _presets[index];
          return GestureDetector(
            onTap: () => _sendPreset(preset['prompt']!),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.purpleAccent.withOpacity(0.18),
                ),
              ),
              child: Row(
                children: [
                  Text(preset['emoji']!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    preset['label']!,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 56,
                color: Colors.purpleAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Toolbox AI 智能助手',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '你可以问我任何问题，或者点选下方快捷场景，立即开启高频多轮对话！',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: faintTextColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isUser, bool isLatestBot) {
    final alignment = isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final color = isUser
        ? (isDark
            ? Colors.purpleAccent.withOpacity(0.2)
            : Colors.purple.shade50)
        : (isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.03));
    final border = isUser
        ? Border.all(
            color: isDark
                ? Colors.purpleAccent.withOpacity(0.25)
                : Colors.purple.shade200)
        : Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.purpleAccent, Colors.deepPurpleAccent],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.android_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isUser
                          ? const Radius.circular(18)
                          : Radius.zero,
                      bottomRight: isUser
                          ? Radius.zero
                          : const Radius.circular(18),
                    ),
                    border: border,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Render response
                      if (isLatestBot)
                        TypewriterText(text: msg.content)
                      else
                        ..._parseMessageContent(msg.content),

                      // Metrics Info Footer (Only for Bot message)
                      if (!isUser) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '⚡ ${msg.provider ?? '云端算力'} · ${msg.usageTokens ?? 0} Tokens',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.purpleAccent.withValues(alpha: 0.5)
                                    : Colors.purple.shade700.withValues(alpha: 0.6),
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
                                            '## AI 对话 ($timestamp)\n\n${msg.content}',
                                          );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            '📝 已存入 Markdown 笔记本',
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
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_note_rounded,
                                        color: isDark ? Colors.cyanAccent : Colors.cyan.shade800,
                                        size: 11,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '存入笔记',
                                        style: TextStyle(
                                          color: isDark ? Colors.cyanAccent : Colors.cyan.shade800,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Copy response
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(
                                      ClipboardData(text: msg.content),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('已成功复制到剪贴板'),
                                        backgroundColor: Color(0xFF0F0C29),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.copy_rounded,
                                        color: Colors.white38,
                                        size: 11,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '复制',
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 10,
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
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purpleAccent.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.purpleAccent.withOpacity(0.2),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: Colors.purpleAccent,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _parseMessageContent(String content) {
    final List<Widget> widgets = [];
    final RegExp exp = RegExp(r'```(?:[a-zA-Z]+)?\n([\s\S]*?)\n```');

    int lastIndex = 0;
    for (final Match match in exp.allMatches(content)) {
      // 1. Text before code block
      if (match.start > lastIndex) {
        final plainText = content.substring(lastIndex, match.start).trim();
        if (plainText.isNotEmpty) {
          widgets.add(
            Text(
              plainText,
              style: TextStyle(
                color: textColor,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          );
        }
      }

      // 2. Code Block
      final codeContent = match.group(1) ?? '';
      widgets.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CODE WORKSPACE',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: codeContent));
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('已复制相应代码段')));
                    },
                    child: const Row(
                      children: [
                        Icon(
                          Icons.copy_rounded,
                          color: Colors.purpleAccent,
                          size: 11,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '复制代码',
                          style: TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText(
                codeContent,
                style: const TextStyle(
                  color: Colors.lightGreenAccent,
                  fontFamily: 'monospace',
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
      lastIndex = match.end;
    }

    // 3. Text after code block
    if (lastIndex < content.length) {
      final remainingText = content.substring(lastIndex).trim();
      if (remainingText.isNotEmpty) {
        widgets.add(
          Text(
            remainingText,
            style: TextStyle(
              color: textColor,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        );
      }
    }

    if (widgets.isEmpty) {
      widgets.add(
        Text(
          content,
          style: TextStyle(
            color: textColor,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildInputBar(BuildContext context, bool isLoading) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 12),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFF0C091F) : Colors.white).withOpacity(0.5),
        border: Border(top: BorderSide(color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _chatFocusNode,
                      enabled: !isLoading,
                      maxLines: null,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        hintText: '请输入消息，与 AI 进行多轮对话...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white24 : Colors.black38,
                          fontSize: 13.5,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Colors.purpleAccent, Colors.deepPurpleAccent],
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: isLoading ? null : _sendCurrentMessage,
            ),
          ),
        ],
      ),
    );
  }

  bool _checkAiModelConfigured({String? pendingText, bool isPreset = false}) {
    final config = ref.read(aiConfigProvider);
    if ((config.provider == 'mock' || config.apiKey.trim().isEmpty) &&
        !_hasPromptedConfig) {
      _showConfigureModelDialog(pendingText: pendingText, isPreset: isPreset);
      return false;
    }
    return true;
  }

  void _showConfigureModelDialog({String? pendingText, bool isPreset = false}) {
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
                  Text(
                    '配置您的 AI 智能助理',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '目前尚未检测到云端 AI 模型配置。Toolbox AI 助手现已全面接入 FreeModel AI (极速 GPT-5.5)、SiliconFlow、DeepSeek 和 Gemini 等顶尖云端模型。\n\n'
                    '只需一分钟，填入您的 API Key，即可开启真实、极速、无限制的云端模型深度多轮对话！',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: subTextColor,
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
                            if (pendingText != null &&
                                pendingText.trim().isNotEmpty) {
                              ref
                                  .read(aiChatProvider.notifier)
                                  .sendMessage(pendingText);
                              if (!isPreset) {
                                _messageController.clear();
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: textColor.withOpacity(0.15),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            '暂不配置',
                            style: TextStyle(
                              color: subTextColor,
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

  void _sendCurrentMessage() {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    if (!_checkAiModelConfigured(pendingText: text, isPreset: false)) return;

    ref.read(aiChatProvider.notifier).sendMessage(text);
    _messageController.clear();
  }
}
