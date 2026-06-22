import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/provider/auth_provider.dart';
import '../model/anime.dart';

class AnimeService {
  final ApiClient _apiClient;

  AnimeService(this._apiClient);

  /// 1. Search anime by keyword
  Future<List<AnimeSearchItem>> searchAnime(String q) async {
    try {
      final response = await _apiClient.instance.get(
        '/anime/search',
        queryParameters: {'q': q},
      );
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> list = response.data;
        return list.map((item) => AnimeSearchItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("searchAnime error: $e");
      return [];
    }
  }

  /// 2. Get anime details and episode lists
  Future<AnimeDetail?> getAnimeDetail(String url) async {
    try {
      final response = await _apiClient.instance.get(
        '/anime/detail',
        queryParameters: {'url': url},
      );
      if (response.statusCode == 200 && response.data != null) {
        return AnimeDetail.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint("getAnimeDetail error: $e");
      return null;
    }
  }

  /// 3. Resolve direct .m3u8/.mp4 stream play link
  Future<String?> getPlayUrl(String url, String title) async {
    try {
      final response = await _apiClient.instance.get(
        '/anime/play_url',
        queryParameters: {'url': url, 'episode_title': title},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['play_url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint("getPlayUrl error: $e");
      return null;
    }
  }

  /// 4. Get watch history/progress records
  Future<List<AnimeProgress>> getWatchProgress({String? animeId}) async {
    try {
      final response = await _apiClient.instance.get(
        '/anime/progress',
        queryParameters: animeId != null ? {'anime_id': animeId} : null,
      );
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> list = response.data;
        return list.map((item) => AnimeProgress.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("getWatchProgress error: $e");
      return [];
    }
  }

  /// 5. Save/Sync watch progress and playback state
  Future<AnimeProgress?> syncWatchProgress({
    required String animeId,
    required String animeTitle,
    String? coverUrl,
    required String animeUrl,
    required String episodeTitle,
    required String episodeUrl,
    required int episodeIndex,
    required int position,
    bool isCompleted = false,
    bool? inFavorites,
  }) async {
    try {
      final payload = {
        'anime_id': animeId,
        'anime_title': animeTitle,
        'cover_url': coverUrl,
        'anime_url': animeUrl,
        'episode_title': episodeTitle,
        'episode_url': episodeUrl,
        'episode_index': episodeIndex,
        'position': position,
        'is_completed': isCompleted,
        if (inFavorites != null) 'in_favorites': inFavorites,
      };

      final response = await _apiClient.instance.post(
        '/anime/progress',
        data: payload,
      );

      if (response.statusCode == 200 && response.data != null) {
        return AnimeProgress.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint("syncWatchProgress error: $e");
      return null;
    }
  }
}

// Riverpod Provider
final animeServiceProvider = Provider<AnimeService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnimeService(apiClient);
});
