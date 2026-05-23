import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import '../../../core/widgets/update_dialog.dart';
import '../../../core/widgets/dynamic_background.dart';
import '../../../core/widgets/deferred_page.dart';
import '../../../core/providers/api_config_provider.dart';
import '../../auth/provider/auth_provider.dart';
import '../../debug/view/debug_console_screen.dart';
import 'analytics_view.dart';
import 'widgets/dashboard_utils.dart';
import 'widgets/dashboard_nav_bar.dart';
import 'widgets/workbench_tab_view.dart';
import 'widgets/profile_tab_view.dart';

/// Standardized Mainstream Workbench Dashboard Shell
/// Employs a premium 3-Tab Architecture with a floating glassmorphic Navigation Bar
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  WebSocket? _socket;
  bool _isDisposed = false;
  String? _connectedUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
      _connectWebSocket(ref.read(apiBaseUrlProvider));
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _socket?.close();
    super.dispose();
  }

  void _connectWebSocket(String baseUrl) async {
    if (kIsWeb) return;
    if (_isDisposed) return;
    if (_connectedUrl == baseUrl && _socket != null) return;

    _socket?.close();
    _connectedUrl = baseUrl;

    String wsUrl =
        baseUrl
            .replaceAll('http://', 'ws://')
            .replaceAll('https://', 'wss://') +
        '/system/ws/updates';

    try {
      _socket = await WebSocket.connect(
        wsUrl,
      ).timeout(const Duration(seconds: 4));
      _socket!.listen(
        (message) {
          try {
            final data = jsonDecode(message as String);
            if (data['type'] == 'new_version') {
              final latestVersion = data['latest_version'] as String;
              final versionCode = data['version_code'] as int;
              final changelog = data['changelog'] as String;
              final downloadUrl = data['download_url'] as String;
              final forceUpdate = data['force_update'] as bool;
              const currentVersionCode = 1;

              if (versionCode > currentVersionCode) {
                if (mounted) {
                  UpdateDialog.show(
                    context,
                    latestVersion: latestVersion,
                    changelog: changelog,
                    downloadUrl: downloadUrl,
                    forceUpdate: forceUpdate,
                  );
                }
              }
            }
          } catch (_) {}
        },
        onError: (_) => _retryConnection(baseUrl),
        onDone: () => _retryConnection(baseUrl),
        cancelOnError: true,
      );
    } catch (_) {
      _retryConnection(baseUrl);
    }
  }

  void _retryConnection(String baseUrl) {
    if (kIsWeb) return;
    if (_isDisposed) return;
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted || _isDisposed) return;
      final currentUrl = ref.read(apiBaseUrlProvider);
      if (currentUrl == baseUrl) {
        _connectWebSocket(baseUrl);
      }
    });
  }

  void _reconnectWebSocket(String newUrl) {
    if (kIsWeb) return;
    _socket?.close();
    _socket = null;
    _connectedUrl = null;
    _connectWebSocket(newUrl);
  }

  /// Perform system update validation
  Future<void> _checkForUpdates() async {
    if (kIsWeb) return;
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.instance.get('/system/version');
      final data = response.data;
      if (data != null) {
        final latestVersion = data['latest_version'] as String;
        final versionCode = data['version_code'] as int;
        final changelog = data['changelog'] as String;
        final downloadUrl = data['download_url'] as String;
        final forceUpdate = data['force_update'] as bool;
        const currentVersionCode = 1;
        if (versionCode > currentVersionCode) {
          if (mounted) {
            UpdateDialog.show(
              context,
              latestVersion: latestVersion,
              changelog: changelog,
              downloadUrl: downloadUrl,
              forceUpdate: forceUpdate,
            );
          }
        }
      }
    } catch (_) {
      // Graceful local bypass for offline operation or connection drops
    }
  }

  /// System System-wide Notification Announcement bottom sheet drawer
  void _showNotificationDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

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
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            const Text(
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
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white54,
                          ),
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
                            content:
                                '所有本地离线计算模块（如随机选择、标准转换、健康BMI）的数据均已采用 AES-256 标准在设备端高强度加密保存。您的运算流绝不会外泄，离线隔离保护罩处于最佳安全状态。',
                            badge: '安全防护',
                            badgeColor: Colors.greenAccent,
                          ),
                          _buildNotificationCard(
                            title: '🚀 新增 Sandbox 自定义换算公式管理',
                            time: '2026-05-19 11:30',
                            content:
                                '全新 v1.2.0 版本已全面打通 Sandbox 公式系统！现在，您可以在“个人中心”非常方便地实时查看、审查以及一键销毁（一键垃圾桶）已过期或作废的自定义计算因子。',
                            badge: '新功能',
                            badgeColor: primaryColor,
                          ),
                          _buildNotificationCard(
                            title: '⚙️ 阿里云深圳多活高防服务器已对接',
                            time: '2026-05-18 18:45',
                            content:
                                '为了应对可能到来的 1000+ 人高并发计算压力，后端数据网关及 Telemetry 日志管道已完成多维限流与高效降级演练。当前系统可用性达到 99.99%，网络延迟极低。',
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
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(apiBaseUrlProvider, (previous, next) {
      if (previous != next && next.isNotEmpty) {
        _reconnectWebSocket(next);
      }
    });

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    final userEmail = ref.watch(authProvider).email ?? "未绑定邮箱";
    final userNickname = ref.watch(authProvider).nickname ?? "Toolbox User";
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 950;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Toolbox Pro',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: subTextColor),
            onPressed: () => _showNotificationDrawer(context),
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: subTextColor),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const DynamicBackground(child: SizedBox.expand()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: _buildActiveTabContent(userEmail, userNickname, isWide),
            ),
          ),
          DashboardNavBar(
            currentIndex: _currentIndex,
            onTabSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ],
      ),
      floatingActionButton:
          userEmail == 'admin@toolbox.com' && _currentIndex == 1
          ? Container(
              margin: const EdgeInsets.only(bottom: 90), // Offset above navbar
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
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
                  side: BorderSide(
                    color: primaryColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(Icons.terminal_rounded, color: primaryColor),
              ),
            )
          : null,
    );
  }

  Widget _buildActiveTabContent(
    String userEmail,
    String userNickname,
    bool isWide,
  ) {
    switch (_currentIndex) {
      case 0:
        return WorkbenchTabView(userEmail: userEmail, isWide: isWide);
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalyticsHeader(),
            const SizedBox(height: 16),
            const Expanded(child: AnalyticsView()),
            const SizedBox(height: 80),
          ],
        );
      case 2:
        return ProfileTabView(
          userEmail: userEmail,
          userNickname: userNickname,
          isWide: isWide,
        );
      default:
        return const SizedBox.shrink();
    }
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
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
