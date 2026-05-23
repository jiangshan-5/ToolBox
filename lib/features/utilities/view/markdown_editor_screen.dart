import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_clipboard_provider.dart';

import '../provider/markdown_editor_provider.dart';

class MarkdownEditorScreen extends ConsumerStatefulWidget {

  const MarkdownEditorScreen({super.key});

  @override

  ConsumerState<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();

}

class _MarkdownEditorScreenState extends ConsumerState<MarkdownEditorScreen> with SingleTickerProviderStateMixin {

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get textColor => isDark ? Colors.white : Colors.black87;

  Color get subTextColor => isDark ? Colors.white70 : Colors.black54;

  Color get faintTextColor => isDark ? Colors.white38 : Colors.black38;

  Color get borderDividerColor => isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);

  late TabController _tabController;

  final TextEditingController _editorController = TextEditingController();

  String _initialText = '';

  @override

  void initState() {

    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    

    final baseText = ref.read(markdownEditorCacheProvider);

    final globalClipboardText = ref.read(globalClipboardProvider);

    String text = baseText;

    

    if (globalClipboardText != null && globalClipboardText.trim().isNotEmpty) {

      text = baseText.isEmpty ? globalClipboardText : '$baseText\n\n$globalClipboardText';

      WidgetsBinding.instance.addPostFrameCallback((_) {

        ref.read(markdownEditorCacheProvider.notifier).updateText(text);

        ref.read(globalClipboardProvider.notifier).state = null;

      });

    }

    _editorController.text = text;

    _initialText = text;

    _editorController.addListener(_onTextChanged);

  }

  void _onTextChanged() {

    ref.read(markdownEditorCacheProvider.notifier).updateText(_editorController.text);

  }

  @override

  void dispose() {

    _editorController.removeListener(_onTextChanged);

    _tabController.dispose();

    _editorController.dispose();

    super.dispose();

  }

  Future<bool> _showExitConfirmationDialog() async {

    final result = await showDialog<bool>(

      context: context,

      builder: (context) => AlertDialog(

        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF140F2D) : Theme.of(context).colorScheme.surfaceContainer,

        shape: RoundedRectangleBorder(

          borderRadius: BorderRadius.circular(20),

          side: BorderSide(color: Colors.purpleAccent.withOpacity(0.3), width: 1.5),

        ),

        title: Text(

          '放弃未保存的更改？',

          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),

        ),

        content: Text(

          '您已对文档进行了修改，返回后本地缓存仍会保留，但确定退出吗？',

          style: TextStyle(color: subTextColor, fontSize: 14),

        ),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(context, false),

            child: const Text('继续编辑', style: TextStyle(color: Colors.purpleAccent)),

          ),

          ElevatedButton(

            style: ElevatedButton.styleFrom(

              backgroundColor: Colors.redAccent.withOpacity(0.8),

              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

            ),

            onPressed: () => Navigator.pop(context, true),

            child: const Text('确定退出', style: TextStyle(color: Colors.white)),

          ),

        ],

      ),

    );

    return result ?? false;

  }

  Future<bool> _handlePop() async {

    if (_editorController.text == _initialText) {

      return true;

    }

    return await _showExitConfirmationDialog();

  }

  void _insertMarkdown(String prefix, String suffix) {

    final text = _editorController.text;

    final selection = _editorController.selection;

    

    int start = selection.start;

    int end = selection.end;

    if (start < 0 || end < 0) {

      start = text.length;

      end = text.length;

    }

    final selectedText = text.substring(start, end);

    final replacement = '$prefix$selectedText$suffix';

    final newText = text.replaceRange(start, end, replacement);

    _editorController.value = TextEditingValue(

      text: newText,

      selection: TextSelection.collapsed(offset: start + prefix.length + selectedText.length),

    );

  }

  @override

  Widget build(BuildContext context) {

    ref.listen<String>(markdownEditorCacheProvider, (previous, next) {

      if (_editorController.text != next) {

        _editorController.text = next;

      }

    });

    return PopScope(

      canPop: false,

      onPopInvoked: (didPop) async {

        if (didPop) return;

        final shouldPop = await _handlePop();

        if (shouldPop && context.mounted) {

          Navigator.of(context).pop();

        }

      },

      child: Scaffold(

        extendBodyBehindAppBar: true,

        appBar: AppBar(

          backgroundColor: Colors.transparent,

          elevation: 0,

          leading: IconButton(

            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),

            onPressed: () async {

              final shouldPop = await _handlePop();

              if (shouldPop && context.mounted) {

                Navigator.pop(context);

              }

            },

          ),

          title: const Text(

            '极简 Markdown 工作站',

            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),

          ),

          bottom: TabBar(

            controller: _tabController,

            indicatorColor: Colors.purpleAccent,

            labelColor: Colors.purpleAccent,

            unselectedLabelColor: Colors.white38,

            tabs: const [

              Tab(text: '✏️ 源码编辑模式'),

              Tab(text: '👁️ 渲染预览模式'),

            ],

          ),

        ),

        body: Stack(

          children: [

            // Background

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

              child: TabBarView(

                controller: _tabController,

                children: [

                  _buildEditorTab(),

                  _buildPreviewTab(),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }

  Widget _buildEditorTab() {

    return Column(

      children: [

        // Helper Toolbar

        Container(

          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

          decoration: BoxDecoration(

            color: Colors.white.withOpacity(0.01),

            border: Border(bottom: BorderSide(color: isDark ? isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04) : Colors.black.withOpacity(0.04))),

          ),

          child: Row(

            mainAxisAlignment: MainAxisAlignment.spaceAround,

            children: [

              _buildToolbarButton('H1', () => _insertMarkdown('# ', '')),

              _buildToolbarButton('H2', () => _insertMarkdown('## ', '')),

              _buildToolbarButton('粗体', () => _insertMarkdown('**', '**')),

              _buildToolbarButton('斜体', () => _insertMarkdown('*', '*')),

              _buildToolbarButton('引用', () => _insertMarkdown('> ', '')),

              _buildToolbarButton('代码', () => _insertMarkdown('```\n', '\n```')),

              _buildToolbarButton('链接', () => _insertMarkdown('[', '](url)')),

            ],

          ),

        ),

        // Text Area Workspace

        Expanded(

          child: Container(

            margin: const EdgeInsets.all(16),

            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(

              color: isDark ? isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.03) : Colors.black.withOpacity(0.03),

              borderRadius: BorderRadius.circular(20),

              border: Border.all(color: borderDividerColor),

            ),

            child: TextField(

              controller: _editorController,

              maxLines: null,

              keyboardType: TextInputType.multiline,

              style: TextStyle(

                color: subTextColor,

                fontSize: 13.5,

                height: 1.5,

                fontFamily: 'monospace',

              ),

              decoration: const InputDecoration(

                border: InputBorder.none,

                hintText: '在此键入您的 Markdown 格式内容...',

                hintStyle: TextStyle(color: Colors.white24, fontSize: 13.5),

              ),

            ),

          ),

        ),

      ],

    );

  }

  Widget _buildPreviewTab() {

    final text = _editorController.text;

    final lines = text.split('\n');

    return ListView.builder(

      physics: const BouncingScrollPhysics(),

      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

      itemCount: lines.length,

      itemBuilder: (context, index) {

        final line = lines[index].trim();

        if (line.isEmpty) {

          return const SizedBox(height: 10);

        }

        // 1. Headers (H1, H2, H3)

        if (line.startsWith('# ')) {

          return Padding(

            padding: const EdgeInsets.only(top: 14.0, bottom: 8.0),

            child: Text(

              line.substring(2),

              style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),

            ),

          );

        }

        if (line.startsWith('## ')) {

          return Padding(

            padding: const EdgeInsets.only(top: 12.0, bottom: 6.0),

            child: Text(

              line.substring(3),

              style: const TextStyle(color: Colors.purpleAccent, fontSize: 17, fontWeight: FontWeight.bold),

            ),

          );

        }

        if (line.startsWith('### ')) {

          return Padding(

            padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),

            child: Text(

              line.substring(4),

              style: const TextStyle(color: Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.bold),

            ),

          );

        }

        // 2. Blockquotes

        if (line.startsWith('> ')) {

          return Container(

            margin: const EdgeInsets.symmetric(vertical: 8),

            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

            decoration: BoxDecoration(

              color: Colors.purpleAccent.withOpacity(0.04),

              border: const Border(left: BorderSide(color: Colors.purpleAccent, width: 3)),

              borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),

            ),

            child: Text(

              line.substring(2),

              style: TextStyle(color: subTextColor, fontSize: 12.5, fontStyle: FontStyle.italic),

            ),

          );

        }

        // 3. Bullet points

        if (line.startsWith('* ') || line.startsWith('- ') || RegExp(r'^\d+\.\s').hasMatch(line)) {

          final content = line.startsWith('* ') || line.startsWith('- ')

              ? line.substring(2)

              : line.replaceFirst(RegExp(r'^\d+\.\s'), '');

          return Padding(

            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),

            child: Row(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                const Text('• ', style: TextStyle(color: Colors.purpleAccent, fontSize: 16)),

                Expanded(

                  child: Text(

                    content,

                    style: TextStyle(color: subTextColor, fontSize: 13, height: 1.4),

                  ),

                ),

              ],

            ),

          );

        }

        // 4. Horizontal Rule

        if (line == '---' || line == '***') {

          return const Padding(

            padding: EdgeInsets.symmetric(vertical: 14.0),

            child: Divider(color: Colors.white10, height: 1),

          );

        }

        // 5. Code block boundaries (simple visual grouping)

        if (line.startsWith('```')) {

          return const SizedBox(height: 4);

        }

        // Default Paragraph

        return Padding(

          padding: const EdgeInsets.symmetric(vertical: 4.0),

          child: Text(

            line,

            style: TextStyle(color: subTextColor, fontSize: 13, height: 1.5),

          ),

        );

      },

    );

  }

  Widget _buildToolbarButton(String label, VoidCallback onTap) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),

        decoration: BoxDecoration(

          color: isDark ? isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.03) : Colors.black.withOpacity(0.03),

          borderRadius: BorderRadius.circular(8),

          border: Border.all(color: isDark ? isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06) : Colors.black.withOpacity(0.06)),

        ),

        child: Text(

          label,

          style: const TextStyle(color: Colors.purpleAccent, fontSize: 11.5, fontWeight: FontWeight.bold),

        ),

      ),

    );

  }

}

