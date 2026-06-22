class AnimeSearchItem {
  final String animeId;
  final String title;
  final String? coverUrl;
  final String animeUrl;
  final String? status;

  AnimeSearchItem({
    required this.animeId,
    required this.title,
    this.coverUrl,
    required this.animeUrl,
    this.status,
  });

  factory AnimeSearchItem.fromJson(Map<String, dynamic> json) {
    return AnimeSearchItem(
      animeId: json['anime_id'] as String,
      title: json['title'] as String,
      coverUrl: json['cover_url'] as String?,
      animeUrl: json['anime_url'] as String,
      status: json['status'] as String?,
    );
  }
}

class AnimeEpisode {
  final String title;
  final String episodeUrl;
  final int index;

  AnimeEpisode({
    required this.title,
    required this.episodeUrl,
    required this.index,
  });

  factory AnimeEpisode.fromJson(Map<String, dynamic> json) {
    return AnimeEpisode(
      title: json['title'] as String,
      episodeUrl: json['episode_url'] as String,
      index: json['index'] as int,
    );
  }
}

class AnimeDetail {
  final String animeId;
  final String title;
  final String? coverUrl;
  final String animeUrl;
  final String? description;
  final String? genres;
  final List<AnimeEpisode> episodes;

  AnimeDetail({
    required this.animeId,
    required this.title,
    this.coverUrl,
    required this.animeUrl,
    this.description,
    this.genres,
    required this.episodes,
  });

  factory AnimeDetail.fromJson(Map<String, dynamic> json) {
    final episodesList = json['episodes'] as List<dynamic>? ?? [];
    return AnimeDetail(
      animeId: json['anime_id'] as String,
      title: json['title'] as String,
      coverUrl: json['cover_url'] as String?,
      animeUrl: json['anime_url'] as String,
      description: json['description'] as String?,
      genres: json['genres'] as String?,
      episodes: episodesList
          .map((e) => AnimeEpisode.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AnimeProgress {
  final String id;
  final String userId;
  final String animeId;
  final String animeTitle;
  final String? coverUrl;
  final String animeUrl;
  final String? lastWatchEpisodeTitle;
  final String? lastWatchEpisodeUrl;
  final int lastWatchEpisodeIndex;
  final int lastWatchPosition;
  final bool isCompleted;
  final bool inFavorites;
  final String updatedAt;

  AnimeProgress({
    required this.id,
    required this.userId,
    required this.animeId,
    required this.animeTitle,
    this.coverUrl,
    required this.animeUrl,
    this.lastWatchEpisodeTitle,
    this.lastWatchEpisodeUrl,
    required this.lastWatchEpisodeIndex,
    required this.lastWatchPosition,
    required this.isCompleted,
    required this.inFavorites,
    required this.updatedAt,
  });

  factory AnimeProgress.fromJson(Map<String, dynamic> json) {
    return AnimeProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      animeId: json['anime_id'] as String,
      animeTitle: json['anime_title'] as String,
      coverUrl: json['cover_url'] as String?,
      animeUrl: json['anime_url'] as String,
      lastWatchEpisodeTitle: json['last_watch_episode_title'] as String?,
      lastWatchEpisodeUrl: json['last_watch_episode_url'] as String?,
      lastWatchEpisodeIndex: json['last_watch_episode_index'] as int? ?? 0,
      lastWatchPosition: json['last_watch_position'] as int? ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      inFavorites: json['in_favorites'] as bool? ?? false,
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}
