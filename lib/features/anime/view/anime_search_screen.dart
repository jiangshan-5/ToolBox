import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../../../../core/widgets/dynamic_background.dart';
import '../model/anime.dart';
import '../provider/anime_provider.dart';
import 'anime_detail_screen.dart';

class AnimeSearchScreen extends ConsumerStatefulWidget {
  const AnimeSearchScreen({super.key});

  @override
  ConsumerState<AnimeSearchScreen> createState() => _AnimeSearchScreenState();
}

class _AnimeSearchScreenState extends ConsumerState<AnimeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;
    
    _searchController.text = cleanQuery;
    setState(() {
      _hasSearched = true;
    });
    
    ref.read(animeSearchHistoryProvider.notifier).addQuery(cleanQuery);
    ref.read(animeSearchProvider.notifier).search(cleanQuery);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(animeSearchProvider);
    final history = ref.watch(animeSearchHistoryProvider);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final themeColor = Colors.deepOrangeAccent;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface.withOpacity(0.7)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '🎬 动漫高清舱',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface),
        ),
      ),
      body: Stack(
        children: [
          const DynamicBackground(child: SizedBox.expand()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  _buildSearchBar(themeColor),
                  const SizedBox(height: 18),
                  Expanded(
                    child: _buildBodyContent(searchState, history, themeColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: themeColor.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 15),
            textInputAction: TextInputAction.search,
            onSubmitted: _performSearch,
            decoration: InputDecoration(
              hintText: '搜索动漫名称...',
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              prefixIcon: Icon(Icons.search_rounded, color: themeColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(animeSearchProvider.notifier).clearSearch();
                        setState(() {
                          _hasSearched = false;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            ),
            onChanged: (val) {
              setState(() {});
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent(AnimeSearchState state, List<String> history, Color themeColor) {
    if (state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: themeColor),
            const SizedBox(height: 16),
            const Text('正在并发检索动漫源，请稍候...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text('检索出错: ${state.error}', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              style: ElevatedButton.styleFrom(backgroundColor: themeColor),
              child: const Text('重试', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      );
    }

    if (!_hasSearched || state.results.isEmpty) {
      if (state.results.isEmpty && _hasSearched) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sentiment_dissatisfied_rounded, color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              const Text('未找到相关动漫资源，请更换关键词搜索', style: TextStyle(color: Colors.white70)),
            ],
          ),
        );
      }

      // Show search history
      return _buildHistoryView(history);
    }

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final item = state.results[index];
        return _buildAnimeCard(item, themeColor);
      },
    );
  }

  Widget _buildHistoryView(List<String> history) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.live_tv_rounded, color: Colors.deepOrangeAccent.withOpacity(0.3), size: 64),
            const SizedBox(height: 16),
            const Text('全网动漫资源实时抓取播放\n输入你想看的动漫，如“火影”', 
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5)
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('历史搜索', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
            TextButton.icon(
              onPressed: () => ref.read(animeSearchHistoryProvider.notifier).clearHistory(),
              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.white38),
              label: const Text('清空', style: TextStyle(fontSize: 12, color: Colors.white38)),
            )
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: history.map((q) {
            return InkWell(
              onTap: () => _performSearch(q),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(q, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),
            );
          }).toList(),
        )
      ],
    );
  }

  Widget _buildAnimeCard(AnimeSearchItem item, Color themeColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailScreen(
              animeUrl: item.animeUrl,
              animeTitle: item.title,
              coverUrl: item.coverUrl,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.coverUrl != null && item.coverUrl!.isNotEmpty
                        ? Image.network(
                            item.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildPlaceholderCover(),
                          )
                        : _buildPlaceholderCover(),
                    if (item.status != null && item.status!.isNotEmpty)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.status!,
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderCover() {
    return Container(
      color: Colors.white.withOpacity(0.05),
      child: const Center(
        child: Icon(Icons.live_tv_rounded, color: Colors.white24, size: 36),
      ),
    );
  }
}
