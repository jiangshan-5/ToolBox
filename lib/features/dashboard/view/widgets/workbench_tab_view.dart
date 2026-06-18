import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_storage.dart';
import '../../provider/tools_provider.dart';
import 'dashboard_utils.dart';
import 'workbench/workbench_header.dart';
import 'workbench/workbench_pipeline_section.dart';
import 'workbench/workbench_recently_used.dart';
import 'workbench/workbench_tool_grid.dart';

class WorkbenchTabView extends ConsumerStatefulWidget {
  final String userEmail;
  final bool isWide;

  const WorkbenchTabView({
    super.key,
    required this.userEmail,
    required this.isWide,
  });

  @override
  ConsumerState<WorkbenchTabView> createState() => _WorkbenchTabViewState();
}

class _WorkbenchTabViewState extends ConsumerState<WorkbenchTabView>
    with TickerProviderStateMixin {
  List<String> _recentlyUsed = ['randomizer', 'converter'];

  static const List<String> _masterToolKeys = [
    'randomizer',
    'converter',
    'bmi_calculator',
    'word_counter',
    'password_generator',
    'world_clock',
    'white_noise',
    'markdown_editor',
    'ai_chat',
    'ai_text_processor',
    'led_banner',
    'dev_encoder',
    'daily_board',
    'novel_reader',
  ];

  List<String> _myToolsKeys = [];
  bool _isEditingTools = false;
  late AnimationController _wiggleController;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _loadRecentlyUsed();
    _loadMyTools();
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    super.dispose();
  }

  void _loadMyTools() {
    try {
      final storage = ref.read(localStorageServiceProvider);
      final savedList = storage.getStringList('my_tools_keys');
      if (savedList != null && savedList.isNotEmpty) {
        setState(() {
          _myToolsKeys = savedList;
        });
      } else {
        setState(() {
          _myToolsKeys = List.from(_masterToolKeys);
        });
      }
    } catch (_) {
      setState(() {
        _myToolsKeys = List.from(_masterToolKeys);
      });
    }
  }

  Future<void> _saveMyTools(List<String> list) async {
    try {
      final storage = ref.read(localStorageServiceProvider);
      await storage.setStringList('my_tools_keys', list);
    } catch (_) {}
  }

  void _loadRecentlyUsed() {
    try {
      final storage = ref.read(localStorageServiceProvider);
      final savedList = storage.getStringList('recently_used');
      if (savedList != null && savedList.isNotEmpty) {
        setState(() {
          _recentlyUsed = savedList;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveRecentlyUsed(List<String> list) async {
    try {
      final storage = ref.read(localStorageServiceProvider);
      await storage.setStringList('recently_used', list);
    } catch (_) {}
  }

  void _onDynamicToolClicked(String toolKey, String title) {
    final page = getToolPage(toolKey);
    if (page != null) {
      setState(() {
        _recentlyUsed.remove(toolKey);
        _recentlyUsed.insert(0, toolKey);
        if (_recentlyUsed.length > 4) {
          _recentlyUsed = _recentlyUsed.sublist(0, 4);
        }
      });
      _saveRecentlyUsed(_recentlyUsed);
      Navigator.push(context, FadePageRoute(child: page));
    } else {
      showComingSoonDialog(context, title);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final categoriesState = ref.watch(categoriesProvider);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_isEditingTools) {
          setState(() {
            _saveMyTools(_myToolsKeys);
            _wiggleController.stop();
            _wiggleController.value = 0.0;
            _isEditingTools = false;
          });
        }
      },
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WorkbenchHeader(
              email: widget.userEmail,
              primaryColor: primaryColor,
              secondaryColor: theme.colorScheme.secondary,
            ),
            ConnectionIndicator(state: categoriesState),
            const WorkbenchPipelineSection(),
            const SizedBox(height: 12),
            WorkbenchRecentlyUsed(
              recentlyUsed: _recentlyUsed,
              primaryColor: primaryColor,
              onToolClicked: _onDynamicToolClicked,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Icon(Icons.grid_view_rounded, color: primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isEditingTools ? '⚙️ 正在编辑布局 (拖动排序/右上角删除)' : '全部工具分类库',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (_isEditingTools) {
                          _saveMyTools(_myToolsKeys);
                          _wiggleController.stop();
                          _wiggleController.value = 0.0;
                        } else {
                          _wiggleController.repeat(reverse: true);
                        }
                        _isEditingTools = !_isEditingTools;
                      });
                    },
                    icon: Icon(
                      _isEditingTools
                          ? Icons.check_circle_outline_rounded
                          : Icons.edit_note_rounded,
                      size: 16,
                      color: Colors.pinkAccent,
                    ),
                    label: Text(
                      _isEditingTools ? '保存完成' : '编辑布局',
                      style: const TextStyle(
                        color: Colors.pinkAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            WorkbenchToolGrid(
              myToolsKeys: _myToolsKeys,
              isEditingTools: _isEditingTools,
              wiggleController: _wiggleController,
              isWide: widget.isWide,
              onToolClicked: _onDynamicToolClicked,
              onToolsReordered: (updatedKeys) {
                setState(() {
                  _myToolsKeys = updatedKeys;
                  _saveMyTools(_myToolsKeys);
                });
              },
              onToolRemoved: (toolKey) {
                setState(() {
                  _myToolsKeys.remove(toolKey);
                  _saveMyTools(_myToolsKeys);
                });
              },
              onToolAdded: (toolKey) {
                setState(() {
                  _myToolsKeys.add(toolKey);
                  _saveMyTools(_myToolsKeys);
                });
              },
              onEditModeTriggered: () {
                setState(() {
                  _isEditingTools = true;
                  _wiggleController.repeat(reverse: true);
                });
              },
            ),
            const SizedBox(height: 112),
          ],
        ),
      ),
    );
  }
}
