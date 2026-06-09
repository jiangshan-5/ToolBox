import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../provider/novel_provider.dart';
import 'widgets/novel_shelf_tab.dart';
import 'widgets/book_oasis_tab.dart';
import 'novel_search_screen.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/widgets/dynamic_background.dart';

class NovelWorkbenchScreen extends ConsumerStatefulWidget {
  const NovelWorkbenchScreen({super.key});

  @override
  ConsumerState<NovelWorkbenchScreen> createState() => _NovelWorkbenchScreenState();
}

class _NovelWorkbenchScreenState extends ConsumerState<NovelWorkbenchScreen> {
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    // Warm-start loading normal bookshelf
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(novelProvider.notifier).fetchBookshelf(false);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleLocalFileImport(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub', 'txt'],
      );
      
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final fileName = result.files.single.name;
        
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⏳ 正在解析并上传书籍 "$fileName"...'),
            backgroundColor: Colors.pinkAccent,
          ),
        );
        
        await ref.read(novelProvider.notifier).importBookFile(filePath, fileName, false);
        
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 书籍 "$fileName" 导入成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 导入失败: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.7)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_rounded, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              '智能净化阅读器',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: onSurface,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.upload_file_rounded, color: onSurface.withOpacity(0.7)),
            tooltip: '导入本地书籍 (TXT/EPUB)',
            onPressed: () => _handleLocalFileImport(context),
          ),
          IconButton(
            icon: Icon(Icons.search_rounded, color: onSurface.withOpacity(0.7)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NovelSearchScreen(inAbyss: false),
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
                _buildTabBar(),
                
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _activeTab == 0
                        ? NovelShelfTab(
                            key: const ValueKey('ShelfTab'),
                            inAbyss: false,
                            onOpenSearch: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NovelSearchScreen(inAbyss: false),
                                ),
                              );
                            },
                          )
                        : BookOasisTab(
                            key: const ValueKey('OasisTab'),
                            inAbyss: false,
                            onSearchTriggered: (query) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NovelSearchScreen(
                                    inAbyss: false,
                                    initialQuery: query,
                                  ),
                                ),
                              );
                            },
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

  Widget _buildTabBar() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: onSurface.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeTab == 0 ? primaryColor.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '📚 我的书架',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: _activeTab == 0 ? primaryColor : onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeTab == 1 ? primaryColor.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  '🔮 发现绿洲',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: _activeTab == 1 ? primaryColor : onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

