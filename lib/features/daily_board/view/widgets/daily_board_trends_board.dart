import 'package:flutter/material.dart';
import '../../../../core/widgets/glass_card.dart';

class DailyBoardTrendsBoard extends StatelessWidget {
  final bool isLoadingHot;
  final List<Map<String, dynamic>> weiboTrends;
  final List<Map<String, dynamic>> baiduTrends;
  final List<Map<String, dynamic>> bilibiliTrends;
  final TabController tabController;
  final void Function(String title, String platform) onTrendTap;

  const DailyBoardTrendsBoard({
    super.key,
    required this.isLoadingHot,
    required this.weiboTrends,
    required this.baiduTrends,
    required this.bilibiliTrends,
    required this.tabController,
    required this.onTrendTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: Colors.white.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TabBar(
              controller: tabController,
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
              child: isLoadingHot
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.cyanAccent,
                        strokeWidth: 2,
                      ),
                    )
                  : TabBarView(
                      controller: tabController,
                      children: [
                        _buildTrendingTabList(
                          weiboTrends,
                          Colors.orangeAccent,
                          'weibo',
                        ),
                        _buildTrendingTabList(
                          baiduTrends,
                          Colors.cyanAccent,
                          'baidu',
                        ),
                        _buildTrendingTabList(
                          bilibiliTrends,
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
            onTap: () => onTrendTap(title, platform),
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
