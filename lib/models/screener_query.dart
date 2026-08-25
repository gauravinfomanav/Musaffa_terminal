enum ScreenerQueryFieldKind { number, keyword }

enum ScreenerQueryValueScale { none, compact, millions, percent }

enum ScreenerQueryExpect { field, operator, value }

class ScreenerQueryOption {
  final String value;
  final String label;

  const ScreenerQueryOption(this.value, this.label);
}

class ScreenerQueryOperator {
  final String id;
  final String symbol;
  final String typesense;
  final String label;
  final bool forNumber;
  final bool forKeyword;

  const ScreenerQueryOperator({
    required this.id,
    required this.symbol,
    required this.typesense,
    required this.label,
    this.forNumber = true,
    this.forKeyword = true,
  });
}

class ScreenerQueryField {
  final String id;
  final String label;
  final String typesenseField;
  final String category;
  final ScreenerQueryFieldKind kind;
  final List<String> aliases;
  final String? unitHint;
  final ScreenerQueryValueScale scale;
  final List<ScreenerQueryOption> options;

  const ScreenerQueryField({
    required this.id,
    required this.label,
    required this.typesenseField,
    required this.category,
    required this.kind,
    this.aliases = const [],
    this.unitHint,
    this.scale = ScreenerQueryValueScale.none,
    this.options = const [],
  });

  bool get isKeyword => kind == ScreenerQueryFieldKind.keyword;

  List<ScreenerQueryOperator> get operators => ScreenerQueryOperators.forKind(kind);

  bool matches(String query) {
    final q = _norm(query);
    if (q.isEmpty) return true;
    if (_norm(id).contains(q)) return true;
    if (_norm(label).contains(q)) return true;
    if (_norm(typesenseField).contains(q)) return true;
    for (final alias in aliases) {
      if (_norm(alias).contains(q)) return true;
    }
    return false;
  }

  int matchScore(String query) {
    final q = _norm(query);
    if (q.isEmpty) return 1;
    final nid = _norm(id);
    final nlabel = _norm(label);
    if (nid == q || nlabel == q || _norm(typesenseField) == q) return 100;
    if (aliases.any((a) => _norm(a) == q)) return 90;
    if (nid.startsWith(q) || nlabel.startsWith(q)) return 80;
    if (aliases.any((a) => _norm(a).startsWith(q))) return 70;
    if (matches(query)) return 40;
    return 0;
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class ScreenerQueryOperators {
  static const eq = ScreenerQueryOperator(
    id: 'eq',
    symbol: '=',
    typesense: ':=',
    label: 'Equals',
  );
  static const neq = ScreenerQueryOperator(
    id: 'neq',
    symbol: '!=',
    typesense: ':!=',
    label: 'Not equal',
  );
  static const gt = ScreenerQueryOperator(
    id: 'gt',
    symbol: '>',
    typesense: ':>',
    label: 'Greater than',
    forKeyword: false,
  );
  static const gte = ScreenerQueryOperator(
    id: 'gte',
    symbol: '>=',
    typesense: ':>=',
    label: 'Greater or equal',
    forKeyword: false,
  );
  static const lt = ScreenerQueryOperator(
    id: 'lt',
    symbol: '<',
    typesense: ':<',
    label: 'Less than',
    forKeyword: false,
  );
  static const lte = ScreenerQueryOperator(
    id: 'lte',
    symbol: '<=',
    typesense: ':<=',
    label: 'Less or equal',
    forKeyword: false,
  );
  static const between = ScreenerQueryOperator(
    id: 'between',
    symbol: 'between',
    typesense: 'between',
    label: 'Between (min..max)',
    forKeyword: false,
  );
  static const inList = ScreenerQueryOperator(
    id: 'in',
    symbol: 'in',
    typesense: 'in',
    label: 'In list',
    forNumber: false,
  );

  static const all = [eq, neq, gt, gte, lt, lte, between, inList];

  static List<ScreenerQueryOperator> forKind(ScreenerQueryFieldKind kind) {
    if (kind == ScreenerQueryFieldKind.number) {
      return all.where((o) => o.forNumber).toList();
    }
    return all.where((o) => o.forKeyword).toList();
  }

  static ScreenerQueryOperator? parse(String raw) {
    final t = raw.trim().toLowerCase();
    for (final op in all) {
      if (op.symbol.toLowerCase() == t || op.id == t) return op;
    }
    if (t == '==' || t == ':') return eq;
    return null;
  }
}

class ScreenerQueryClause {
  final ScreenerQueryField field;
  final ScreenerQueryOperator operator;
  final String rawValue;

  const ScreenerQueryClause({
    required this.field,
    required this.operator,
    required this.rawValue,
  });

  String get display => '${field.id} ${operator.symbol} $rawValue';

  Map<String, dynamic> toJson() => {
        'id': field.id,
        'op': operator.id,
        'value': rawValue,
      };

  static ScreenerQueryClause? fromJson(Map<String, dynamic> json) {
    final field = ScreenerQueryCatalog.byId(json['id']?.toString() ?? '');
    final op = ScreenerQueryOperators.parse(json['op']?.toString() ?? '');
    final value = json['value']?.toString();
    if (field == null || op == null || value == null || value.isEmpty) {
      return null;
    }
    return ScreenerQueryClause(field: field, operator: op, rawValue: value);
  }

  String toTypesense({List<String> Function(String sector)? mapSector}) {
    final ts = field.typesenseField;
    if (operator.id == 'between') {
      final bounds = _splitBetween(rawValue);
      if (bounds == null) return '';
      final min = _typedValue(bounds.$1);
      final max = _typedValue(bounds.$2);
      return '$ts:>=$min&&$ts:<=$max';
    }
    if (operator.id == 'in') {
      final values = rawValue
          .split(RegExp(r'[,,]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (ts == 'sector' && mapSector != null) {
        final mapped = <String>[];
        for (final v in values) {
          mapped.addAll(mapSector(v));
        }
        final quoted = mapped.map(_quote).join(',');
        return '$ts:=[$quoted]';
      }
      return '$ts:=[${values.map(_typedValue).join(',')}]';
    }
    if (ts == 'sector' && mapSector != null && operator.id == 'eq') {
      final mapped = mapSector(rawValue).map(_quote).join(',');
      return '$ts:=[$mapped]';
    }
    return '$ts${operator.typesense}${_typedValue(rawValue)}';
  }

  String _typedValue(String raw) {
    if (field.kind == ScreenerQueryFieldKind.number) {
      return ScreenerQueryValueParser.parse(raw, field.scale);
    }
    return _quote(raw);
  }

  static String _quote(String raw) {
    var v = raw.trim();
    if ((v.startsWith('"') && v.endsWith('"')) ||
        (v.startsWith("'") && v.endsWith("'"))) {
      v = v.substring(1, v.length - 1);
    }
    if (v.startsWith('`') && v.endsWith('`')) return v;
    return '`$v`';
  }

  static (String, String)? _splitBetween(String raw) {
    final t = raw.trim();
    if (t.contains('..')) {
      final p = t.split('..');
      if (p.length == 2) return (p[0].trim(), p[1].trim());
    }
    final p = t.split(RegExp(r'[\s,]+')).where((e) => e.isNotEmpty).toList();
    if (p.length >= 2) return (p[0], p[1]);
    return null;
  }
}

class ScreenerQueryValueParser {
  static String parse(String raw, ScreenerQueryValueScale scale) {
    var t = raw.trim();
    if (t.endsWith('%')) t = t.substring(0, t.length - 1).trim();
    t = t.replaceAll(',', '');
    if (t.isEmpty) return '0';

    if (scale == ScreenerQueryValueScale.percent) {
      return _plainNumber(t);
    }

    final suffix = RegExp(r'^(-?\d*\.?\d+)\s*([kKmMbBtT])?$');
    final m = suffix.firstMatch(t);
    if (m == null) return _plainNumber(t);

    final n = double.tryParse(m.group(1)!) ?? 0;
    final s = (m.group(2) ?? '').toLowerCase();
    double multiplier = 1;
    switch (s) {
      case 'k':
        multiplier = 1e3;
        break;
      case 'm':
        multiplier = 1e6;
        break;
      case 'b':
        multiplier = 1e9;
        break;
      case 't':
        multiplier = 1e12;
        break;
    }

    if (scale == ScreenerQueryValueScale.millions) {
      final millions = n * multiplier / 1e6;
      return _fmt(millions);
    }
    if (scale == ScreenerQueryValueScale.compact) {
      return _fmt(n * (s.isEmpty ? 1 : multiplier));
    }
    return _fmt(n * (s.isEmpty ? 1 : multiplier));
  }

  static String _plainNumber(String t) {
    final n = double.tryParse(t);
    if (n == null) return t;
    return _fmt(n);
  }

  static String _fmt(double n) {
    if (n == n.roundToDouble()) return n.round().toString();
    return n.toString();
  }
}

class ScreenerQuerySuggestion {
  final String title;
  final String subtitle;
  final String insert;
  final ScreenerQuerySuggestionKind kind;

  const ScreenerQuerySuggestion({
    required this.title,
    required this.subtitle,
    required this.insert,
    required this.kind,
  });
}

enum ScreenerQuerySuggestionKind { field, operator, value, connector }

class ScreenerQueryParseResult {
  final List<ScreenerQueryClause> clauses;
  final String remainder;
  final ScreenerQueryExpect expect;
  final ScreenerQueryField? activeField;
  final ScreenerQueryOperator? activeOperator;

  const ScreenerQueryParseResult({
    required this.clauses,
    required this.remainder,
    required this.expect,
    this.activeField,
    this.activeOperator,
  });
}

class ScreenerQueryParser {
  static final _tokenPattern = RegExp(
    r'>=|<=|!=|==|&&|\|\||>|<|=|:|'
    r'\bAND\b|\band\b|\bOR\b|\bor\b|\bbetween\b|\bBETWEEN\b|\bin\b|\bIN\b|'
    r'"[^"]*"|'
    r"'[^']*'|"
    r'`[^`]*`|'
    r'[A-Za-z_][A-Za-z0-9_]*|'
    r'-?\d[\d._]*[kKmMbBtT%]?',
  );

  static ScreenerQueryParseResult parse(
    String input, {
    bool closeValue = false,
  }) {
    final clauses = <ScreenerQueryClause>[];
    final tokens = _tokenize(input);
    var i = 0;
    ScreenerQueryField? field;
    ScreenerQueryOperator? op;

    while (i < tokens.length) {
      final token = tokens[i];
      if (field == null) {
        if (_isConnector(token)) {
          i++;
          continue;
        }
        final isLast = i == tokens.length - 1;
        final exactId = ScreenerQueryCatalog.byId(token);
        final match = exactId ?? ScreenerQueryCatalog.resolve(token);
        if (match == null || (isLast && exactId == null)) {
          return ScreenerQueryParseResult(
            clauses: clauses,
            remainder: _remainderFrom(tokens, i),
            expect: ScreenerQueryExpect.field,
          );
        }
        field = match;
        i++;
        continue;
      }
      if (op == null) {
        final parsedOp = ScreenerQueryOperators.parse(token);
        if (parsedOp == null ||
            (field.kind == ScreenerQueryFieldKind.number && !parsedOp.forNumber) ||
            (field.kind == ScreenerQueryFieldKind.keyword && !parsedOp.forKeyword)) {
          return ScreenerQueryParseResult(
            clauses: clauses,
            remainder: _remainderFrom(tokens, i),
            expect: ScreenerQueryExpect.operator,
            activeField: field,
          );
        }
        op = parsedOp;
        i++;
        continue;
      }

      if (op.id == 'between') {
        if (i + 1 >= tokens.length) {
          return ScreenerQueryParseResult(
            clauses: clauses,
            remainder: _remainderFrom(tokens, i),
            expect: ScreenerQueryExpect.value,
            activeField: field,
            activeOperator: op,
          );
        }
        var a = tokens[i];
        var b = tokens[i + 1];
        if (_isConnector(b) && i + 2 < tokens.length) {
          b = tokens[i + 2];
          clauses.add(ScreenerQueryClause(
            field: field,
            operator: op,
            rawValue: '$a..$b',
          ));
          i += 3;
        } else if (a.contains('..')) {
          clauses.add(ScreenerQueryClause(
            field: field,
            operator: op,
            rawValue: a,
          ));
          i += 1;
        } else {
          clauses.add(ScreenerQueryClause(
            field: field,
            operator: op,
            rawValue: '$a..$b',
          ));
          i += 2;
        }
        field = null;
        op = null;
        continue;
      }

      final isLast = i == tokens.length - 1;
      if (isLast && !closeValue) {
        return ScreenerQueryParseResult(
          clauses: clauses,
          remainder: _stripQuotes(token),
          expect: ScreenerQueryExpect.value,
          activeField: field,
          activeOperator: op,
        );
      }

      clauses.add(ScreenerQueryClause(
        field: field,
        operator: op,
        rawValue: _stripQuotes(token),
      ));
      field = null;
      op = null;
      i++;
    }

    if (field != null && op != null) {
      return ScreenerQueryParseResult(
        clauses: clauses,
        remainder: '',
        expect: ScreenerQueryExpect.value,
        activeField: field,
        activeOperator: op,
      );
    }
    if (field != null) {
      return ScreenerQueryParseResult(
        clauses: clauses,
        remainder: '',
        expect: ScreenerQueryExpect.operator,
        activeField: field,
      );
    }
    return ScreenerQueryParseResult(
      clauses: clauses,
      remainder: '',
      expect: ScreenerQueryExpect.field,
    );
  }

  static List<ScreenerQuerySuggestion> suggestions(ScreenerQueryParseResult parsed) {
    final q = parsed.remainder.trim();
    switch (parsed.expect) {
      case ScreenerQueryExpect.field:
        // Don't dump the full catalog on empty focus — wait until the user types.
        if (q.isEmpty || _isConnector(q)) {
          return const [];
        }
        final fields = [...ScreenerQueryCatalog.fields]
          ..sort((a, b) => b.matchScore(q).compareTo(a.matchScore(q)));
        return fields
            .where((f) => f.matchScore(q) > 0)
            .take(40)
            .map(_fieldSuggestion)
            .toList();
      case ScreenerQueryExpect.operator:
        final ops = parsed.activeField?.operators ?? const <ScreenerQueryOperator>[];
        final nq = q.toLowerCase();
        return ops
            .where((o) =>
                nq.isEmpty ||
                o.symbol.toLowerCase().contains(nq) ||
                o.label.toLowerCase().contains(nq))
            .map((o) => ScreenerQuerySuggestion(
                  title: o.symbol,
                  subtitle: o.label,
                  insert: o.symbol,
                  kind: ScreenerQuerySuggestionKind.operator,
                ))
            .toList();
      case ScreenerQueryExpect.value:
        final field = parsed.activeField;
        if (field == null) return const [];
        if (field.options.isNotEmpty) {
          final nq = q.toLowerCase();
          // Wait for typing before listing keyword options (e.g. sectors).
          if (nq.isEmpty) return const [];
          return field.options
              .where((o) =>
                  o.label.toLowerCase().contains(nq) ||
                  o.value.toLowerCase().contains(nq))
              .map((o) => ScreenerQuerySuggestion(
                    title: o.label,
                    subtitle: o.value,
                    insert: o.value,
                    kind: ScreenerQuerySuggestionKind.value,
                  ))
              .toList();
        }
        if (field.options.isEmpty && field.isKeyword) {
          if (q.isEmpty) return const [];
          return [
            ScreenerQuerySuggestion(
              title: q,
              subtitle: field.label,
              insert: q,
              kind: ScreenerQuerySuggestionKind.value,
            ),
          ];
        }
        final hint = field.unitHint ?? 'number';
        if (q.isEmpty) {
          return const [];
        }
        return [
          ScreenerQuerySuggestion(
            title: q,
            subtitle: 'Use $q as ${field.label} · $hint',
            insert: q,
            kind: ScreenerQuerySuggestionKind.value,
          ),
        ];
    }
  }

  static ScreenerQuerySuggestion _fieldSuggestion(ScreenerQueryField f) {
    return ScreenerQuerySuggestion(
      title: f.label,
      subtitle: f.category + (f.unitHint != null ? ' · ${f.unitHint}' : ''),
      insert: f.id,
      kind: ScreenerQuerySuggestionKind.field,
    );
  }

  static List<String> _tokenize(String input) {
    return _tokenPattern.allMatches(input).map((m) => m.group(0)!).toList();
  }

  static bool _isConnector(String token) {
    final t = token.trim().toLowerCase();
    return t == 'and' || t == 'or' || t == '&&' || t == '||';
  }

  static String _remainderFrom(List<String> tokens, int i) {
    return tokens.sublist(i).join(' ');
  }

  static String _stripQuotes(String raw) {
    var v = raw.trim();
    if (v.length >= 2 &&
        ((v.startsWith('"') && v.endsWith('"')) ||
            (v.startsWith("'") && v.endsWith("'")) ||
            (v.startsWith('`') && v.endsWith('`')))) {
      return v.substring(1, v.length - 1);
    }
    return v;
  }
}

class ScreenerQueryKeys {
  static const clauses = '_queryClauses';
  static const text = '_query';
}

class ScreenerQueryCatalog {
  static ScreenerQueryField? byId(String id) {
    final n = ScreenerQueryField._norm(id);
    for (final f in fields) {
      if (ScreenerQueryField._norm(f.id) == n ||
          ScreenerQueryField._norm(f.typesenseField) == n) {
        return f;
      }
    }
    return null;
  }

  static ScreenerQueryField? resolve(String token) {
    final exact = byId(token);
    if (exact != null) return exact;
    final n = ScreenerQueryField._norm(token);
    for (final f in fields) {
      if (f.aliases.any((a) => ScreenerQueryField._norm(a) == n)) return f;
    }
    return null;
  }

  static ScreenerQueryField _n(
    String id,
    String label,
    String ts, {
    required String category,
    List<String> aliases = const [],
    String? unitHint,
    ScreenerQueryValueScale scale = ScreenerQueryValueScale.none,
  }) {
    return ScreenerQueryField(
      id: id,
      label: label,
      typesenseField: ts,
      category: category,
      kind: ScreenerQueryFieldKind.number,
      aliases: aliases,
      unitHint: unitHint,
      scale: scale,
    );
  }

  static ScreenerQueryField _k(
    String id,
    String label,
    String ts, {
    required String category,
    required List<ScreenerQueryOption> options,
    List<String> aliases = const [],
  }) {
    return ScreenerQueryField(
      id: id,
      label: label,
      typesenseField: ts,
      category: category,
      kind: ScreenerQueryFieldKind.keyword,
      aliases: aliases,
      options: options,
    );
  }

  static final fields = <ScreenerQueryField>[
    _k('exchange', 'Exchange', 'exchange',
        category: 'Descriptive',
        aliases: const ['exch'],
        options: const [
          ScreenerQueryOption('NYSE', 'NYSE'),
          ScreenerQueryOption('NASDAQ', 'NASDAQ'),
        ]),
    _k('sector', 'Sector', 'sector',
        category: 'Descriptive',
        // Values match stocks_data.sector (table column) / sector_api_mapping keys.
        options: const [
          ScreenerQueryOption('Technology Services', 'Technology Services'),
          ScreenerQueryOption('Electronic Technology', 'Electronic Technology'),
          ScreenerQueryOption('Technology', 'Technology'),
          ScreenerQueryOption('Finance', 'Finance'),
          ScreenerQueryOption('Financial Services', 'Financial Services'),
          ScreenerQueryOption('Healthcare', 'Healthcare'),
          ScreenerQueryOption('Health Technology', 'Health Technology'),
          ScreenerQueryOption('Health Services', 'Health Services'),
          ScreenerQueryOption('Consumer Cyclical', 'Consumer Cyclical'),
          ScreenerQueryOption('Consumer Services', 'Consumer Services'),
          ScreenerQueryOption('Consumer Durables', 'Consumer Durables'),
          ScreenerQueryOption('Consumer Non-Durables', 'Consumer Non-Durables'),
          ScreenerQueryOption('Consumer Defensive', 'Consumer Defensive'),
          ScreenerQueryOption('Retail Trade', 'Retail Trade'),
          ScreenerQueryOption('Distribution Services', 'Distribution Services'),
          ScreenerQueryOption('Industrials', 'Industrials'),
          ScreenerQueryOption('Producer Manufacturing', 'Producer Manufacturing'),
          ScreenerQueryOption('Industrial Services', 'Industrial Services'),
          ScreenerQueryOption('Commercial Services', 'Commercial Services'),
          ScreenerQueryOption('Transportation', 'Transportation'),
          ScreenerQueryOption('Energy', 'Energy'),
          ScreenerQueryOption('Energy Minerals', 'Energy Minerals'),
          ScreenerQueryOption('Utilities', 'Utilities'),
          ScreenerQueryOption('Real Estate', 'Real Estate'),
          ScreenerQueryOption('Communication Services', 'Communication Services'),
          ScreenerQueryOption('Communications', 'Communications'),
          ScreenerQueryOption('Basic Materials', 'Basic Materials'),
          ScreenerQueryOption('Non-Energy Minerals', 'Non-Energy Minerals'),
          ScreenerQueryOption('Process Industries', 'Process Industries'),
          ScreenerQueryOption('Miscellaneous', 'Miscellaneous'),
        ]),
    _k('currency', 'Currency', 'currency',
        category: 'Descriptive',
        aliases: const ['curr', 'fx'],
        options: const [
          ScreenerQueryOption('USD', 'USD'),
          ScreenerQueryOption('EUR', 'EUR'),
          ScreenerQueryOption('GBP', 'GBP'),
          ScreenerQueryOption('CAD', 'CAD'),
          ScreenerQueryOption('JPY', 'JPY'),
          ScreenerQueryOption('CNY', 'CNY'),
          ScreenerQueryOption('HKD', 'HKD'),
          ScreenerQueryOption('CHF', 'CHF'),
        ]),
    _k('country', 'Country', 'country',
        category: 'Descriptive',
        options: const [
          ScreenerQueryOption('US', 'United States'),
        ]),
    _k('industry', 'Industry', 'industry',
        category: 'Descriptive',
        options: const []),
    _k('marketCapClassification', 'Market Cap Class', 'marketCapClassification',
        category: 'Descriptive',
        aliases: const ['capclass', 'size'],
        options: const [
          ScreenerQueryOption('MEGA_CAP', 'Mega Cap'),
          ScreenerQueryOption('LARGE_CAP', 'Large Cap'),
          ScreenerQueryOption('MID_CAP', 'Mid Cap'),
          ScreenerQueryOption('SMALL_CAP', 'Small Cap'),
          ScreenerQueryOption('MICRO_CAP', 'Micro Cap'),
          ScreenerQueryOption('NANO_CAP', 'Nano Cap'),
        ]),
    _k('shariaCompliance', 'Shariah Compliance', 'sharia_compliance',
        category: 'Descriptive',
        aliases: const ['shariah', 'halal', 'compliance'],
        options: const [
          ScreenerQueryOption('COMPLIANT', 'Compliant'),
          ScreenerQueryOption('NON_COMPLIANT', 'Non-compliant'),
          ScreenerQueryOption('QUESTIONABLE', 'Questionable'),
          ScreenerQueryOption('NOT_UNDER_COVERAGE', 'Not under coverage'),
        ]),
    _n('currentPrice', 'Current Price', 'currentPrice',
        category: 'Descriptive',
        aliases: const ['price', 'curr', 'px'],
        unitHint: 'USD'),
    _n('usdMarketCap', 'Market Cap', 'usdMarketCap',
        category: 'Descriptive',
        aliases: const ['marketCap', 'mcap', 'marketcap'],
        unitHint: 'USD, 2b → \$2B',
        scale: ScreenerQueryValueScale.millions),
    _n('sharesOutstanding', 'Shares Outstanding', 'sharesOutStanding',
        category: 'Descriptive',
        aliases: const ['shares', 'so'],
        unitHint: 'millions of shares',
        scale: ScreenerQueryValueScale.millions),
    _n('volume', 'Volume', 'volume',
        category: 'Descriptive',
        aliases: const ['vol'],
        unitHint: 'shares, 5m → 5,000,000',
        scale: ScreenerQueryValueScale.compact),
    _n('volume10Days', 'Avg Volume 10D', 'avgVolume10days',
        category: 'Descriptive',
        aliases: const ['avgvol10', 'avgVolume10days'],
        unitHint: 'shares',
        scale: ScreenerQueryValueScale.compact),
    _n('volume30Days', 'Avg Volume 30D', 'avgVolume30days',
        category: 'Descriptive',
        aliases: const ['avgvol30', 'avgVolume30days'],
        unitHint: 'shares',
        scale: ScreenerQueryValueScale.compact),
    _n('peAnnual', 'P/E Annual', 'peAnnual',
        category: 'Fundamental', aliases: const ['pe']),
    _n('peTTM', 'P/E TTM', 'peTTM',
        category: 'Fundamental', aliases: const ['pettm']),
    _n('pbAnnual', 'P/B Annual', 'pbAnnual',
        category: 'Fundamental', aliases: const ['pb']),
    _n('psAnnual', 'P/S Annual', 'psAnnual',
        category: 'Fundamental', aliases: const ['ps']),
    _n('psTTM', 'P/S TTM', 'psTTM', category: 'Fundamental'),
    _n('epsTTM', 'EPS (TTM)', 'epsTTM',
        category: 'Fundamental', aliases: const ['eps'], unitHint: 'USD'),
    _n('epsAnnual', 'EPS (Annual)', 'epsAnnual',
        category: 'Fundamental', unitHint: 'USD'),
    _n('evEbit', 'EV/EBIT', 'ev_ebit',
        category: 'Fundamental', aliases: const ['evebit']),
    _n('evFcf', 'EV/FCF', 'ev_fcf',
        category: 'Fundamental', aliases: const ['evfcf']),
    _n('enterpriseValue', 'Enterprise Value', 'enterpriseValue',
        category: 'Fundamental',
        aliases: const ['ev'],
        unitHint: 'USD',
        scale: ScreenerQueryValueScale.compact),
    _n('bookValuePerShare', 'Book Value/Share', 'bookValuePerShareAnnual',
        category: 'Fundamental', unitHint: 'USD'),
    _n('currentRatio', 'Current Ratio', 'currentRatioAnnual',
        category: 'Fundamental'),
    _n('quickRatio', 'Quick Ratio', 'quickRatioAnnual',
        category: 'Fundamental'),
    _n('debtEquity', 'Debt/Equity', 'totalDebt_totalEquityAnnual',
        category: 'Fundamental', aliases: const ['de', 'dte']),
    _n('longTermDebtEquity', 'Long-term Debt/Equity', 'longTermDebt_equityAnnual',
        category: 'Fundamental'),
    _n('interestCoverage', 'Interest Coverage', 'netInterestCoverageAnnual',
        category: 'Fundamental'),
    _n('equityToAssets', 'Equity to Assets', 'equity_to_assets_annual',
        category: 'Fundamental',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('netMargin', 'Net Margin', 'netProfitMarginAnnual',
        category: 'Fundamental',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('grossMargin', 'Gross Margin', 'grossMarginAnnual',
        category: 'Fundamental',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('operatingMargin', 'Operating Margin', 'operatingMarginAnnual',
        category: 'Fundamental',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('pretaxMargin', 'Pretax Margin', 'pretaxMarginAnnual',
        category: 'Fundamental',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('roe', 'ROE', 'ROE',
        category: 'Fundamental',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('roi', 'ROI', 'roiAnnual',
        category: 'Fundamental',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('roaTTM', 'ROA TTM', 'roaTTM',
        category: 'Fundamental',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('dividendYield', 'Dividend Yield', 'currentDividendYieldTTM',
        category: 'Fundamental',
        aliases: const ['yield', 'divyield'],
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('payoutRatio', 'Payout Ratio', 'payoutRatioTTM',
        category: 'Fundamental',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('assetTurnover', 'Asset Turnover', 'assetTurnoverAnnual',
        category: 'Fundamental'),
    _n('inventoryTurnover', 'Inventory Turnover', 'inventoryTurnoverAnnual',
        category: 'Fundamental'),
    _n('receivablesTurnover', 'Receivables Turnover', 'receivablesTurnoverTTM',
        category: 'Fundamental'),
    _n('epsGrowth', 'EPS Growth 1Y', 'eps_growth_1y',
        category: 'Fundamental',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('revenueGrowth', 'Revenue Growth 1Y', 'revenueGrowth1Y',
        category: 'Fundamental',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('analystRecommendation', 'Analyst Recommendation',
        'analyst_recommendation_weighted_avg',
        category: 'Fundamental',
        aliases: const ['analyst'],
        unitHint: '1 Strong Buy … 5 Strong Sell'),
    _n('priceChange1D', 'Price Change 1D', 'priceChange1DPercent',
        category: 'Technical',
        aliases: const ['chg1d', 'change1d'],
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('priceChange1W', 'Price Change 1W', 'priceChange1WPercent',
        category: 'Technical',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('priceChange1M', 'Price Change 1M', 'priceChange1MPercent',
        category: 'Technical',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('priceChange3M', 'Price Change 3M', 'priceChange3MPercent',
        category: 'Technical',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('priceChange6M', 'Price Change 6M', 'priceChange6MPercent',
        category: 'Technical',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('priceChange1Y', 'Price Change 1Y', 'priceChange1YPercent',
        category: 'Technical',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('priceChange3Y', 'Price Change 3Y', 'priceChange3YPercent',
        category: 'Technical',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('priceChange5Y', 'Price Change 5Y', 'priceChange5YPercent',
        category: 'Technical',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('priceChangeYTD', 'YTD Performance', 'priceChangeYTDPercent',
        category: 'Technical',
        aliases: const ['ytd'],
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('beta', 'Beta', 'beta', category: 'Technical'),
    _n('weekHigh52', '52W High', '52WeekHigh',
        category: 'Technical',
        aliases: const ['52WeekHigh', 'high52'],
        unitHint: 'USD'),
    _n('weekLow52', '52W Low', '52WeekLow',
        category: 'Technical',
        aliases: const ['52WeekLow', 'low52'],
        unitHint: 'USD'),
    _n('priceProximityToHigh', 'Price vs 52W High', 'priceProximityToHigh',
        category: 'Technical',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('marketCapChange3Y', 'Market Cap Change 3Y', 'marketCap_change_3y',
        category: 'Technical',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('open', 'Open', 'open', category: 'Technical', unitHint: 'USD'),
    _n('high', 'High', 'high', category: 'Technical', unitHint: 'USD'),
    _n('low', 'Low', 'low', category: 'Technical', unitHint: 'USD'),
    _n('close', 'Close', 'close', category: 'Technical', unitHint: 'USD'),
    _n('previousClose', 'Previous Close', 'previous_close',
        category: 'Technical', unitHint: 'USD'),
    _n('revenueGrowth3Y', 'Revenue Growth 3Y', 'revenueGrowth3Y',
        category: 'Growth',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('revenueGrowth5Y', 'Revenue Growth 5Y', 'revenueGrowth5Y',
        category: 'Growth',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('earningsGrowth3Y', 'EPS Growth 3Y', 'epsGrowth3Y',
        category: 'Growth',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('earningsGrowth5Y', 'EPS Growth 5Y', 'epsGrowth5Y',
        category: 'Growth',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('epsGrowthQuarterlyYoY', 'EPS Growth QoQ YoY', 'epsGrowthQuarterlyYoy',
        category: 'Growth',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('epsGrowthTTMYoY', 'EPS Growth TTM YoY', 'epsGrowthTTMYoy',
        category: 'Growth',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('revenueGrowthQuarterlyYoY', 'Revenue Growth QoQ YoY',
        'revenueGrowthQuarterlyYoy',
        category: 'Growth',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('revenueGrowthTTMYoY', 'Revenue Growth TTM YoY', 'revenueGrowthTTMYoy',
        category: 'Growth',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('revenuePerShareGrowth5Y', 'Revenue/Share Growth 5Y',
        'revenueShareGrowth5Y',
        category: 'Growth',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('roe5Y', 'ROE 5Y', 'roe5Y',
        category: 'Growth',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('roa5Y', 'ROA 5Y', 'roa5Y',
        category: 'Growth',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('assetsGrowth1Y', 'Assets Growth 1Y', 'assets_growth_1y',
        category: 'Growth',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('assetsGrowth3Y', 'Assets Growth 3Y', 'assets_growth_3y',
        category: 'Growth',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('assetsGrowth5Y', 'Assets Growth 5Y', 'assets_growth_5y',
        category: 'Growth',
        unitHint: '%',
        scale: ScreenerQueryValueScale.percent),
    _n('revenueAnnual', 'Revenue Annual', 'revenue_annual',
        category: 'Fundamental',
        scale: ScreenerQueryValueScale.compact),
    _n('netIncomeAnnual', 'Net Income Annual', 'net_income_annual',
        category: 'Fundamental',
        scale: ScreenerQueryValueScale.compact),
    _n('aum', 'AUM', 'aum',
        category: 'ETF',
        unitHint: 'USD',
        scale: ScreenerQueryValueScale.compact),
    _n('holdingsCount', 'Holdings Count', 'holdingsCount', category: 'ETF'),
  ];
}
