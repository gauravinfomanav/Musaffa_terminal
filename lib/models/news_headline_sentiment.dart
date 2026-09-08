enum NewsHeadlineTone { bullish, bearish, mixed, neutral }

extension NewsHeadlineToneLabel on NewsHeadlineTone {
  String get label {
    switch (this) {
      case NewsHeadlineTone.bullish:
        return 'Bullish';
      case NewsHeadlineTone.bearish:
        return 'Bearish';
      case NewsHeadlineTone.mixed:
        return 'Mixed';
      case NewsHeadlineTone.neutral:
        return 'Neutral';
    }
  }
}

class NewsHeadlineSentimentScore {
  const NewsHeadlineSentimentScore({
    required this.tone,
    required this.bullishHits,
    required this.bearishHits,
  });

  final NewsHeadlineTone tone;
  final int bullishHits;
  final int bearishHits;

  String get label => tone.label;
}

/// Tags a headline (and optional summary) as bullish / bearish from language.
/// Finnhub news-sentiment is aggregate-only; this is how we show which stories lean which way.
class NewsHeadlineSentiment {
  NewsHeadlineSentiment._();

  static const List<String> _bullishPhrases = <String>[
    'beats estimates',
    'beat estimates',
    'tops estimates',
    'topped estimates',
    'raises guidance',
    'raised guidance',
    'raises forecast',
    'raised forecast',
    'price target raised',
    'pt raised',
    'upgraded to buy',
    'upgrade to buy',
    'initiated at buy',
    'strong buy',
    'time to buy',
    'buy the stock',
    'raises prices',
    'raised prices',
    'price hike',
    'record high',
    'all-time high',
    'all time high',
    'hits high',
    'new high',
    'better than expected',
    'above expectations',
    'earnings beat',
    'revenue beat',
    'profit jump',
    'profit jumps',
    'revenue jump',
    'stellar growth',
    'strong growth',
    'accelerating growth',
    'outperform',
    'outperforming',
    'outperformed',
    'overweight',
    'upgraded',
    'upgrade',
    'soars',
    'soar',
    'surges',
    'surge',
    'rallies',
    'rally',
    'skyrockets',
    'jumps',
    'jumped',
    'rallied',
    'surged',
    'bullish',
    'upbeat',
    'optimistic',
    'beats',
    'beat',
    'gains',
    'gained',
    'rises',
    'rose',
    'climbs',
    'climbed',
    'rebounds',
    'rebounded',
    'expansion',
    'partnership',
    'wins contract',
    'won contract',
    'approval',
    'buyback',
    'dividend hike',
    'raises dividend',
  ];

  static const List<String> _bullishPatterns = <String>[
    r'rais(?:es|ed)\b.{0,48}\bprices',
    r'\bbet big\b',
    r'\bbillion in\b.{0,24}\brevenue',
  ];

  static const List<String> _bearishPhrases = <String>[
    'misses estimates',
    'missed estimates',
    'below estimates',
    'cuts guidance',
    'cut guidance',
    'lowers guidance',
    'lowered guidance',
    'cuts forecast',
    'cut forecast',
    'price target cut',
    'pt cut',
    'downgraded to sell',
    'initiated at sell',
    'sell rating',
    'negative catalyst',
    'negative for',
    'to be negative',
    'negative',
    'profit warning',
    'running out of room',
    'worse than expected',
    'below expectations',
    'earnings miss',
    'revenue miss',
    'job cuts',
    'layoffs',
    'lawsuit',
    'lawsuits',
    'sued',
    'investigation',
    'probe',
    'downgraded',
    'downgrade',
    'underweight',
    'plunges',
    'plunged',
    'slumps',
    'slumped',
    'tumbles',
    'tumbled',
    'tanks',
    'tanked',
    'crashes',
    'crashed',
    'sinks',
    'sank',
    'dipped',
    'dips',
    'falls',
    'fell',
    'drops',
    'dropped',
    'declines',
    'declined',
    'slides',
    'slid',
    'selloff',
    'sell-off',
    'bearish',
    'warns',
    'warning',
    'misses',
    'missed',
    'miss',
    'bankruptcy',
    'default',
    'fraud',
    'scandal',
    'recall',
    'laggard',
    'weakness',
    'weak',
    'pressure',
    'risks',
    'headwinds',
  ];

  static const List<String> _bearishPatterns = <String>[
    r'\bwarns?\b.{0,48}\bnegative\b',
    r'\brunning out of room\b',
  ];

  static NewsHeadlineSentimentScore classify(
    String headline, {
    String? summary,
  }) {
    final String primary = _normalize(headline);
    NewsHeadlineSentimentScore score = _score(primary);
    if (score.tone != NewsHeadlineTone.neutral ||
        summary == null ||
        summary.trim().isEmpty) {
      return score;
    }
    return _score('$primary ${_normalize(summary)}');
  }

  static NewsHeadlineSentimentScore _score(String text) {
    if (text.isEmpty) {
      return const NewsHeadlineSentimentScore(
        tone: NewsHeadlineTone.neutral,
        bullishHits: 0,
        bearishHits: 0,
      );
    }

    final int bullish =
        _hitWeight(text, _bullishPhrases) + _patternWeight(text, _bullishPatterns);
    final int bearish =
        _hitWeight(text, _bearishPhrases) + _patternWeight(text, _bearishPatterns);

    NewsHeadlineTone tone = NewsHeadlineTone.neutral;
    if (bullish > 0 && bearish > 0 && bullish == bearish) {
      tone = NewsHeadlineTone.mixed;
    } else if (bullish > bearish) {
      tone = NewsHeadlineTone.bullish;
    } else if (bearish > bullish) {
      tone = NewsHeadlineTone.bearish;
    }

    return NewsHeadlineSentimentScore(
      tone: tone,
      bullishHits: bullish,
      bearishHits: bearish,
    );
  }

  static int _hitWeight(String text, List<String> phrases) {
    int weight = 0;
    for (final String phrase in phrases) {
      if (_hasPhrase(text, phrase)) {
        weight += phrase.contains(' ') ? 2 : 1;
      }
    }
    return weight;
  }

  static int _patternWeight(String text, List<String> patterns) {
    int weight = 0;
    for (final String pattern in patterns) {
      if (RegExp(pattern).hasMatch(text)) {
        weight += 2;
      }
    }
    return weight;
  }

  static bool _hasPhrase(String text, String phrase) {
    final String escaped = RegExp.escape(phrase);
    return RegExp(
      '(^|[^a-z0-9])$escaped(\$|[^a-z0-9])',
    ).hasMatch(text);
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
