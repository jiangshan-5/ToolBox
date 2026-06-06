import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../provider/novel_provider.dart';
import 'widgets/novel_shelf_tab.dart';
import 'widgets/book_oasis_tab.dart';
import 'novel_search_screen.dart';
import 'abyss_chamber_screen.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/widgets/dynamic_background.dart';

class NovelWorkbenchScreen extends ConsumerStatefulWidget {
  const NovelWorkbenchScreen({super.key});

  @override
  ConsumerState<NovelWorkbenchScreen> createState() => _NovelWorkbenchScreenState();
}

class _NovelWorkbenchScreenState extends ConsumerState<NovelWorkbenchScreen> {
  int _activeTab = 0;
  
  // Timing parameters for the secret 5s gesture trigger
  Timer? _gestureTimer;
  int _longPressSeconds = 0;
  bool _isTriggeringAbyss = false;

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
    _gestureTimer?.cancel();
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

  void _onGestureStart() {
    _longPressSeconds = 0;
    _gestureTimer?.cancel();
    _gestureTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _longPressSeconds++;
      if (_longPressSeconds >= 5) {
        timer.cancel();
        _triggerAbyssChamberAccess();
      } else {
        // Micro feedback sound or vibration tick
        HapticFeedback.lightImpact();
      }
    });
  }

  void _onGestureEnd() {
    _gestureTimer?.cancel();
  }

  void _triggerAbyssChamberAccess() async {
    setState(() {
      _isTriggeringAbyss = true;
    });
    
    // Intense physical vibration sequence
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 200));
    HapticFeedback.heavyImpact();

    if (mounted) {
      setState(() {
        _isTriggeringAbyss = false;
      });
      // Redirect to Abyss Chamber Screen
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => const AbyssChamberScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation.drive(CurveTween(curve: Curves.easeInOutCubic)),
              child: ScaleTransition(
                scale: animation.drive(Tween<double>(begin: 0.9, end: 1.0)),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  void _showImportSourcesDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) {
        return _ImportSourcesDialog(ref: ref);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Force a dark theme for the entire novel workbench section to ensure high readability
    // of all text elements and create a gorgeous immersive reading environment
    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.pinkAccent,
        brightness: Brightness.dark,
        surface: const Color(0xFF0F0C29), // deep midnight purple-blue space background
      ),
      useMaterial3: true,
    );

    return Theme(
      data: darkTheme,
      child: Builder(
        builder: (context) {
          final localTheme = Theme.of(context);
          final primaryColor = localTheme.colorScheme.primary;

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
              // Hidden 5s long-press gesture detector on the Title Logo area
              title: GestureDetector(
                onLongPressStart: (_) => _onGestureStart(),
                onLongPressEnd: (_) => _onGestureEnd(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_stories_rounded, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      '智能净化阅读器',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.cloud_download_rounded, color: Colors.white70),
                  tooltip: '导入书源',
                  onPressed: () => _showImportSourcesDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file_rounded, color: Colors.white70),
                  tooltip: '导入本地书籍 (TXT/EPUB)',
                  onPressed: () => _handleLocalFileImport(context),
                ),
                IconButton(
                  icon: const Icon(Icons.search_rounded, color: Colors.white70),
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

                // Portal particle transition cover overlay
                if (_isTriggeringAbyss)
                  Positioned.fill(
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: Colors.purple.withOpacity(0.3),
                          alignment: Alignment.center,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 16),
                              Text(
                                '🌌 正在撕裂空间穿梭至深渊...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeTab == 0 ? Colors.pinkAccent.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '📚 我的书架',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                  color: _activeTab == 1 ? Colors.pinkAccent.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '🔮 发现绿洲',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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

class _ImportSourcesDialog extends StatefulWidget {
  final WidgetRef ref;
  const _ImportSourcesDialog({required this.ref});

  @override
  State<_ImportSourcesDialog> createState() => _ImportSourcesDialogState();
}

class _ImportSourcesDialogState extends State<_ImportSourcesDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _jsonController = TextEditingController();
  String? _selectedFileName;
  String? _selectedFileContent;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _pickSourceFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = io.File(path);
        final content = await file.readAsString();
        setState(() {
          _selectedFileName = result.files.single.name;
          _selectedFileContent = content;
          _errorMessage = null;
          _successMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "选择文件失败: $e";
      });
    }
  }

  Future<void> _handleImport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });
    HapticFeedback.lightImpact();

    try {
      Map<String, dynamic> result;
      if (_tabController.index == 0) {
        final url = _urlController.text.trim();
        if (url.isEmpty) {
          throw Exception("请输入书源导入 URL");
        }
        result = await widget.ref.read(novelProvider.notifier).importBookSources(url: url);
      } else if (_tabController.index == 1) {
        if (_selectedFileContent == null || _selectedFileContent!.trim().isEmpty) {
          throw Exception("请先选择本地书源文件");
        }
        
        final jsonText = _selectedFileContent!.trim();
        late final dynamic parsed;
        try {
          parsed = jsonDecode(jsonText);
        } catch (e) {
          throw Exception("文件 JSON 格式错误: $e");
        }

        final List<dynamic> jsonData;
        if (parsed is List) {
          jsonData = parsed;
        } else if (parsed is Map) {
          jsonData = [parsed];
        } else {
          throw Exception("不支持的书源 JSON 结构 (必须是数组或对象)");
        }

        result = await widget.ref.read(novelProvider.notifier).importBookSources(jsonData: jsonData);
      } else {
        final jsonText = _jsonController.text.trim();
        if (jsonText.isEmpty) {
          throw Exception("请粘贴书源 JSON 内容");
        }
        
        // Try parsing JSON locally to validate first
        late final dynamic parsed;
        try {
          parsed = jsonDecode(jsonText);
        } catch (e) {
          throw Exception("JSON 格式错误，请检查: $e");
        }

        final List<dynamic> jsonData;
        if (parsed is List) {
          jsonData = parsed;
        } else if (parsed is Map) {
          jsonData = [parsed];
        } else {
          throw Exception("不支持的书源 JSON 结构 (必须是数组或对象)");
        }

        result = await widget.ref.read(novelProvider.notifier).importBookSources(jsonData: jsonData);
      }

      // Success
      final imported = result['imported_count'] ?? 0;
      final updated = result['updated_count'] ?? 0;
      
      setState(() {
        _successMessage = "🎉 导入成功！\n新增: $imported 个书源\n更新: $updated 个书源";
        _isLoading = false;
      });
      HapticFeedback.heavyImpact();
    } catch (e) {
      String errStr = e.toString();
      if (errStr.startsWith("Exception: ")) {
        errStr = errStr.substring("Exception: ".length);
      }
      setState(() {
        _errorMessage = errStr;
        _isLoading = false;
      });
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF140D33).withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.pinkAccent.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.pinkAccent.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Row(
                    children: [
                      const Icon(Icons.cloud_download_rounded, color: Colors.pinkAccent, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        '导入外部书源',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Segmented TabBar
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.pinkAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.pinkAccent.withOpacity(0.3)),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: const [
                        Tab(text: '🌐 网络链接'),
                        Tab(text: '📁 本地文件'),
                        Tab(text: '📝 粘贴文本'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tab View Content
                  Flexible(
                    child: SizedBox(
                      height: 180,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: URL
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '书源 URL 链接 (支持 Base64 / JSON)',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _urlController,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'https://example.com/sources.json',
                                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.02),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.pinkAccent),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Tab 2: Local File
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '选择本地书源文件 (.json 或 .txt)',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: InkWell(
                                  onTap: _pickSourceFile,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.02),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _selectedFileName != null
                                            ? Colors.pinkAccent.withOpacity(0.5)
                                            : Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _selectedFileName != null
                                              ? Icons.insert_drive_file_rounded
                                              : Icons.upload_file_rounded,
                                          color: _selectedFileName != null ? Colors.pinkAccent : Colors.white54,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _selectedFileName ?? '点击选择本地书源文件',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _selectedFileName != null ? Colors.white : Colors.white54,
                                            fontSize: 13,
                                            fontWeight: _selectedFileName != null ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (_selectedFileName != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '大小: ${((_selectedFileContent?.length ?? 0) / 1024).toStringAsFixed(1)} KB',
                                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Tab 3: Raw JSON text
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '书源 JSON 内容 (数组或单个对象格式)',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: TextField(
                                  controller: _jsonController,
                                  maxLines: null,
                                  expands: true,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
                                  decoration: InputDecoration(
                                    hintText: '[{"bookSourceName": "xx", "bookSourceUrl": "xx", ...}]',
                                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 11),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.02),
                                    contentPadding: const EdgeInsets.all(12),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.pinkAccent),
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

                  // Messages (Error / Success)
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_successMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleImport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.pinkAccent.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('立即导入'),
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
}
