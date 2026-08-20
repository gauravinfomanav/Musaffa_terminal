class YouTubeVideosResponse {
  YouTubeVideosResponse({
    required this.status,
    this.data,
    this.message,
    this.meta,
  });

  final String status;
  final YouTubeVideosData? data;
  final String? message;
  final YouTubeVideosMeta? meta;

  factory YouTubeVideosResponse.fromJson(Map<String, dynamic> json) {
    return YouTubeVideosResponse(
      status: json['status']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? YouTubeVideosData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message']?.toString(),
      meta: json['meta'] is Map<String, dynamic>
          ? YouTubeVideosMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }
}

class YouTubeVideosData {
  YouTubeVideosData({
    required this.query,
    this.searchQuery,
    this.searchQueries = const [],
    this.quality,
    required this.videos,
    required this.count,
    required this.cached,
  });

  final String query;
  final String? searchQuery;
  final List<String> searchQueries;
  final YouTubeVideosQuality? quality;
  final List<StockYouTubeVideo> videos;
  final int count;
  final bool cached;

  /// Display text for what was searched (prefers multi-query list from API).
  String get searchSummary {
    if (searchQueries.isNotEmpty) {
      return searchQueries.join(' · ');
    }
    return searchQuery?.trim() ?? '';
  }

  factory YouTubeVideosData.fromJson(Map<String, dynamic> json) {
    final rawVideos = json['videos'];
    final rawQueries = json['searchQueries'];
    return YouTubeVideosData(
      query: json['query']?.toString() ?? '',
      searchQuery: json['searchQuery']?.toString(),
      searchQueries: rawQueries is List
          ? rawQueries
              .map((q) => q.toString().trim())
              .where((q) => q.isNotEmpty)
              .toList()
          : const [],
      quality: json['quality'] is Map<String, dynamic>
          ? YouTubeVideosQuality.fromJson(
              json['quality'] as Map<String, dynamic>,
            )
          : null,
      videos: rawVideos is List
          ? rawVideos
              .whereType<Map<String, dynamic>>()
              .map(StockYouTubeVideo.fromJson)
              .toList()
          : const [],
      count: json['count'] is num ? (json['count'] as num).toInt() : 0,
      cached: json['cached'] == true,
    );
  }
}

class YouTubeVideosQuality {
  YouTubeVideosQuality({
    this.minViewsApplied,
    this.candidatesScanned,
  });

  final int? minViewsApplied;
  final int? candidatesScanned;

  factory YouTubeVideosQuality.fromJson(Map<String, dynamic> json) {
    return YouTubeVideosQuality(
      minViewsApplied: json['minViewsApplied'] is num
          ? (json['minViewsApplied'] as num).toInt()
          : null,
      candidatesScanned: json['candidatesScanned'] is num
          ? (json['candidatesScanned'] as num).toInt()
          : null,
    );
  }

  String? get subtitle {
    final parts = <String>['Ranked by views'];
    if (minViewsApplied != null && minViewsApplied! > 0) {
      parts.add('${_formatCount(minViewsApplied!)}+ min views');
    }
    if (candidatesScanned != null && candidatesScanned! > 0) {
      parts.add('${candidatesScanned!} scanned');
    }
    return parts.length > 1 ? parts.join(' · ') : null;
  }

  static String _formatCount(int count) {
    if (count >= 1000) {
      final value = count / 1000;
      return value >= 10
          ? '${value.toStringAsFixed(0)}K'
          : '${value.toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class StockYouTubeVideo {
  StockYouTubeVideo({
    required this.title,
    this.channel,
    this.channelUrl,
    required this.videoUrl,
    this.thumbnail,
    this.publishedAt,
    this.viewCount,
    this.durationSeconds,
    this.duration,
  });

  final String title;
  final String? channel;
  final String? channelUrl;
  final String videoUrl;
  final String? thumbnail;
  final String? publishedAt;
  final int? viewCount;
  final int? durationSeconds;
  final String? duration;

  factory StockYouTubeVideo.fromJson(Map<String, dynamic> json) {
    return StockYouTubeVideo(
      title: json['title']?.toString() ?? '',
      channel: json['channel']?.toString(),
      channelUrl: json['channelUrl']?.toString(),
      videoUrl: json['videoUrl']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString(),
      publishedAt: json['publishedAt']?.toString(),
      viewCount: json['viewCount'] is num
          ? (json['viewCount'] as num).toInt()
          : null,
      durationSeconds: json['durationSeconds'] is num
          ? (json['durationSeconds'] as num).toInt()
          : null,
      duration: json['duration']?.toString(),
    );
  }
}

class YouTubeVideosMeta {
  YouTubeVideosMeta({
    required this.defaultLimit,
    required this.maxLimit,
  });

  final int defaultLimit;
  final int maxLimit;

  factory YouTubeVideosMeta.fromJson(Map<String, dynamic> json) {
    return YouTubeVideosMeta(
      defaultLimit: json['defaultLimit'] is num
          ? (json['defaultLimit'] as num).toInt()
          : 10,
      maxLimit: json['maxLimit'] is num
          ? (json['maxLimit'] as num).toInt()
          : 20,
    );
  }
}
