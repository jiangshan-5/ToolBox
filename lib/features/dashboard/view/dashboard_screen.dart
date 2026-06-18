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
import '../../../core/providers/package_info_provider.dart';
import '../../../core/storage/local_storage.dart';
import '../../auth/provider/auth_provider.dart';
import '../../debug/view/debug_console_screen.dart';
import 'analytics_view.dart';
import 'widgets/dashboard_utils.dart';
import 'widgets/dashboard_nav_bar.dart';
import 'widgets/workbench_tab_view.dart';
import 'widgets/profile_tab_view.dart';

/// Riverpod Provider for System Announcements
final announcementsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.instance.get('/system/announcements');
  return response.data as List<dynamic>;
});

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
        '${baseUrl.replaceAll('http://', 'ws://').replaceAll('https://', 'wss://')}/system/ws/updates';

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

              final packageInfo = ref.read(packageInfoProvider);
              final currentVersionCode =
                  int.tryParse(packageInfo.buildNumber) ?? 0;

              if (versionCode > currentVersionCode) {
                final prefs = ref.read(sharedPreferencesProvider);
                final ignoredVersion =
                    prefs.getInt('ignored_version_code') ?? 0;
                if (forceUpdate || versionCode > ignoredVersion) {
                  if (mounted) {
                    UpdateDialog.show(
                      context,
                      latestVersion: latestVersion,
                      changelog: changelog,
                      downloadUrl: downloadUrl,
                      forceUpdate: forceUpdate,
                      onIgnore: () async {
                        await prefs.setInt('ignored_version_code', versionCode);
                      },
                    );
                  }
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

  /// Perform system update validation
  Future<void> _checkForUpdates() async {
    if (kIsWeb) return;
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.instance.get(
        '/system/version',
        queryParameters: {'t': DateTime.now().millisecondsSinceEpoch},
      );
      final data = response.data;
      if (data != null) {
        final latestVersion = data['latest_version'] as String;
        final versionCode = data['version_code'] as int;
        final changelog = data['changelog'] as String;
        final downloadUrl = data['download_url'] as String;
        final forceUpdate = data['force_update'] as bool;

        final packageInfo = ref.read(packageInfoProvider);
        final currentVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

        if (versionCode > currentVersionCode) {
          final prefs = ref.read(sharedPreferencesProvider);
          final ignoredVersion = prefs.getInt('ignored_version_code') ?? 0;
          if (forceUpdate || versionCode > ignoredVersion) {
            if (mounted) {
              UpdateDialog.show(
                context,
                latestVersion: latestVersion,
                changelog: changelog,
                downloadUrl: downloadUrl,
                forceUpdate: forceUpdate,
                onIgnore: () async {
                  await prefs.setInt('ignored_version_code', versionCode);
                },
              );
            }
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
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    // Refresh the announcements provider when opening the drawer
    ref.invalidate(announcementsProvider);

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
                color: theme.colorScheme.surface.withOpacity(0.85),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.08),
                  width: 1.2,
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
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_active_rounded,
                          color: primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '安全公告与通告中心',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: subTextColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toolbox Pro 核心安全隔离通报与版本日志',
                      style: TextStyle(
                        color: subTextColor.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final announcementsAsync = ref.watch(
                            announcementsProvider,
                          );
                          return announcementsAsync.when(
                            data: (announcements) {
                              if (announcements.isEmpty) {
                                return Center(
                                  child: Text(
                                    '📭 暂无任何公告通知',
                                    style: TextStyle(
                                      color: subTextColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }
                              return ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                itemCount: announcements.length,
                                itemBuilder: (context, index) {
                                  final item =
                                      announcements[index]
                                          as Map<String, dynamic>;
                                  return _buildNotificationCard(
                                    context: context,
                                    icon: _getIconData(
                                      item['icon']?.toString() ?? '',
                                    ),
                                    title: item['title']?.toString() ?? '',
                                    time: item['time']?.toString() ?? '',
                                    content: item['content']?.toString() ?? '',
                                    badge: item['badge']?.toString() ?? '',
                                    badgeColor: _getBadgeColor(
                                      item['badgeColor']?.toString() ?? '',
                                      primaryColor,
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => Center(
                              child: CircularProgressIndicator(
                                color: primaryColor,
                              ),
                            ),
                            error: (err, stack) => Center(
                              child: Text(
                                '⚠️ 加载公告失败: $err',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
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

  IconData _getIconData(String iconName) => switch (iconName) {
    'rocket_launch_rounded' => Icons.rocket_launch_rounded,
    'shield_rounded' => Icons.shield_rounded,
    'dns_rounded' => Icons.dns_rounded,
    _ => Icons.notifications_rounded,
  };

  Color _getBadgeColor(String colorName, Color primaryColor) =>
      switch (colorName) {
        'primary' => primaryColor,
        'greenAccent' => Colors.greenAccent,
        'cyanAccent' => Colors.cyanAccent,
        _ => Colors.grey,
      };

  Widget _buildNotificationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String time,
    required String content,
    required String badge,
    required Color badgeColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final timeColor = isDark ? Colors.white30 : Colors.black38;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.02)
            : Colors.black.withOpacity(0.01),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.04)
              : Colors.black.withOpacity(0.05),
        ),
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
                  color: badgeColor.withOpacity(0.12),
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
              Text(time, style: TextStyle(color: timeColor, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, color: badgeColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(color: subTextColor, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    final userEmail = ref.watch(authProvider).email ?? "未绑定邮箱";
    final userNickname = ref.watch(authProvider).nickname ?? "Toolbox User";
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 950;
    final horizontalPadding = isWide ? 28.0 : (size.width < 380 ? 16.0 : 20.0);

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
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isWide ? 12.0 : 8.0,
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
            const SizedBox(height: 112),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white38 : Colors.black45;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '数据分析控制台',
            style: TextStyle(
              color: textColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '实时监控您所有沙盒工具上报的计算流性能与日志',
            style: TextStyle(color: subTextColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
