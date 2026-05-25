import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/dynamic_effects.dart';
import '../../auth/provider/auth_provider.dart';
import '../../dashboard/provider/tools_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  IconData _getNewsIcon(String text, int index, bool isHeader) {
    if (isHeader) {
      return Icons.today_rounded;
    }
    if (index == _newsList.length - 1) {
      return Icons.auto_awesome_rounded;
    }
    if (text.contains('航天') || text.contains('卫星')) {
      return Icons.rocket_launch_rounded;
    }
    if (text.contains('人工智能') || text.contains('智能') || text.contains('AI')) {
      return Icons.psychology_rounded;
    }
    if (text.contains('车') || text.contains('电池') || text.contains('出行')) {
      return Icons.electric_car_rounded;
    }
    if (text.contains('计算') || text.contains('芯片') || text.contains('量子')) {
      return Icons.memory_rounded;
    }
    if (text.contains('经济') || text.contains('金融') || text.contains('交易')) {
      return Icons.insights_rounded;
    }
    if (text.contains('医学') || text.contains('健康') || text.contains('生物')) {
      return Icons.medical_services_rounded;
    }
    if (text.contains('天文') || text.contains('宇宙') || text.contains('星')) {
      return Icons.wb_twilight_rounded;
    }
    return Icons.fiber_manual_record_rounded;
  }

  Color _getNewsIconColor(String text, int index, bool isHeader) {
    if (isHeader) {
      return Colors.amberAccent;
    }
    if (index == _newsList.length - 1) {
      return Colors.amberAccent;
    }
    if (text.contains('航天') || text.contains('计算') || text.contains('天文')) {
      return Colors.cyanAccent;
    }
    if (text.contains('人工智能')) {
      return Colors.pinkAccent.shade100;
    }
    if (text.contains('车') || text.contains('经济')) {
      return Colors.greenAccent;
    }
    if (text.contains('医学')) {
      return Colors.orangeAccent.shade100;
    }
    return Colors.cyanAccent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

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
          // Cyberpunk background
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
                _buildQuoteCardStudio(textColor, subTextColor),
                const SizedBox(height: 24),

                // 2. 60s Daily Morning News Section
                _buildSectionHeader(
                  '📰 今日 60 秒读懂世界',
                  Icons.library_books_outlined,
                ),
                const SizedBox(height: 12),
                _buildMorningNewsCard(subTextColor),
                const SizedBox(height: 24),

                // 3. Trends Board Section
                _buildSectionHeader(
                  '🔥 实时热搜风向标',
                  Icons.local_fire_department_outlined,
                ),
                const SizedBox(height: 12),
                _buildTrendsBoard(textColor, subTextColor),
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

  Widget _buildQuoteCardStudio(Color textColor, Color subTextColor) {
    return GlassCard(
      borderColor: Colors.white.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview Card with custom properties
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 180),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _cardGradients[_selectedGradientIndex],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _cardGradients[_selectedGradientIndex][0]
                          .withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Text(
                        "一 言 • H I T O K O T O",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isLoadingQuote
                        ? const Center(
                            child: SizedBox(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator(
                                color: Colors.white70,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Text(
                            "“$_quoteText”",
                            textAlign: _textAlign,
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: _cardOpacity,
                              ),
                              fontSize: _textSize,
                              fontWeight: FontWeight.bold,
                              height: 1.6,
                              shadows: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                    const SizedBox(height: 20),
                    if (!_isLoadingQuote)
                      Text(
                        "—— $_quoteAuthor 《$_quoteSource》",
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Background Selection Slider
            const Text(
              "选择背景渐变：",
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _cardGradients.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedGradientIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedGradientIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? Colors.cyanAccent
                              : Colors.white.withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1,
                        ),
                        gradient: LinearGradient(
                          colors: _cardGradients[index],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _gradientNames[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Controls (Text Size & Alignment)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "卡片字体大小：",
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      Slider(
                        value: _textSize,
                        min: 12.0,
                        max: 20.0,
                        activeColor: Colors.cyanAccent,
                        inactiveColor: Colors.white.withValues(alpha: 0.05),
                        onChanged: (val) => setState(() => _textSize = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "卡片透明度：",
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      Slider(
                        value: _cardOpacity,
                        min: 0.5,
                        max: 1.0,
                        activeColor: Colors.cyanAccent,
                        inactiveColor: Colors.white.withValues(alpha: 0.05),
                        onChanged: (val) => setState(() => _cardOpacity = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Alignment selector
                Row(
                  children: [
                    const Text(
                      "对齐方式：",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.align_horizontal_left_rounded,
                        color: _textAlign == TextAlign.left
                            ? Colors.cyanAccent
                            : Colors.white38,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _textAlign = TextAlign.left),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.align_horizontal_center_rounded,
                        color: _textAlign == TextAlign.center
                            ? Colors.cyanAccent
                            : Colors.white38,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _textAlign = TextAlign.center),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.align_horizontal_right_rounded,
                        color: _textAlign == TextAlign.right
                            ? Colors.cyanAccent
                            : Colors.white38,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _textAlign = TextAlign.right),
                    ),
                  ],
                ),

                // Studio actions
                Row(
                  children: [
                    ScaleOnTap(
                      onTap: _fetchQuote,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withValues(alpha: 0.04),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cached_rounded,
                              color: Colors.cyanAccent.shade100,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "随机换一句",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ScaleOnTap(
                      onTap: _copyQuote,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: const LinearGradient(
                            colors: [Colors.cyanAccent, Color(0xFF00E5FF)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              color: Colors.black87,
                              size: 13,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "复制卡片",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMorningNewsCard(Color subTextColor) {
    return GlassCard(
      borderColor: Colors.white.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.cyanAccent.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Text(
                    "📅 DAILY REPORT",
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Text(
                  "新闻源: 后端极速安全网关",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _isLoadingNews
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: CircularProgressIndicator(
                        color: Colors.cyanAccent,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _newsList.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.white.withValues(alpha: 0.04),
                      height: 16,
                    ),
                    itemBuilder: (context, index) {
                      final item = _newsList[index];
                      final isHeader = index == 0;
                      final iconData = _getNewsIcon(item, index, isHeader);
                      final iconColor = _getNewsIconColor(item, index, isHeader);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          hoverColor: Colors.white.withValues(alpha: 0.04),
                          splashColor: Colors.cyanAccent.withValues(alpha: 0.08),
                          onTap: () {
                            if (item.isNotEmpty) {
                              _launchURL(
                                'https://www.baidu.com/s?wd=${Uri.encodeComponent(item)}',
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6.0,
                              horizontal: 8.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  iconData,
                                  color: iconColor,
                                  size: isHeader ? 15 : 13.5,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      color: isHeader
                                          ? Colors.white
                                          : Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                      fontSize: isHeader ? 13.5 : 12.5,
                                      fontWeight: isHeader
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsBoard(Color textColor, Color subTextColor) {
    return GlassCard(
      borderColor: Colors.white.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.cyanAccent,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white38,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
              tabs: const [
                Tab(text: "微博热搜榜"),
                Tab(text: "百度风云榜"),
                Tab(text: "哔哩哔哩热议"),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 290,
              child: _isLoadingHot
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.cyanAccent,
                        strokeWidth: 2,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTrendingTabList(
                          _weiboTrends,
                          Colors.orangeAccent,
                          'weibo',
                        ),
                        _buildTrendingTabList(
                          _baiduTrends,
                          Colors.cyanAccent,
                          'baidu',
                        ),
                        _buildTrendingTabList(
                          _bilibiliTrends,
                          Colors.pinkAccent,
                          'bilibili',
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingTabList(
    List<Map<String, dynamic>> list,
    Color themeColor,
    String platform,
  ) {
    if (list.isEmpty) {
      return const Center(
        child: Text(
          "暂无数据，请尝试刷新",
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final title = item['title'] ?? '';
        final hot = item['hot'] ?? '';
        final trend = item['trend'] ?? 'default';

        Widget trendWidget = const SizedBox.shrink();
        if (trend == 'up') {
          trendWidget = const Icon(
            Icons.arrow_upward_rounded,
            color: Colors.redAccent,
            size: 12,
          );
        } else if (trend == 'hot') {
          trendWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              "HOT",
              style: TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        } else if (trend == 'new') {
          trendWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              "NEW",
              style: TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            hoverColor: Colors.white.withValues(alpha: 0.04),
            splashColor: themeColor.withValues(alpha: 0.1),
            onTap: () {
              if (title.isNotEmpty) {
                String searchUrl = '';
                if (platform == 'weibo') {
                  searchUrl =
                      'https://s.weibo.com/weibo?q=${Uri.encodeComponent(title)}';
                } else if (platform == 'baidu') {
                  searchUrl =
                      'https://www.baidu.com/s?wd=${Uri.encodeComponent(title)}';
                } else if (platform == 'bilibili') {
                  searchUrl =
                      'https://search.bilibili.com/all?keyword=${Uri.encodeComponent(title)}';
                }
                if (searchUrl.isNotEmpty) {
                  _launchURL(searchUrl);
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.02),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Position Index
                  Container(
                    width: 24,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "${index + 1}",
                      style: TextStyle(
                        color: index < 3 ? themeColor : Colors.white24,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // Topic Title
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        trendWidget,
                      ],
                    ),
                  ),

                  // Heat Metric
                  if (hot.isNotEmpty)
                    Text(
                      hot,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10.5,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
