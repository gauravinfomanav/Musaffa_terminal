import 'package:musaffa_terminal/models/news_headline_sentiment.dart';

class CompanyNewsItem {
  const CompanyNewsItem({
    required this.headline,
    required this.summary,
    required this.source,
    required this.url,
    required this.datetime,
    required this.tone,
  });

  final String headline;
  final String summary;
  final String source;
  final String url;
  final int datetime;
  final NewsHeadlineTone tone;

  factory CompanyNewsItem.fromJson(Map<String, dynamic> json) {
    final String headline = _string(json['headline'] ?? json['Headline']);
    final String summary = _string(json['summary'] ?? json['Summary']);
    final NewsHeadlineSentimentScore score =
        NewsHeadlineSentiment.classify(headline, summary: summary);

    return CompanyNewsItem(
      headline: headline,
      summary: summary,
      source: _string(json['source'] ?? json['Source']),
      url: _string(
        json['url'] ?? json['URL'] ?? json['Url'] ?? json['Link'] ?? json['link'],
      ),
      datetime: _int(json['datetime'] ?? json['Datetime']),
      tone: score.tone,
    );
  }

  static String _string(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
