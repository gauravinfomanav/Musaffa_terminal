import 'package:musaffa_terminal/models/institutional_investor_model.dart';
import 'package:musaffa_terminal/services/finnhub/finnhub_api_client.dart';

class InstitutionalInvestorService {
  InstitutionalInvestorService({FinnhubApiClient? client})
      : _client = client ?? const FinnhubApiClient();

  final FinnhubApiClient _client;

  Future<List<InstitutionalInvestorProfile>> fetchProfiles({
    bool forceRefresh = false,
  }) async {
    final dynamic decoded = await _client.get(
      'institutional/profile',
      cacheKey: 'institutional/profile:all',
      forceRefresh: forceRefresh,
    );

    final List<dynamic> rawList = _extractList(decoded, const <String>['data']);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(InstitutionalInvestorProfile.fromJson)
        .where(
          (InstitutionalInvestorProfile item) =>
              item.cik.isNotEmpty && item.manager.isNotEmpty,
        )
        .toList();
  }

  Future<InstitutionalInvestorProfile?> matchProfile(String fundName) async {
    final String needle = _normalizeName(fundName);
    if (needle.isEmpty) return null;

    final List<InstitutionalInvestorProfile> profiles = await fetchProfiles();
    InstitutionalInvestorProfile? best;
    int bestScore = 0;

    for (final InstitutionalInvestorProfile profile in profiles) {
      final int score = _nameScore(needle, _normalizeName(profile.manager));
      if (score > bestScore) {
        bestScore = score;
        best = profile;
      }
    }

    return bestScore >= 2 ? best : null;
  }

  Future<InstitutionalPortfolioSnapshot?> fetchPortfolio(String cik) async {
    final String normalized = cik.trim();
    if (normalized.isEmpty) return null;

    final DateTime to = DateTime.now();
    final DateTime from = DateTime(to.year - 1, to.month, to.day);
    final String fromStr = _isoDate(from);
    final String toStr = _isoDate(to);

    final dynamic decoded = await _client.get(
      'institutional/portfolio',
      queryParameters: <String, String>{
        'cik': normalized,
        'from': fromStr,
        'to': toStr,
      },
      cacheKey: 'institutional/portfolio:$normalized:$fromStr:$toStr',
    );

    final List<dynamic> groups = _extractList(decoded, const <String>['data']);
    InstitutionalPortfolioSnapshot? latest;

    for (final dynamic group in groups) {
      if (group is! Map<String, dynamic>) continue;
      final List<dynamic> rawHoldings =
          _extractList(group, const <String>['portfolio', 'data']);
      final List<InstitutionalHolding> holdings = rawHoldings
          .whereType<Map<String, dynamic>>()
          .map(InstitutionalHolding.fromJson)
          .where((InstitutionalHolding item) => item.symbol.isNotEmpty)
          .toList()
        ..sort(
          (InstitutionalHolding a, InstitutionalHolding b) =>
              b.value.compareTo(a.value),
        );
      if (holdings.isEmpty) continue;

      final InstitutionalPortfolioSnapshot snapshot =
          InstitutionalPortfolioSnapshot(
        reportDate: _date(group['reportDate']),
        filingDate: _date(group['filingDate']),
        holdings: holdings,
      );
      if (latest == null ||
          (snapshot.reportDate != null &&
              (latest.reportDate == null ||
                  snapshot.reportDate!.isAfter(latest.reportDate!)))) {
        latest = snapshot;
      }
    }

    return latest;
  }

  List<dynamic> _extractList(dynamic decoded, List<String> keys) {
    if (decoded is List<dynamic>) return decoded;
    if (decoded is Map<String, dynamic>) {
      for (final String key in keys) {
        final dynamic value = decoded[key];
        if (value is List<dynamic>) return value;
      }
      for (final dynamic value in decoded.values) {
        if (value is List<dynamic>) return value;
      }
    }
    return <dynamic>[];
  }

  static String _normalizeName(String raw) {
    return raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(
          RegExp(
            r'\b(the|inc|incorporated|corp|corporation|llc|lp|llp|ltd|limited|co|company|group|holdings|holding|management|advisors?|partners?|capital|asset|investments?|investors?|trust|plc|ag|nv|sa|n a)\b',
          ),
          ' ',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static int _nameScore(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 8;
    if (a.contains(b) || b.contains(a)) return 6;

    final Set<String> aTokens =
        a.split(' ').where((String t) => t.length >= 3).toSet();
    final Set<String> bTokens =
        b.split(' ').where((String t) => t.length >= 3).toSet();
    if (aTokens.isEmpty || bTokens.isEmpty) return 0;
    return aTokens.intersection(bTokens).length;
  }

  static String _isoDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    final String raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
