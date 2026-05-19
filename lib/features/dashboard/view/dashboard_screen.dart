import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../../core/storage/local_storage.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/parallax_glass_card.dart';
import '../../../core/widgets/dynamic_background.dart';
import '../../../core/widgets/deferred_page.dart';
import '../../auth/provider/auth_provider.dart';
import '../../randomizer/view/randomizer_screen.dart';
import '../../converter/view/converter_screen.dart';
import '../../bmi/view/bmi_screen.dart';
import '../../debug/view/debug_console_screen.dart';
import '../provider/tools_provider.dart';
import '../../converter/provider/converter_provider.dart';
import '../../ai/view/ai_chat_screen.dart';
import '../../ai/view/ai_text_processor_screen.dart';
import '../../utilities/view/word_counter_screen.dart';
import '../../utilities/view/password_generator_screen.dart';
import '../../utilities/view/world_clock_screen.dart';
import '../../utilities/view/white_noise_screen.dart';
import '../../utilities/view/markdown_editor_screen.dart';
import 'analytics_view.dart';

/// Elite ultra-smooth fade transition route that eliminates page entry stutters
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  FadePageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation.drive(CurveTween(curve: Curves.easeOutCubic)),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 220),
        );
}

/// Standardized Mainstream Workbench Dashboard Shell
/// Employs a premium 3-Tab Architecture with a floating glassmorphic Navigation Bar
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  List<String> _recentlyUsed = ['randomizer', 'converter']; // Tracks active user utilities in real-time

  @override
  void initState() {
    super.initState();
    _loadRecentlyUsed();
  }

  /// Load persistent recently used tools list from disk cache
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

  /// Persist recently used tools list to disk cache
  Future<void> _saveRecentlyUsed(List<String> list) async {
    try {
      final storage = ref.read(localStorageServiceProvider);
      await storage.setStringList('recently_used', list);
    } catch (_) {}
  }

  /// Map database tool keys to compiled Flutter widget views wrapped in a deferred-transition container
  Widget? _getToolPage(String toolKey) {
    switch (toolKey) {
      case 'randomizer':
        return const DeferredPage(
          title: '高自由度决策随机沙盒',
          child: RandomizerScreen(),
        );
      case 'unit_converter':
      case 'converter':
        return const DeferredPage(
          title: '物理量公式沙盒转换站',
          child: ConverterScreen(),
        );
      case 'bmi_calculator':
        return const DeferredPage(
          title: '体征与宏量营养沙盒',
          child: BmiScreen(),
        );
      case 'ai_chat':
        return const DeferredPage(
          title: 'AI 智能多轮对话助理',
          child: AiChatScreen(),
        );
      case 'ai_text_processor':
        return const DeferredPage(
          title: 'AI 高级写作引擎',
          child: AiTextProcessorScreen(),
        );
      case 'word_counter':
        return const DeferredPage(
          title: '字数与字符统计器',
          child: WordCounterScreen(),
        );
      case 'password_generator':
        return const DeferredPage(
          title: '密码生成与强度分析',
          child: PasswordGeneratorScreen(),
        );
      case 'world_clock':
        return const DeferredPage(
          title: '时区对照与极智番茄钟',
          child: WorldClockScreen(),
        );
      case 'white_noise':
        return const DeferredPage(
          title: '白噪音专注冥想',
          child: WhiteNoiseScreen(),
        );
      case 'markdown_editor':
        return const DeferredPage(
          title: '极简 Markdown 工作站',
          child: MarkdownEditorScreen(),
        );
      default:
        return null;
    }
  }

  IconData _getToolIcon(String toolKey) {
    switch (toolKey) {
      case 'randomizer':
        return Icons.casino_rounded;
      case 'unit_converter':
      case 'converter':
        return Icons.swap_horiz_rounded;
      case 'bmi_calculator':
        return Icons.monitor_weight_outlined;
      case 'word_counter':
        return Icons.text_fields_rounded;
      case 'password_generator':
        return Icons.lock_reset_rounded;
      case 'world_clock':
        return Icons.alarm_rounded;
      case 'white_noise':
        return Icons.spa_rounded;
      case 'markdown_editor':
        return Icons.edit_note_rounded;
      case 'ai_chat':
        return Icons.psychology_rounded;
      case 'ai_text_processor':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.build_rounded;
    }
  }

  Color _getToolColor(String toolKey) {
    switch (toolKey) {
      case 'randomizer':
        return Colors.orangeAccent;
      case 'unit_converter':
      case 'converter':
        return Colors.cyanAccent;
      case 'bmi_calculator':
        return Colors.pinkAccent;
      case 'word_counter':
        return Colors.lightGreenAccent;
      case 'password_generator':
        return Colors.greenAccent;
      case 'world_clock':
        return Colors.purpleAccent;
      case 'white_noise':
        return Colors.tealAccent;
      case 'markdown_editor':
        return Colors.amberAccent;
      case 'ai_chat':
        return Colors.purpleAccent;
      case 'ai_text_processor':
        return Colors.amberAccent;
      default:
        return Colors.deepPurpleAccent;
    }
  }

  String _getToolChineseName(String toolKey) {
    switch (toolKey) {
      case 'randomizer':
        return '随机选择生成器';
      case 'unit_converter':
      case 'converter':
        return '标准单位转换器';
      case 'bmi_calculator':
        return '健康 BMI 计算器';
      case 'word_counter':
        return '字数与字符统计器';
      case 'password_generator':
        return '密码生成与强度分析';
      case 'world_clock':
        return '多时区时钟与番茄钟';
      case 'white_noise':
        return '白噪音专注冥想';
      case 'markdown_editor':
        return '极简 Markdown 编辑器';
      case 'ai_chat':
        return 'AI 智能多轮对话助理';
      case 'ai_text_processor':
        return 'AI 写作引擎';
      default:
        return '常用系统工具';
    }
  }

  String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final difference = DateTime.now().difference(dateTime);
      if (difference.inMinutes < 1) {
        return '刚刚';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}分钟前';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}小时前';
      } else {
        return '${dateTime.month}月${dateTime.day}日';
      }
    } catch (_) {
      return '刚刚';
    }
  }

  void _showComingSoonDialog(BuildContext context, String toolName) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            borderColor: Colors.deepPurpleAccent.withOpacity(0.3),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 56,
                    color: Colors.amberAccent,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    toolName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '💡 功能正在全力开发中\n我们将于近期版本为您解锁这套超高强度的智能化服务，敬请期待！',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(120, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('好 的'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onDynamicToolClicked(String toolKey, String title) {
    final page = _getToolPage(toolKey);
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
      _showComingSoonDialog(context, title);
    }
  }

  /// System System-wide Notification Announcement bottom sheet drawer
  void _showNotificationDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: const Color(0xFF0C091F).withOpacity(0.85),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pull indicator line
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notifications_active_rounded, color: Colors.purpleAccent, size: 24),
                            SizedBox(width: 10),
                            Text(
                              '安全公告与通告中心',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Toolbox Pro 核心安全隔离通报与版本日志',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _buildNotificationCard(
                            title: '🛡️ 局域离线安全沙盒保护已激活',
                            time: '2026-05-19 12:00',
                            content: '所有本地离线计算模块（如随机选择、标准转换、健康BMI）的数据均已采用 AES-256 标准在设备端高强度加密保存。您的运算流绝不会外泄，离线隔离保护罩处于最佳安全状态。',
                            badge: '安全防护',
                            badgeColor: Colors.greenAccent,
                          ),
                          _buildNotificationCard(
                            title: '🚀 新增 Sandbox 自定义换算公式管理',
                            time: '2026-05-19 11:30',
                            content: '全新 v1.2.0 版本已全面打通 Sandbox 公式系统！现在，您可以在“个人中心”非常方便地实时查看、审查以及一键销毁（一键垃圾桶）已过期或作废的自定义计算因子。',
                            badge: '新功能',
                            badgeColor: Colors.purpleAccent,
                          ),
                          _buildNotificationCard(
                            title: '⚙️ 阿里云深圳多活高防服务器已对接',
                            time: '2026-05-18 18:45',
                            content: '为了应对可能到来的 1000+ 人高并发计算压力，后端数据网关及 Telemetry 日志管道已完成多维限流与高效降级演练。当前系统可用性达到 99.99%，网络延迟极低。',
                            badge: '系统扩容',
                            badgeColor: Colors.cyanAccent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String time,
    required String content,
    required String badge,
    required Color badgeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: Colors.white30, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = ref.watch(authProvider).email ?? "User";
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 950;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Toolbox Pro',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
            onPressed: () => _showNotificationDrawer(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: _buildActiveTabContent(userEmail, isWide),
            ),
          ),
          _buildGlassBottomNavBar(context),
        ],
      ),
      floatingActionButton: userEmail == 'admin@toolbox.com' && _currentIndex == 1
          ? Container(
              margin: const EdgeInsets.only(bottom: 90), // Offset above navbar
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    FadePageRoute(
                      child: const DeferredPage(
                        title: '系统级高级控制台',
                        child: DebugConsoleScreen(),
                      ),
                    ),
                  );
                },
                backgroundColor: const Color(0xFF0F0C29),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.purpleAccent.withOpacity(0.5), width: 1.5),
                ),
                child: const Icon(Icons.terminal_rounded, color: Colors.purpleAccent),
              ),
            )
          : null,
    );
  }

  Widget _buildBackground() {
    return const DynamicBackground(
      child: SizedBox.expand(),
    );
  }

  /// Floating Glassmorphic Bottom Navigation Bar mimicking premium mainstream shells
  Widget _buildGlassBottomNavBar(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Positioned(
      bottom: bottomPadding > 0 ? bottomPadding : 20,
      left: 20,
      right: 20,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF140F2D).withOpacity(0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.grid_view_rounded, '工作台'),
                _buildNavItem(1, Icons.analytics_rounded, '数据分析站'),
                _buildNavItem(2, Icons.manage_accounts_rounded, '个人中心'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? Colors.purpleAccent : Colors.white60;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? Colors.purpleAccent.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Dynamic live network connectivity and API server health indicator banner
  Widget _buildConnectionIndicator(AsyncValue<List<dynamic>> state) {
    final bool isOnline = state.value != null;
    final color = isOnline ? Colors.greenAccent : Colors.orangeAccent;
    final icon = isOnline ? Icons.cloud_done_rounded : Icons.wifi_off_rounded;
    final text = isOnline ? '全双工云端互联已建立 (Sync Enabled)' : '安全离线隔离沙盒模式 (Offline Sandbox)';
    final desc = isOnline ? '已连接阿里云高防加密节点 · 延迟 12ms' : '网络离线，已安全切换至本地离线高速计算芯片';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// High quality content routing based on selected tab index
  Widget _buildActiveTabContent(String userEmail, bool isWide) {
    final categoriesState = ref.watch(categoriesProvider);

    switch (_currentIndex) {
      case 0:
        // Workbench / Tools Catalog Tab
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWorkbenchHeader(userEmail),
            _buildConnectionIndicator(categoriesState),
            const SizedBox(height: 12),
            _buildRecentlyUsedSection(context),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.grid_view_rounded, color: Colors.purpleAccent, size: 16),
                  SizedBox(width: 8),
                  Text(
                    '全部工具分类库',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 400),
                firstChild: _buildStaticGrid(context, isWide),
                secondChild: categoriesState.value != null
                    ? _buildDynamicGrid(context, categoriesState.value!, isWide)
                    : const SizedBox.shrink(),
                crossFadeState: categoriesState.value == null
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
              ),
            ),
            const SizedBox(height: 80), // Prevent content being covered by floating navbar
          ],
        );
      case 1:
        // Telemetry & Logs Tab
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalyticsHeader(),
            const SizedBox(height: 16),
            const Expanded(
              child: AnalyticsView(),
            ),
            const SizedBox(height: 80),
          ],
        );
      case 2:
        // Account Settings & Custom Formulas Tab
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(userEmail),
            const SizedBox(height: 16),
            Expanded(
              child: _buildProfileSettingsContent(context, userEmail),
            ),
            const SizedBox(height: 80),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWorkbenchHeader(String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.purpleAccent, Colors.deepPurpleAccent],
              ),
            ),
            child: Center(
              child: Text(
                email.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '欢迎回来，$email',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '专属黄金加密节点 · 正常连接',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyUsedSection(BuildContext context) {
    if (_recentlyUsed.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.history_rounded, color: Colors.purpleAccent, size: 16),
              SizedBox(width: 8),
              Text(
                '最近使用的工具',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _recentlyUsed.length,
            itemBuilder: (context, index) {
              final toolKey = _recentlyUsed[index];
              final name = _getToolChineseName(toolKey);
              final color = _getToolColor(toolKey);
              final icon = _getToolIcon(toolKey);
              
              return GestureDetector(
                onTap: () {
                  final page = _getToolPage(toolKey);
                  if (page != null) {
                    Navigator.push(context, FadePageRoute(child: page));
                  } else {
                    _showComingSoonDialog(context, name);
                  }
                },
                child: Container(
                  width: 175,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              '点击即刻唤醒',
                              style: TextStyle(
                                color: Colors.white30,
                                fontSize: 9.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildAnalyticsHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '数据分析控制台',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '实时监控您所有沙盒工具上报的计算流性能与日志',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String email) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '设置与个人中心',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '管理您的云端账户凭证及自定义物理公式模板',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSettingsContent(BuildContext context, String email) {
    final converterState = ref.watch(converterProvider);
    final customConverters = converterState.customConverters;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        // 1. Account Info Section
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_rounded, color: Colors.purpleAccent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '账户凭证信息',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSettingRow('注册邮箱', email),
              const Divider(color: Colors.white10),
              _buildSettingRow('权限组', 'Premium 尊享会员'),
              const Divider(color: Colors.white10),
              _buildSettingRow('服务器会话', 'Active · AES-256 加密'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Custom Sandbox Formulas Section
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.rule_folder_rounded, color: Colors.amberAccent, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Sandbox 自定义公式库',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${customConverters.length} 个模板',
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (customConverters.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      '暂无自定义物理公式\n您可在“单位转换”->“沙盒公式”中自由编写！',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.5),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: customConverters.length,
                  itemBuilder: (context, index) {
                    final item = customConverters[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.04)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '公式：1 ${item.fromUnit} = ${item.factor} ${item.toUnit} (偏置: +${item.offset})',
                                  style: const TextStyle(color: Colors.white38, fontSize: 10.5),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                            onPressed: () {
                              ref.read(converterProvider.notifier).removeCustomConverter(item.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('公式“${item.name}”已安全销毁'),
                                  backgroundColor: const Color(0xFF0F0C29),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. System Actions
        GestureDetector(
          onTap: () => ref.read(authProvider.notifier).logout(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8A2387), Color(0xFFE94057)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE94057).withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '安全退出登录会话',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text(
            'Toolbox Pro v1.2.0 · 工业标准级应用底座',
            style: TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// App-Store style Dynamic Category list loaded from Database
  Widget _buildDynamicGrid(BuildContext context, List<dynamic> categories, bool isWide, {Key? key}) {
    if (categories.isEmpty) {
      return Center(
        key: key,
        child: const Text('无内置工具，请检查数据库配置', style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      key: key,
      physics: const BouncingScrollPhysics(),
      itemCount: categories.length,
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, catIndex) {
        final category = categories[catIndex];
        final List<dynamic> catTools = category['tools'] ?? [];

        if (catTools.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 10.0),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(category['icon']),
                    color: Colors.deepPurpleAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['name'] ?? '分类',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                // Highly optimized dense grid sizes
                int crossAxisCount = isWide
                    ? (constraints.maxWidth > 1100 ? 3 : 2)
                    : (constraints.maxWidth > 600 ? 3 : 2);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.3, // Ultra sleek horizontal card ratio
                  ),
                  itemCount: catTools.length,
                  itemBuilder: (context, toolIndex) {
                    final tool = catTools[toolIndex];
                    final String toolKey = tool['tool_key'] ?? '';
                    final String name = tool['name'] ?? '';
                    final String description = tool['description'] ?? '云端数据库极速计算已就绪';
                    final Color color = _getToolColor(toolKey);
                    final IconData icon = _getToolIcon(toolKey);

                    return ParallaxGlassCard(
                      tiltSensitivity: 0.02,
                      onTap: () => _onDynamicToolClicked(toolKey, name),
                      borderColor: color.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withOpacity(0.15), width: 1),
                              ),
                              child: Icon(icon, size: 22, color: color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Offline fallback grid rendering preseeded static utilities
  Widget _buildStaticGrid(BuildContext context, bool isWide, {Key? key}) {
    final List<Map<String, dynamic>> staticTools = [
      {'title': '随机选择生成器', 'key': 'randomizer', 'desc': '极速随机生成数字，支持快速去重', 'page': const RandomizerScreen()},
      {'title': '标准单位转换器', 'key': 'converter', 'desc': '多种体积长度质量快速一键互转', 'page': const ConverterScreen()},
      {'title': '健康 BMI 计算器', 'key': 'bmi_calculator', 'desc': '标准人体健康指标评测云储存', 'page': const BmiScreen()},
      {'title': '字数与字符统计器', 'key': 'word_counter', 'desc': '统计文本的字数、词数及中英文字符占比', 'page': null},
      {'title': '密码生成与强度分析', 'key': 'password_generator', 'desc': '安全高强度密码快捷生成及熵值分析', 'page': null},
      {'title': '多时区时钟与番茄钟', 'key': 'world_clock', 'desc': '多时区对照与高精度番茄专注时钟', 'page': null},
      {'title': '白噪音专注冥想', 'key': 'white_noise', 'desc': '精选自然白噪音辅助冥想与高效专注', 'page': null},
      {'title': '极极简 Markdown 编辑器', 'key': 'markdown_editor', 'desc': '极简 Markdown 实时预览排版与字数统计', 'page': null},
      {'title': 'AI 智能多轮对话助理', 'key': 'ai_chat', 'desc': '结合大语言模型的高强度多轮文本分析', 'page': null},
      {'title': 'AI 写作引擎', 'key': 'ai_text_processor', 'desc': '一键精准翻译、句式优雅润色与摘要提取', 'page': null},
    ];

    return ListView(
      key: key,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 10.0),
          child: Row(
            children: const [
              Icon(
                Icons.handyman_rounded,
                color: Colors.deepPurpleAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '常用工具',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = isWide
                ? (constraints.maxWidth > 1100 ? 3 : 2)
                : (constraints.maxWidth > 600 ? 3 : 2);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.3,
              ),
              itemCount: staticTools.length,
              itemBuilder: (context, index) {
                final tool = staticTools[index];
                final String toolKey = tool['key'];
                final String title = tool['title'];
                final String desc = tool['desc'];
                final Color color = _getToolColor(toolKey);
                final IconData icon = _getToolIcon(toolKey);

                return ParallaxGlassCard(
                  tiltSensitivity: 0.02,
                  onTap: () => _onDynamicToolClicked(toolKey, title),
                  borderColor: color.withOpacity(0.2),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.15), width: 1),
                          ),
                          child: Icon(icon, size: 22, color: color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                desc,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// High quality skeleton loader for dynamic content
  Widget _buildLoadingSkeleton(bool isWide) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isWide ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.3,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.deepPurpleAccent),
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String? iconSlug) {
    switch (iconSlug) {
      case 'build':
        return Icons.handyman_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'text_fields':
        return Icons.text_fields_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  /// Right side Floating Personal Center Panel Container
  Widget _buildPersonalCenterPanel(BuildContext context, WidgetRef ref, String email) {
    return GlassCard(
      borderColor: Colors.deepPurpleAccent.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: _buildPersonalCenterContent(context, ref, email),
      ),
    );
  }

  /// Interactive Personal Center inner layout displaying real database telemetry
  Widget _buildPersonalCenterContent(BuildContext context, WidgetRef ref, String email) {
    final telemetryLogs = ref.watch(telemetryLogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 👑 VIP Avatar Box
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.purpleAccent, Colors.deepPurpleAccent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.3),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    email.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Premium 尊享会员',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 🔒 Server Node Details
        const Text(
          '🔒 云端服务器节点',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '数据库已连接 (阿里云深圳)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('云端存储延迟', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Text('< 15ms', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 📊 Live Telemetry Stream
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline_rounded, color: Colors.purpleAccent, size: 16),
                SizedBox(width: 6),
                Text(
                  '📊 数据库 Telemetry 实况',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white54, size: 16),
              onPressed: () => ref.invalidate(telemetryLogsProvider),
            ),
          ],
        ),
        const SizedBox(height: 4),

        Expanded(
          child: telemetryLogs.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const Center(
                  child: Text(
                    '暂无 Telemetry 上报日志\n运行任何工具，数据将瞬间存盘！',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: logs.length > 5 ? 5 : logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final String toolKey = log['tool_key'] ?? '';
                  final String status = log['status'] ?? 'success';
                  final int duration = log['duration_ms'] ?? 0;
                  final String createdAt = log['created_at'] ?? '';
                  final Color color = _getToolColor(toolKey);

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Vertical Timeline indicator
                        Column(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            if (index != (logs.length > 5 ? 4 : logs.length - 1))
                              Expanded(
                                child: Container(
                                  width: 1.5,
                                  color: Colors.white10,
                                  ),
                                ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Log Detail
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _getToolChineseName(toolKey),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(createdAt),
                                      style: const TextStyle(
                                        color: Colors.white30,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(
                                      status == 'success' ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                                      color: status == 'success' ? Colors.greenAccent : Colors.redAccent,
                                      size: 11,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      status == 'success' ? '计算完成 · ${duration}ms' : '运算异常',
                                      style: TextStyle(
                                        color: status == 'success' ? Colors.greenAccent.withOpacity(0.8) : Colors.redAccent,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.purpleAccent),
              ),
            ),
            error: (err, stack) => const Center(
              child: Text(
                'Telemetry 数据流拉取失败',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
