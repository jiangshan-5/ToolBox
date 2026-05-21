import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import '../provider/ai_provider.dart';
import '../../utilities/provider/markdown_editor_provider.dart';
import '../../utilities/view/markdown_editor_screen.dart';
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

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Preset Prompt suggestions
  final List<Map<String, String>> _presets = [
    {
      'emoji': '💡',
      'label': '头脑风暴',
      'prompt': '帮我想 3 个极具新意且适合移动端应用开发的创意点子。',
    },
    {
      'emoji': '🐍',
      'label': '算法模型',
      'prompt': '请用清晰通俗的语言解释二叉树中“左右旋”的运作原理。',
    },
    {
      'emoji': '📝',
      'label': '商务公文',
      'prompt': '帮我草拟一份向领导申请新增服务器高防节点的申请书邮件。',
    },
    {
      'emoji': '🎨',
      'label': '文艺创作',
      'prompt': '写一段富有诗意且关于“深夜工作台与跳动光标”的开场微散文。',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI 智能多轮对话助理',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Colors.white70, size: 20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AiConfigScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white70, size: 20),
            onPressed: () {
              ref.read(aiChatProvider.notifier).clearHistory();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('对话上下文已安全清理'),
                  backgroundColor: Color(0xFF0F0C29),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient matching Toolbox standard
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0C091F), Color(0xFF140F2D), Color(0xFF06050C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top Info Tip Badge
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.15)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.tips_and_updates_rounded, color: Colors.purpleAccent, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '💡 AI 引擎已经与云端大语言模型完美通联，支持完整的上下文连续多轮对话！',
                          style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          physics: const BouncingScrollPhysics(),
                          itemCount: chatState.messages.length,
                          itemBuilder: (context, index) {
                            final msg = chatState.messages[index];
                            final isUser = msg.role == 'user';
                            final isLatestBot = !isUser && index == chatState.messages.length - 1;
                            return _buildMessageBubble(msg, isUser, isLatestBot);
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.purpleAccent,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'AI 助手正在精准计算中...',
                                style: TextStyle(color: Colors.white38, fontSize: 11),
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
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.18)),
              ),
              child: Row(
                children: [
                  Text(preset['emoji']!, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    preset['label']!,
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.bold),
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
            const Text(
              'Toolbox AI 智能助手',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              '你可以问我任何问题，或者点选下方快捷场景，立即开启高频多轮对话！',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.white38, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message msg, bool isUser, bool isLatestBot) {
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isUser ? Colors.purpleAccent.withOpacity(0.2) : Colors.white.withOpacity(0.03);
    final border = isUser
        ? Border.all(color: Colors.purpleAccent.withOpacity(0.25))
        : Border.all(color: Colors.white.withOpacity(0.06));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [Colors.purpleAccent, Colors.deepPurpleAccent]),
                  ),
                  child: const Center(
                    child: Icon(Icons.android_rounded, color: Colors.white, size: 16),
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
                      bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
                      bottomRight: isUser ? Radius.zero : const Radius.circular(18),
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
                                color: Colors.purpleAccent.withValues(alpha: 0.5),
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
                                      final timestamp = DateTime.now().toString().substring(0, 16);
                                      ref.read(markdownEditorCacheProvider.notifier).appendText(
                                        '## AI 对话 ($timestamp)\n\n${msg.content}'
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('📝 已存入 Markdown 笔记本'),
                                          backgroundColor: const Color(0xFF1E1B3A),
                                          action: SnackBarAction(
                                            label: '去看看',
                                            textColor: Colors.purpleAccent,
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (_) => const MarkdownEditorScreen()),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    } catch (_) {}
                                  },
                                  child: const Row(
                                    children: [
                                      Icon(Icons.edit_note_rounded, color: Colors.cyanAccent, size: 11),
                                      SizedBox(width: 4),
                                      Text('存入笔记', style: TextStyle(color: Colors.cyanAccent, fontSize: 10)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Copy response
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: msg.content));
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
                                      Icon(Icons.copy_rounded, color: Colors.white38, size: 11),
                                      SizedBox(width: 4),
                                      Text('复制', style: TextStyle(color: Colors.white38, fontSize: 10)),
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
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
                  ),
                  child: const Center(
                    child: Icon(Icons.person_rounded, color: Colors.purpleAccent, size: 16),
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
          widgets.add(Text(
            plainText,
            style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.5),
          ));
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
                  const Text('CODE WORKSPACE', style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: codeContent));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制相应代码段')),
                      );
                    },
                    child: const Row(
                      children: [
                        Icon(Icons.copy_rounded, color: Colors.purpleAccent, size: 11),
                        SizedBox(width: 4),
                        Text('复制代码', style: TextStyle(color: Colors.purpleAccent, fontSize: 10)),
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
        widgets.add(Text(
          remainingText,
          style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.5),
        ));
      }
    }
    
    if (widgets.isEmpty) {
      widgets.add(Text(
        content,
        style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.5),
      ));
    }
    
    return widgets;
  }

  Widget _buildInputBar(BuildContext context, bool isLoading) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0C091F).withOpacity(0.5),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.04))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !isLoading,
                      maxLines: null,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: '请输入消息，与 AI 进行多轮对话...',
                        hintStyle: TextStyle(color: Colors.white24, fontSize: 13.5),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) {
                        if (!isLoading) {
                          _sendCurrentMessage();
                        }
                      },
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

  void _sendCurrentMessage() {
    final text = _messageController.text;
    if (text.trim().isEmpty) return;

    ref.read(aiChatProvider.notifier).sendMessage(text);
    _messageController.clear();
  }
}
