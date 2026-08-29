class StockTwitterPostsResponse {
  StockTwitterPostsResponse({
    required this.status,
    this.data,
    this.message,
  });

  final String status;
  final StockTwitterPostsData? data;
  final String? message;

  factory StockTwitterPostsResponse.fromJson(Map<String, dynamic> json) {
    return StockTwitterPostsResponse(
      status: (json['status'] as String?) ?? 'error',
      data: json['data'] is Map<String, dynamic>
          ? StockTwitterPostsData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
    );
  }
}

class StockTwitterPostsData {
  StockTwitterPostsData({
    this.tweets = const [],
    this.searchSummary,
  });

  final List<StockTweet> tweets;
  final String? searchSummary;

  factory StockTwitterPostsData.fromJson(Map<String, dynamic> json) {
    final raw = json['tweets'] ?? json['posts'] ?? json['items'];
    final list = raw is List ? raw : const [];
    return StockTwitterPostsData(
      tweets: list
          .whereType<Map>()
          .map((e) => StockTweet.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      searchSummary: json['searchSummary'] as String?,
    );
  }
}

class StockTweet {
  StockTweet({
    required this.id,
    required this.authorName,
    required this.authorHandle,
    required this.text,
    this.avatarUrl,
    this.createdAt,
    this.likeCount = 0,
    this.repostCount = 0,
    this.replyCount = 0,
    this.url,
    this.verified = false,
  });

  final String id;
  final String authorName;
  final String authorHandle;
  final String text;
  final String? avatarUrl;
  final DateTime? createdAt;
  final int likeCount;
  final int repostCount;
  final int replyCount;
  final String? url;
  final bool verified;

  factory StockTweet.fromJson(Map<String, dynamic> json) {
    final handle = (json['authorHandle'] ??
            json['handle'] ??
            json['username'] ??
            json['userName'] ??
            '')
        .toString()
        .replaceFirst('@', '');
    final name = (json['authorName'] ??
            json['name'] ??
            json['displayName'] ??
            handle)
        .toString();
    return StockTweet(
      id: (json['id'] ?? json['tweetId'] ?? '').toString(),
      authorName: name.isEmpty ? 'Market Voice' : name,
      authorHandle: handle.isEmpty ? 'market' : handle,
      text: (json['text'] ?? json['content'] ?? json['body'] ?? '').toString(),
      avatarUrl: json['avatarUrl'] as String? ?? json['profileImage'] as String?,
      createdAt: _parseDate(json['createdAt'] ?? json['date'] ?? json['time']),
      likeCount: _int(json['likeCount'] ?? json['likes'] ?? json['favoriteCount']),
      repostCount:
          _int(json['repostCount'] ?? json['retweets'] ?? json['reposts']),
      replyCount: _int(json['replyCount'] ?? json['replies']),
      url: json['url'] as String? ?? json['tweetUrl'] as String?,
      verified: json['verified'] == true || json['isVerified'] == true,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) {
      // seconds vs millis
      final ms = value > 9999999999 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return DateTime.tryParse(value.toString());
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
