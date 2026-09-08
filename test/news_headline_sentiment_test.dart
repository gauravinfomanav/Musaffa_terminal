import 'package:flutter_test/flutter_test.dart';
import 'package:musaffa_terminal/models/company_news_item.dart';
import 'package:musaffa_terminal/models/news_headline_sentiment.dart';

void main() {
  group('NewsHeadlineSentiment', () {
    test('tags upgrades, beats, and buy-the-stock headlines as bullish', () {
      expect(
        NewsHeadlineSentiment.classify(
          'Apple upgraded to buy after iPhone beats estimates',
        ).tone,
        NewsHeadlineTone.bullish,
      );
      expect(
        NewsHeadlineSentiment.classify(
          "Here's Whether It's Finally Time to Buy the Stock.",
        ).tone,
        NewsHeadlineTone.bullish,
      );
      expect(
        NewsHeadlineSentiment.classify(
          'Apple (AAPL) Raises Apple TV and Apple One Prices Again in the U.S.',
        ).tone,
        NewsHeadlineTone.bullish,
      );
    });

    test('tags lawsuits, misses, and negative catalysts as bearish', () {
      expect(
        NewsHeadlineSentiment.classify(
          "KeyBanc warns Apple's iPhone 18 launch may be a negative catalyst for shares",
        ).tone,
        NewsHeadlineTone.bearish,
      );
      expect(
        NewsHeadlineSentiment.classify(
          'Apple (AAPL) Draws New £2 Billion UK ATT Lawsuit With Wider Europe Stakes',
        ).tone,
        NewsHeadlineTone.bearish,
      );
      expect(
        NewsHeadlineSentiment.classify(
          'Why Apple (AAPL) Dipped More Than Broader Market Today',
        ).tone,
        NewsHeadlineTone.bearish,
      );
      expect(
        NewsHeadlineSentiment.classify(
          '5 big analyst AI moves: iPhone launch to be negative for Apple stock',
        ).tone,
        NewsHeadlineTone.bearish,
      );
    });

    test('marks mixed when bullish and bearish language are balanced', () {
      expect(
        NewsHeadlineSentiment.classify(
          'Apple upgraded after lawsuit filing',
        ).tone,
        NewsHeadlineTone.mixed,
      );
    });

    test('stays neutral on factual headlines without tone words', () {
      expect(
        NewsHeadlineSentiment.classify(
          'Apple (AAPL) Sets iPhone Launch Event. The First Under New CEO John Ternus',
        ).tone,
        NewsHeadlineTone.neutral,
      );
    });

    test('does not treat "again" as a gain', () {
      expect(
        NewsHeadlineSentiment.classify('Prices change again in the U.S.').tone,
        NewsHeadlineTone.neutral,
      );
    });
  });

  group('CompanyNewsItem', () {
    test('parses Finnhub company-news payloads and attaches a tone', () {
      final CompanyNewsItem item = CompanyNewsItem.fromJson(<String, dynamic>{
        'headline': 'Apple stock plunges after earnings miss',
        'summary': 'Shares fell after results.',
        'source': 'Yahoo',
        'url': 'https://example.com/a',
        'datetime': 1788741926,
      });

      expect(item.headline, contains('plunges'));
      expect(item.source, 'Yahoo');
      expect(item.datetime, 1788741926);
      expect(item.tone, NewsHeadlineTone.bearish);
    });
  });
}
