import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/widgets/glass_card.dart';

class MarkdownEditorScreen extends StatefulWidget {
  const MarkdownEditorScreen({super.key});

  @override
  State<MarkdownEditorScreen> createState() => _MarkdownEditorScreenState();
}

class _MarkdownEditorScreenState extends State<MarkdownEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _editorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Inject friendly initial markdown template
    _editorController.text = '''# 欢迎使用极简 Markdown 编研站 🚀

这是一套专为移动端打造的极简 **Markdown 编辑与渲染容器**。

## 💡 功能亮点

1. **实时双栏对照**：自由切换“源码编辑”与“深度渲染”；
2. **快捷动作栏**：支持一键加粗、引用、代码块与链接插入；
3. **沉浸式暗黑风格**：完美融入极客工作台主题。

---

> “好记性不如烂笔头。用极简的排版，沉淀最具深度的思想。”

### 💻 代码块模拟展示
```javascript
const greet = (name) => {
  console.log(`Hello, \${name}!`);
};
greet("Toolbox Pro User");
```
''';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _editorController.dispose();
    super.dispose();
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
            border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.04))),
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
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: TextField(
              controller: _editorController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                color: Colors.white70,
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
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
              style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontStyle: FontStyle.italic),
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
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
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
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
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
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.purpleAccent, fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
