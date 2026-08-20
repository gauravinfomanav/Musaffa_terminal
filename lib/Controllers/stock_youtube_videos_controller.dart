import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:musaffa_terminal/models/youtube_videos.dart';
import 'package:musaffa_terminal/web_service.dart';

class StockYouTubeVideosController extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _loadedQuery;
  String? _searchSummary;
  String? _qualitySubtitle;
  List<StockYouTubeVideo> _videos = const [];
  String? _message;
  bool _featureDisabled = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get searchSummary => _searchSummary;
  String? get qualitySubtitle => _qualitySubtitle;
  List<StockYouTubeVideo> get videos => _videos;
  String? get message => _message;
  bool get featureDisabled => _featureDisabled;
  bool get hasVideos => _videos.isNotEmpty;

  Future<void> load({
    required String ticker,
    String? companyName,
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final normalizedTicker = ticker.trim();
    if (normalizedTicker.isEmpty) return;

    if (!forceRefresh &&
        _loadedQuery == normalizedTicker &&
        (_videos.isNotEmpty || _message != null || _error != null)) {
      return;
    }

    _loadedQuery = normalizedTicker;
    _isLoading = true;
    _error = null;
    _featureDisabled = false;
    notifyListeners();

    try {
      final tickerResult =
          await _fetchVideos(normalizedTicker, limit: limit);
      if (tickerResult.featureDisabled) {
        _featureDisabled = true;
        _videos = const [];
        return;
      }

      if (tickerResult.videos.isNotEmpty) {
        _applyResult(tickerResult);
        return;
      }

      final fallbackName = companyName?.trim();
      if (fallbackName != null &&
          fallbackName.isNotEmpty &&
          fallbackName.toUpperCase() != normalizedTicker.toUpperCase()) {
        final nameResult = await _fetchVideos(fallbackName, limit: limit);
        if (nameResult.featureDisabled) {
          _featureDisabled = true;
          _videos = const [];
          return;
        }
        _applyResult(nameResult);
        return;
      }

      _applyResult(tickerResult);
    } catch (e) {
      debugPrint('StockYouTubeVideosController.load error: $e');
      _error = 'Unable to load analysis videos';
      _videos = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyResult(_YouTubeFetchResult result) {
    _videos = result.videos;
    _searchSummary = result.searchSummary;
    _qualitySubtitle = result.qualitySubtitle;
    _message = result.message;
    _error = result.error;
  }

  Future<_YouTubeFetchResult> _fetchVideos(
    String query, {
    required int limit,
  }) async {
    final response = await WebService.callApi(
      method: HttpMethod.GET,
      path: ['stocks', query, 'youtube-videos'],
      params: {'limit': limit.toString()},
    );

    if (response.statusCode == 403) {
      return const _YouTubeFetchResult(featureDisabled: true);
    }

    if (response.status != ApiStatus.SUCCESS || response.data == null) {
      return _YouTubeFetchResult(
        error: response.errorMessage ?? 'Failed to fetch analysis videos',
      );
    }

    final jsonData = jsonDecode(response.data!);
    if (jsonData is! Map<String, dynamic>) {
      return const _YouTubeFetchResult(error: 'Invalid response format');
    }

    final parsed = YouTubeVideosResponse.fromJson(jsonData);
    if (parsed.status != 'success') {
      return _YouTubeFetchResult(
        error: parsed.message ?? 'Failed to fetch analysis videos',
      );
    }

    final data = parsed.data;
    return _YouTubeFetchResult(
      videos: data?.videos ?? const [],
      searchSummary: data?.searchSummary,
      qualitySubtitle: data?.quality?.subtitle,
      message: parsed.message,
    );
  }
}

class _YouTubeFetchResult {
  const _YouTubeFetchResult({
    this.videos = const [],
    this.searchSummary,
    this.qualitySubtitle,
    this.message,
    this.error,
    this.featureDisabled = false,
  });

  final List<StockYouTubeVideo> videos;
  final String? searchSummary;
  final String? qualitySubtitle;
  final String? message;
  final String? error;
  final bool featureDisabled;
}
