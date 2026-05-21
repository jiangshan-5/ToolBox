import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_storage.dart';

const String _markdownCacheKey = 'markdown_editor_cache';
const String _defaultMarkdownText = '''# 欢迎使用极简 Markdown 编研站 🚀

这是一套专为移动端打造 of 极简 **Markdown 编辑与渲染容器**。

## 💡 功能亮点

1. **实时双栏对照**：自由切换“源码编辑”与“深度渲染”；
2. **快捷动作栏**：支持一键加粗、引用、代码块与链接插入；
3. **沉浸式暗黑风格**：完美融入极客工作台主题。

---

> “好记性不如烂笔头。用极简的排版，沉淀最具深度的思想。”

### 💻 代码块模拟展示
```javascript
const greet = (name) => {
  console.log(`\${name}!`);
};
greet("Toolbox Pro User");
```
''';

class MarkdownEditorCacheNotifier extends StateNotifier<String> {
  final LocalStorageService _storage;

  MarkdownEditorCacheNotifier(this._storage) : super('') {
    _loadCache();
  }

  void _loadCache() {
    final cached = _storage.getString(_markdownCacheKey);
    state = cached ?? _defaultMarkdownText;
  }

  Future<void> updateText(String text) async {
    if (state == text) return;
    state = text;
    await _storage.setString(_markdownCacheKey, text);
  }

  Future<void> appendText(String text) async {
    final appended = state.isEmpty ? text : '$state\n\n$text';
    state = appended;
    await _storage.setString(_markdownCacheKey, appended);
  }
}

final markdownEditorCacheProvider = StateNotifierProvider<MarkdownEditorCacheNotifier, String>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return MarkdownEditorCacheNotifier(storage);
});
