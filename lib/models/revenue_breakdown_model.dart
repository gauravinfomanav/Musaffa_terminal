class RevenueBreakdownItem {
  const RevenueBreakdownItem({
    required this.label,
    required this.revenue,
    this.percentage,
  });

  final String label;
  final num revenue;
  final double? percentage;
}

class RevenueBreakdownSlice {
  const RevenueBreakdownSlice({
    required this.title,
    required this.periodLabel,
    required this.items,
    this.totalRevenue,
    this.unit = 'usd',
  });

  final String title;
  final String periodLabel;
  final List<RevenueBreakdownItem> items;
  final num? totalRevenue;
  final String unit;

  bool get isEmpty => items.isEmpty;

  RevenueBreakdownItem? get largest => items.isEmpty ? null : items.first;

  num get total =>
      totalRevenue ??
      items.fold<num>(0, (num sum, RevenueBreakdownItem item) => sum + item.revenue);
}

class RevenueBreakdownModel {
  const RevenueBreakdownModel({
    this.product,
    this.geography,
  });

  final RevenueBreakdownSlice? product;
  final RevenueBreakdownSlice? geography;

  bool get hasData =>
      (product?.items.isNotEmpty ?? false) ||
      (geography?.items.isNotEmpty ?? false);

  static RevenueBreakdownModel? parse(dynamic decoded) {
    return RevenueBreakdownParser.parse(decoded);
  }
}

class RevenueBreakdownParser {
  RevenueBreakdownParser._();

  static const Set<String> _metaKeys = <String>{
    'period',
    'date',
    'startdate',
    'enddate',
    'symbol',
    'ticker',
    'currency',
    'unit',
    'concept',
    'value',
    'accessnumber',
    'cik',
    'breakdown',
    'revenuedown',
    'revenubreakdown',
  };

  static RevenueBreakdownModel? parse(dynamic decoded) {
    if (decoded is! Map) return null;
    final Map<String, dynamic> root = Map<String, dynamic>.from(decoded);

    final dynamic data = root['data'];
    if (data is List && data.isNotEmpty) {
      final RevenueBreakdownModel? fromFilings = _fromFilingList(data);
      if (fromFilings != null && fromFilings.hasData) return fromFilings;
    }

    final dynamic series = root['series'];
    if (series is Map && series.isNotEmpty) {
      final RevenueBreakdownModel? fromSeries = _fromSeries(series);
      if (fromSeries != null && fromSeries.hasData) return fromSeries;
    }

    return null;
  }

  static RevenueBreakdownModel? _fromFilingList(List<dynamic> data) {
    final List<_CandidateSlice> products = <_CandidateSlice>[];
    final List<_CandidateSlice> geos = <_CandidateSlice>[];

    for (final dynamic raw in data) {
      if (raw is! Map) continue;
      final Map<String, dynamic> item = Map<String, dynamic>.from(raw);
      final dynamic breakdown = item['breakdown'];
      if (breakdown is Map) {
        _collectFromNestedBreakdown(
          Map<String, dynamic>.from(breakdown),
          products,
          geos,
        );
        continue;
      }
      if (item['percent'] is Map || item['actual'] is Map) {
        _collectFromLegacyPercentActual(item, products, geos);
        continue;
      }
      _collectFromFlatMap(item, products, geos);
    }

    return RevenueBreakdownModel(
      product: _pickBest(products, preferDetailed: true),
      geography: _pickBest(geos, preferDetailed: true, preferRicher: true),
    );
  }

  static void _collectFromNestedBreakdown(
    Map<String, dynamic> breakdown,
    List<_CandidateSlice> products,
    List<_CandidateSlice> geos,
  ) {
    final String start = (breakdown['startDate'] ?? '').toString();
    final String end = (breakdown['endDate'] ?? breakdown['period'] ?? '').toString();
    final String periodLabel = _formatPeriod(start, end);
    final String sortKey = end.isNotEmpty ? end : start;
    final num? total = _num(breakdown['value']);
    final String unit = (breakdown['unit'] ?? 'usd').toString();
    final dynamic groups = breakdown['revenueBreakdown'];
    if (groups is! List) return;

    for (final dynamic rawGroup in groups) {
      if (rawGroup is! Map) continue;
      final Map<String, dynamic> group = Map<String, dynamic>.from(rawGroup);
      final String axis = _normalizeAxis(group['axis']?.toString() ?? '');
      if (_isIgnoredAxis(axis)) continue;

      final List<RevenueBreakdownItem> items = _itemsFromAxisData(group['data']);
      if (items.length < 2) continue;

      final _CandidateSlice candidate = _CandidateSlice(
        sortKey: sortKey,
        periodLabel: periodLabel,
        unit: unit,
        totalRevenue: total,
        items: items,
        detailed: items.length >= 3,
        axis: axis,
      );

      if (_isGeographicAxis(axis) || _looksGeographic(items)) {
        geos.add(candidate.copyWith(title: 'Geography'));
      } else if (_isProductAxis(axis)) {
        final bool coarse = _isCoarseProductMix(items);
        products.add(
          candidate.copyWith(
            title: coarse ? 'Products vs services' : 'Product mix',
            detailed: !coarse && items.length >= 3,
          ),
        );
      } else {
        products.add(candidate.copyWith(title: 'Segments'));
      }
    }
  }

  static void _collectFromLegacyPercentActual(
    Map<String, dynamic> item,
    List<_CandidateSlice> products,
    List<_CandidateSlice> geos,
  ) {
    final String period = (item['period'] ?? item['date'] ?? '').toString();
    final Map<String, dynamic> actual = _asMap(item['actual']) ?? const <String, dynamic>{};
    final Map<String, dynamic> percent = _asMap(item['percent']) ?? const <String, dynamic>{};

    void addBucket(String key, String title, List<_CandidateSlice> sink) {
      final Map<String, dynamic>? values = _asMap(actual[key]) ?? _asMap(percent[key]);
      if (values == null) return;
      final Map<String, dynamic>? shares = _asMap(percent[key]);
      final List<RevenueBreakdownItem> items = <RevenueBreakdownItem>[];
      for (final MapEntry<String, dynamic> entry in values.entries) {
        final num? revenue = _num(entry.value);
        if (revenue == null || revenue <= 0) continue;
        final num? share = shares == null ? null : _num(shares[entry.key]);
        items.add(
          RevenueBreakdownItem(
            label: entry.key,
            revenue: revenue,
            percentage: share?.toDouble(),
          ),
        );
      }
      if (items.length < 2) return;
      items.sort(
        (RevenueBreakdownItem a, RevenueBreakdownItem b) =>
            b.revenue.compareTo(a.revenue),
      );
      sink.add(
        _CandidateSlice(
          title: title,
          sortKey: period,
          periodLabel: _formatPeriod('', period),
          items: items,
          detailed: items.length >= 3,
        ),
      );
    }

    addBucket('product', 'Product mix', products);
    addBucket('geographic', 'Geography', geos);
    addBucket('geography', 'Geography', geos);
  }

  static void _collectFromFlatMap(
    Map<String, dynamic> item,
    List<_CandidateSlice> products,
    List<_CandidateSlice> geos,
  ) {
    final String period =
        (item['period'] ?? item['date'] ?? item['endDate'] ?? '').toString();
    final List<RevenueBreakdownItem> items = <RevenueBreakdownItem>[];
    for (final MapEntry<String, dynamic> entry in item.entries) {
      if (_metaKeys.contains(entry.key.toLowerCase())) continue;
      if (entry.value is Map || entry.value is List) continue;
      final num? revenue = _num(entry.value);
      if (revenue == null || revenue <= 0) continue;
      items.add(RevenueBreakdownItem(label: entry.key, revenue: revenue));
    }
    if (items.length < 2) return;
    items.sort(
      (RevenueBreakdownItem a, RevenueBreakdownItem b) =>
          b.revenue.compareTo(a.revenue),
    );
    final _CandidateSlice candidate = _CandidateSlice(
      sortKey: period,
      periodLabel: _formatPeriod('', period),
      items: _withShares(items),
      detailed: items.length >= 3,
    );
    if (_looksGeographic(items)) {
      geos.add(candidate.copyWith(title: 'Geography'));
    } else {
      products.add(candidate.copyWith(title: 'Product mix'));
    }
  }

  static RevenueBreakdownModel? _fromSeries(Map<dynamic, dynamic> series) {
    final List<String> periods = series.keys.map((dynamic e) => e.toString()).toList()
      ..sort();
    if (periods.isEmpty) return null;
    final String period = periods.last;
    final dynamic bucket = series[period];
    if (bucket is! Map) return null;
    final List<_CandidateSlice> products = <_CandidateSlice>[];
    final List<_CandidateSlice> geos = <_CandidateSlice>[];
    _collectFromFlatMap(
      <String, dynamic>{'period': period, ...Map<String, dynamic>.from(bucket)},
      products,
      geos,
    );
    return RevenueBreakdownModel(
      product: _pickBest(products, preferDetailed: true),
      geography: _pickBest(geos, preferDetailed: true, preferRicher: true),
    );
  }

  static RevenueBreakdownSlice? _pickBest(
    List<_CandidateSlice> candidates, {
    required bool preferDetailed,
    bool preferRicher = false,
  }) {
    if (candidates.isEmpty) return null;
    final List<_CandidateSlice> pool = preferDetailed
        ? candidates.where((_CandidateSlice c) => c.detailed).toList()
        : candidates;
    final List<_CandidateSlice> usable = pool.isNotEmpty ? pool : candidates;
    usable.sort((_CandidateSlice a, _CandidateSlice b) {
      if (preferRicher) {
        final int byCount = b.items.length.compareTo(a.items.length);
        if (byCount != 0) return byCount;
      }
      final int byDate = b.sortKey.compareTo(a.sortKey);
      if (byDate != 0) return byDate;
      return b.items.length.compareTo(a.items.length);
    });
    final _CandidateSlice chosen = usable.first;
    return RevenueBreakdownSlice(
      title: chosen.title,
      periodLabel: chosen.periodLabel,
      items: _withShares(chosen.items, total: chosen.totalRevenue),
      totalRevenue: chosen.totalRevenue,
      unit: chosen.unit,
    );
  }

  static List<RevenueBreakdownItem> _itemsFromAxisData(dynamic raw) {
    if (raw is! List) return <RevenueBreakdownItem>[];
    final List<RevenueBreakdownItem> items = <RevenueBreakdownItem>[];
    for (final dynamic row in raw) {
      if (row is! Map) continue;
      final Map<String, dynamic> map = Map<String, dynamic>.from(row);
      final String label = (map['label'] ?? map['name'] ?? '').toString().trim();
      if (label.isEmpty) continue;
      final num? revenue = _num(map['value'] ?? map['revenue']);
      if (revenue == null || revenue <= 0) continue;
      items.add(
        RevenueBreakdownItem(
          label: label,
          revenue: revenue,
          percentage: _num(map['percentage'] ?? map['percent'])?.toDouble(),
        ),
      );
    }
    items.sort(
      (RevenueBreakdownItem a, RevenueBreakdownItem b) =>
          b.revenue.compareTo(a.revenue),
    );
    return items;
  }

  static List<RevenueBreakdownItem> _withShares(
    List<RevenueBreakdownItem> items, {
    num? total,
  }) {
    final num sum = total != null && total > 0
        ? total
        : items.fold<num>(0, (num acc, RevenueBreakdownItem i) => acc + i.revenue);
    if (sum <= 0) return items;
    return items
        .map(
          (RevenueBreakdownItem item) => RevenueBreakdownItem(
            label: item.label,
            revenue: item.revenue,
            percentage: item.percentage ?? (item.revenue / sum) * 100,
          ),
        )
        .toList();
  }

  static String _normalizeAxis(String axis) {
    return axis.toLowerCase().replaceAll(':', '_').replaceAll('-', '_');
  }

  static bool _isIgnoredAxis(String axis) {
    return axis.contains('consolidation');
  }

  static bool _isProductAxis(String axis) {
    return axis.contains('product') || axis.contains('service');
  }

  static bool _isGeographicAxis(String axis) {
    return axis.contains('geograph') ||
        axis.contains('region') ||
        axis.contains('country');
  }

  static bool _looksGeographic(List<RevenueBreakdownItem> items) {
    const List<String> markers = <String>[
      'americas',
      'europe',
      'greater china',
      'china',
      'japan',
      'asia pacific',
      'rest of asia',
      'united states',
      'u.s.',
      'u.s',
      'usa',
      'emea',
      'latam',
      'north america',
      'south america',
      'middle east',
      'africa',
      'other countries',
      'rest of world',
      'rest of the world',
    ];
    int hits = 0;
    for (final RevenueBreakdownItem item in items) {
      final String label = item.label.toLowerCase();
      if (markers.any(label.contains)) hits += 1;
    }
    return hits >= 2;
  }

  static bool _isCoarseProductMix(List<RevenueBreakdownItem> items) {
    if (items.length != 2) return false;
    final Set<String> labels =
        items.map((RevenueBreakdownItem e) => e.label.toLowerCase()).toSet();
    return labels.contains('products') && labels.contains('services');
  }

  static String _formatPeriod(String startRaw, String endRaw) {
    final DateTime? start = DateTime.tryParse(startRaw);
    final DateTime? end = DateTime.tryParse(endRaw);
    if (start != null && end != null) {
      return '${_shortDate(start)} – ${_shortDate(end)}';
    }
    if (end != null) return _shortDate(end);
    if (start != null) return _shortDate(start);
    if (endRaw.trim().isNotEmpty) return endRaw.trim();
    return '--';
  }

  static String _shortDate(DateTime date) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static num? _num(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }
}

class _CandidateSlice {
  const _CandidateSlice({
    required this.sortKey,
    required this.periodLabel,
    required this.items,
    this.title = '',
    this.unit = 'usd',
    this.totalRevenue,
    this.detailed = false,
    this.axis = '',
  });

  final String title;
  final String sortKey;
  final String periodLabel;
  final String unit;
  final num? totalRevenue;
  final List<RevenueBreakdownItem> items;
  final bool detailed;
  final String axis;

  _CandidateSlice copyWith({
    String? title,
    bool? detailed,
  }) {
    return _CandidateSlice(
      title: title ?? this.title,
      sortKey: sortKey,
      periodLabel: periodLabel,
      unit: unit,
      totalRevenue: totalRevenue,
      items: items,
      detailed: detailed ?? this.detailed,
      axis: axis,
    );
  }
}
