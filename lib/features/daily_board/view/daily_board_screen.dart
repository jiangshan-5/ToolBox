import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/provider/auth_provider.dart';
import '../../dashboard/provider/tools_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'dart:js' if (dart.library.html) 'dart:js' as js;
import '../../../core/storage/local_storage.dart';
import '../../../core/providers/api_config_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'widgets/daily_board_quote_studio.dart';
import 'widgets/daily_board_morning_news.dart';
import 'widgets/daily_board_trends_board.dart';
import 'widgets/daily_board_push_controller.dart';

class DailyBoardScreen extends ConsumerStatefulWidget {
  const DailyBoardScreen({super.key});

  @override
  ConsumerState<DailyBoardScreen> createState() => _DailyBoardScreenState();
}

class _DailyBoardScreenState extends ConsumerState<DailyBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingQuote = false;
  bool _isLoadingNews = false;
  bool _isLoadingHot = false;

  String _quoteText = "生命不仅是解决问题，更是去体验那些不可思议的奇迹。";
  String _quoteAuthor = "阿尔伯特·爱因斯坦";
  String _quoteSource = "理论物理随笔";

  List<String> _newsList = ["📅 正在加载最新时事早报，请稍候..."];

  List<Map<String, dynamic>> _weiboTrends = [];
  List<Map<String, dynamic>> _baiduTrends = [];
  List<Map<String, dynamic>> _bilibiliTrends = [];

  // Push Notification Simulation State
  bool _pushOnStartup = false;
  int _pushNewsCount = 3;
  int _pushIntervalSeconds = 10;
  bool _isPeriodicPushRunning = false;
  Timer? _periodicPushTimer;
  final List<Map<String, dynamic>> _pushHistory = [];
  OverlayEntry? _activeNotificationOverlay;

  // Custom Card Studio Parameters
  int _selectedGradientIndex = 0;
  double _cardOpacity = 0.85;
  double _textSize = 14.5;
  TextAlign _textAlign = TextAlign.center;

  final List<List<Color>> _cardGradients = [
    [const Color(0xFF26103A), const Color(0xFF4C0E5A)], // Cyberpunk Violet
    [
      const Color(0xFF0F2027),
      const Color(0xFF203A43),
      const Color(0xFF2C5364),
    ], // Deep Ocean
    [
      const Color(0xFF3A6073),
      const Color(0xFF3A6073).withBlue(220),
    ], // Steel Grey Blue
    [
      const Color(0xFF833ab4),
      const Color(0xFFfd1d1d),
      const Color(0xFFfcb045),
    ], // Sunset Glow
    [const Color(0xFF11998e), const Color(0xFF38ef7d)], // Emerald Forest
  ];

  final List<String> _gradientNames = ["赛博幽紫", "深海静谧", "极客冷灰", "霞光万丈", "绿野仙踪"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Trigger dynamic fetch on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchQuote();
      _fetchNews();
      _fetchHotSearches();
      _logToolUsage();
      _loadPushSettings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _periodicPushTimer?.cancel();
    _activeNotificationOverlay?.remove();
    _activeNotificationOverlay = null;
    super.dispose();
  }

  void _logToolUsage() {
    try {
      ref
          .read(toolsAnalyticsProvider)
          .logUsage(
            toolKey: 'daily_board',
            parameters: {'action': 'open_board'},
            status: 'success',
            durationMs: 0,
          );
    } catch (_) {}
  }

  Future<void> _fetchQuote() async {
    if (_isLoadingQuote) return;
    setState(() => _isLoadingQuote = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.instance.get('/system/quote');
      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          _quoteText = response.data['quote'] ?? _quoteText;
          _quoteAuthor = response.data['author'] ?? _quoteAuthor;
          _quoteSource = response.data['source'] ?? _quoteSource;
        });
      }
    } catch (_) {
      // Fallback works automatically in the backend or local defaults
    } finally {
      setState(() => _isLoadingQuote = false);
    }
  }

  Future<void> _fetchNews() async {
    if (_isLoadingNews) return;
    setState(() => _isLoadingNews = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.instance.get('/system/news');
      if (response.statusCode == 200 && response.data != null) {
        final rawNews = response.data['news'];
        if (rawNews is List) {
          setState(() {
            _newsList = List<String>.from(rawNews);
          });
        }
      }
    } catch (_) {
      // Automatic backup
    } finally {
      setState(() => _isLoadingNews = false);
    }
  }

  Future<void> _fetchHotSearches() async {
    if (_isLoadingHot) return;
    setState(() => _isLoadingHot = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.instance.get('/system/hot-searches');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        setState(() {
          _weiboTrends = List<Map<String, dynamic>>.from(data['weibo'] ?? []);
          _baiduTrends = List<Map<String, dynamic>>.from(data['baidu'] ?? []);
          _bilibiliTrends = List<Map<String, dynamic>>.from(
            data['bilibili'] ?? [],
          );
        });
      }
    } catch (_) {
      // Local fallbacks
    } finally {
      setState(() => _isLoadingHot = false);
    }
  }

  void _copyQuote() {
    final text =
        "“$_quoteText”\n—— $_quoteAuthor 《$_quoteSource》\n分享自 Toolbox Pro";
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ 语录文本已成功复制到剪贴板！'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ 无法打开链接，请重试！'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  void _loadPushSettings() {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      setState(() {
        _pushOnStartup = prefs.getBool('push_on_startup') ?? false;
        _pushNewsCount = prefs.getInt('push_news_count') ?? 3;
        _pushIntervalSeconds = prefs.getInt('push_interval_seconds') ?? 10;
      });

      if (_pushOnStartup) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          final now = DateTime.now().toLocal().toString().substring(11, 19);
          final welcomeTitle = "🚀 ToolBox Pro 开屏时事速递 ($now)";
          final welcomeItems = _getCuratedNewsForPush(_pushNewsCount);

          _showFloatingNotification(title: welcomeTitle, items: welcomeItems);
          _playChimeSound();
          _triggerBrowserNotification(title: welcomeTitle, items: welcomeItems);
        });
      }
    } catch (_) {}
  }

  void _savePushSetting(String key, dynamic value) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      }
    } catch (_) {}
  }

  List<String> _getCuratedNewsForPush(int count) {
    final cleanNews = _newsList.where((item) {
      return !item.contains('早报') && !item.contains('寄语');
    }).toList();

    if (cleanNews.isEmpty) {
      return ["正在从极速安全网关拉取最新时事早报，请稍候..."];
    }

    final resultCount = count.clamp(1, cleanNews.length);
    return cleanNews.sublist(0, resultCount);
  }

  void _showFloatingNotification({
    required String title,
    required List<String> items,
  }) {
    _activeNotificationOverlay?.remove();
    _activeNotificationOverlay = null;

    final overlayState = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 60,
          left: 20,
          right: 20,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: -150, end: 0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {
                  _activeNotificationOverlay?.remove();
                  _activeNotificationOverlay = null;
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF160E35), Color(0xFF2C1045)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.cyanAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.close_rounded,
                            color: Colors.white38,
                            size: 14,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "• ",
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(entry);
    _activeNotificationOverlay = entry;

    Future.delayed(const Duration(seconds: 6), () {
      if (_activeNotificationOverlay == entry) {
        entry.remove();
        _activeNotificationOverlay = null;
      }
    });
  }

  void _triggerDelayedPush() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔔 5秒后台推送模拟已启动！请立即切回系统桌面或锁屏测试...'),
        backgroundColor: Colors.cyan,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Timer(const Duration(seconds: 5), () {
      final now = DateTime.now().toLocal().toString().substring(11, 19);
      final pushTitle = "⚡ ToolBox Pro 后台时事速递 ($now)";
      final pushItems = _getCuratedNewsForPush(_pushNewsCount);

      _showFloatingNotification(title: pushTitle, items: pushItems);
      _playChimeSound();

      if (mounted) {
        setState(() {
          _pushHistory.insert(0, {
            'time': now,
            'title': pushTitle,
            'items': pushItems,
          });
        });
      }

      _triggerBrowserNotification(title: pushTitle, items: pushItems);
    });
  }

  void _triggerBrowserNotification({
    required String title,
    required List<String> items,
  }) {
    if (!kIsWeb) return;
    try {
      final hasNotification = js.context.hasProperty('Notification');
      if (hasNotification) {
        final permission = js.context['Notification']['permission'];
        if (permission == 'granted') {
          final bodyText = items.join('\n');
          js.context.callMethod('Notification', [
            title,
            js.JsObject.jsify({'body': bodyText}),
          ]);
        } else if (permission != 'denied') {
          js.context['Notification'].callMethod('requestPermission');
        }
      }
    } catch (_) {}
  }

  void _playChimeSound() async {
    try {
      final player = AudioPlayer();
      await player.setUrl(
        'https://assets.mixkit.co/active_storage/sfx/2568/2568-84.wav',
      );
      await player.setVolume(0.85);
      await player.play();
      Future.delayed(const Duration(seconds: 4), () => player.dispose());
    } catch (_) {}
  }

  void _startPeriodicPush() {
    setState(() => _isPeriodicPushRunning = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ 自动轮询推送已启动！每隔 $_pushIntervalSeconds 秒将自动广播...'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _periodicPushTimer = Timer.periodic(
      Duration(seconds: _pushIntervalSeconds),
      (timer) {
        final now = DateTime.now().toLocal().toString().substring(11, 19);
        final pushTitle = "⚡ ToolBox Pro 定时广播 ($now)";
        final pushItems = _getCuratedNewsForPush(_pushNewsCount);

        _showFloatingNotification(title: pushTitle, items: pushItems);
        _playChimeSound();
        if (mounted) {
          setState(() {
            _pushHistory.insert(0, {
              'time': now,
              'title': pushTitle,
              'items': pushItems,
            });
          });
        }
        _triggerBrowserNotification(title: pushTitle, items: pushItems);
      },
    );
  }

  void _stopPeriodicPush() {
    _periodicPushTimer?.cancel();
    _periodicPushTimer = null;
    setState(() => _isPeriodicPushRunning = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🛑 自动轮询推送已停止。'),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white70,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '今日时事与卡片工坊',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () {
              _fetchQuote();
              _fetchNews();
              _fetchHotSearches();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF090615),
                  Color(0xFF120B24),
                  Color(0xFF040308),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // 1. Interactive Quote Card Studio Section
                _buildSectionHeader('🎨 语录与即刻卡片工坊', Icons.palette_outlined),
                const SizedBox(height: 12),
                DailyBoardQuoteStudio(
                  isLoadingQuote: _isLoadingQuote,
                  quoteText: _quoteText,
                  quoteAuthor: _quoteAuthor,
                  quoteSource: _quoteSource,
                  selectedGradientIndex: _selectedGradientIndex,
                  cardOpacity: _cardOpacity,
                  textSize: _textSize,
                  textAlign: _textAlign,
                  cardGradients: _cardGradients,
                  gradientNames: _gradientNames,
                  onFetchQuote: _fetchQuote,
                  onCopyQuote: _copyQuote,
                  onGradientChanged: (index) => setState(() => _selectedGradientIndex = index),
                  onTextSizeChanged: (val) => setState(() => _textSize = val),
                  onCardOpacityChanged: (val) => setState(() => _cardOpacity = val),
                  onTextAlignChanged: (align) => setState(() => _textAlign = align),
                ),
                const SizedBox(height: 24),

                // 2. 60s Daily Morning News Section
                _buildSectionHeader(
                  '📰 今日 60 秒读懂世界',
                  Icons.library_books_outlined,
                ),
                const SizedBox(height: 12),
                DailyBoardMorningNews(
                  isLoadingNews: _isLoadingNews,
                  newsList: _newsList,
                  onNewsTap: (item) {
                    if (item.isNotEmpty) {
                      final apiBaseUrl = ref.read(apiBaseUrlProvider);
                      _launchURL('$apiBaseUrl/system/news/redirect?q=${Uri.encodeComponent(item)}');
                    }
                  },
                ),
                const SizedBox(height: 24),

                // 3. Trends Board Section
                _buildSectionHeader(
                  '🔥 实时热搜风向标',
                  Icons.local_fire_department_outlined,
                ),
                const SizedBox(height: 12),
                DailyBoardTrendsBoard(
                  isLoadingHot: _isLoadingHot,
                  weiboTrends: _weiboTrends,
                  baiduTrends: _baiduTrends,
                  bilibiliTrends: _bilibiliTrends,
                  tabController: _tabController,
                  onTrendTap: (title, platform) {
                    if (title.isNotEmpty) {
                      final apiBaseUrl = ref.read(apiBaseUrlProvider);
                      _launchURL('$apiBaseUrl/system/news/redirect?q=${Uri.encodeComponent(title)}&platform=$platform');
                    }
                  },
                ),
                const SizedBox(height: 24),

                // 4. Push & Broadcast Simulator Section
                _buildSectionHeader(
                  '📡 时事推送与系统广播中心',
                  Icons.sensors_rounded,
                ),
                const SizedBox(height: 12),
                DailyBoardPushController(
                  pushOnStartup: _pushOnStartup,
                  pushNewsCount: _pushNewsCount,
                  isPeriodicPushRunning: _isPeriodicPushRunning,
                  pushIntervalSeconds: _pushIntervalSeconds,
                  pushHistory: _pushHistory,
                  onPushOnStartupChanged: (val) {
                    setState(() => _pushOnStartup = val);
                    _savePushSetting('push_on_startup', val);
                  },
                  onPushNewsCountChanged: (val) {
                    setState(() => _pushNewsCount = val);
                    _savePushSetting('push_news_count', val);
                  },
                  onPeriodicPushRunningChanged: (val) {
                    if (val) {
                      _startPeriodicPush();
                    } else {
                      _stopPeriodicPush();
                    }
                  },
                  onPushIntervalSecondsChanged: (val) {
                    setState(() => _pushIntervalSeconds = val);
                    _savePushSetting('push_interval_seconds', val);
                  },
                  onTriggerImmediatePush: () {
                    final now = DateTime.now().toLocal().toString().substring(11, 19);
                    final title = "🚀 ToolBox Pro 即刻时事推送 ($now)";
                    final items = _getCuratedNewsForPush(_pushNewsCount);

                    _showFloatingNotification(title: title, items: items);
                    _playChimeSound();
                    _triggerBrowserNotification(title: title, items: items);

                    setState(() {
                      _pushHistory.insert(0, {
                        'time': now,
                        'title': title,
                        'items': items,
                      });
                    });
                  },
                  onTriggerDelayedPush: _triggerDelayedPush,
                  onClearHistory: () => setState(() => _pushHistory.clear()),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
