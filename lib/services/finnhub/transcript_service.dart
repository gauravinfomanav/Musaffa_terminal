import 'package:musaffa_terminal/models/transcript_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class TranscriptService {
  TranscriptService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<List<TranscriptListItem>> fetchList(String symbol) async {
    final String normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return <TranscriptListItem>[];

    final dynamic decoded = await _client.get(
      'stock/transcripts/list',
      queryParameters: <String, String>{'symbol': normalized},
      cacheKey: 'stock/transcripts/list:$normalized',
    );

    final List<dynamic> raw = decoded is List<dynamic>
        ? decoded
        : decoded is Map<String, dynamic>
            ? (decoded['transcripts'] as List<dynamic>? ??
                decoded['data'] as List<dynamic>? ??
                <dynamic>[])
            : <dynamic>[];

    return raw
        .whereType<Map>()
        .map(
          (Map item) =>
              TranscriptListItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((TranscriptListItem item) => item.id.isNotEmpty)
        .toList();
  }

  Future<TranscriptDetail?> fetchById(String id) async {
    final String transcriptId = id.trim();
    if (transcriptId.isEmpty) return null;

    final dynamic decoded = await _client.get(
      'stock/transcripts',
      queryParameters: <String, String>{'id': transcriptId},
      cacheKey: 'stock/transcripts:$transcriptId',
    );

    if (decoded is! Map<String, dynamic>) return null;
    return TranscriptDetail.fromJson(decoded);
  }
}
