import 'package:flutter_test/flutter_test.dart';
import 'package:musaffa_terminal/models/screener_query.dart';

void main() {
  group('ScreenerQueryParser', () {
    test('parses currentPrice > 200', () {
      final parsed = ScreenerQueryParser.parse(
        'currentPrice > 200',
        closeValue: true,
      );
      expect(parsed.clauses, hasLength(1));
      expect(parsed.clauses.first.field.id, 'currentPrice');
      expect(parsed.clauses.first.operator.symbol, '>');
      expect(parsed.clauses.first.rawValue, '200');
      expect(parsed.expect, ScreenerQueryExpect.field);
    });

    test('parses chained AND clauses without spaces around operators', () {
      final parsed = ScreenerQueryParser.parse(
        'currentPrice>200 AND peTTM<15 AND currency=USD',
        closeValue: true,
      );
      expect(parsed.clauses, hasLength(3));
      expect(parsed.clauses[0].display, 'currentPrice > 200');
      expect(parsed.clauses[1].field.id, 'peTTM');
      expect(parsed.clauses[2].field.id, 'currency');
      expect(parsed.clauses[2].rawValue, 'USD');
    });

    test('suggests fields for curr', () {
      final parsed = ScreenerQueryParser.parse('curr');
      final suggestions = ScreenerQueryParser.suggestions(parsed);
      final ids = suggestions.map((s) => s.title).toList();
      expect(ids, contains('currentPrice'));
      expect(ids, contains('currency'));
    });

    test('suggests operators after a field', () {
      final parsed = ScreenerQueryParser.parse('currentPrice ');
      expect(parsed.expect, ScreenerQueryExpect.operator);
      final suggestions = ScreenerQueryParser.suggestions(parsed);
      expect(suggestions.map((s) => s.title), containsAll(['>', '>=', '<', '=']));
    });

    test('suggests currency values after typing', () {
      final parsed = ScreenerQueryParser.parse('currency = U');
      expect(parsed.expect, ScreenerQueryExpect.value);
      final suggestions = ScreenerQueryParser.suggestions(parsed);
      expect(suggestions.map((s) => s.insert), contains('USD'));
    });

    test('does not list fields until the user types', () {
      final parsed = ScreenerQueryParser.parse('');
      expect(parsed.expect, ScreenerQueryExpect.field);
      expect(ScreenerQueryParser.suggestions(parsed), isEmpty);
    });
  });

  group('ScreenerQueryClause.toTypesense', () {
    test('numeric comparison', () {
      final parsed = ScreenerQueryParser.parse('currentPrice > 200', closeValue: true);
      expect(parsed.clauses.first.toTypesense(), 'currentPrice:>200');
    });

    test('market cap suffix 2b is millions', () {
      final parsed = ScreenerQueryParser.parse('usdMarketCap > 2b', closeValue: true);
      expect(parsed.clauses.first.toTypesense(), 'usdMarketCap:>2000');
    });

    test('keyword equality is quoted', () {
      final parsed = ScreenerQueryParser.parse('currency = USD', closeValue: true);
      expect(parsed.clauses.first.toTypesense(), 'currency:=`USD`');
    });

    test('between operator', () {
      final parsed = ScreenerQueryParser.parse('peTTM between 10 20', closeValue: true);
      expect(parsed.clauses.first.toTypesense(), 'peTTM:>=10&&peTTM:<=20');
    });
    test('maps Technology to API sector keys used in the table', () {
      // Simulated reverse map used by FilterController after the fix.
      final mapping = {
        'Technology Services': ['Information Technology', 'Technology'],
        'Electronic Technology': ['Information Technology', 'Technology'],
        'Technology': ['Information Technology', 'Technology'],
      };
      List<String> mapSector(String ui) {
        final lower = ui.toLowerCase();
        final matches = <String>{};
        for (final e in mapping.entries) {
          if (e.key.toLowerCase() == lower) matches.add(e.key);
          for (final v in e.value) {
            if (v.toLowerCase() == lower) matches.add(e.key);
          }
        }
        return matches.toList()..sort();
      }

      final parsed = ScreenerQueryParser.parse(
        'sector = "Technology Services"',
        closeValue: true,
      );
      expect(
        parsed.clauses.first.toTypesense(mapSector: mapSector),
        'sector:=[`Technology Services`]',
      );
    });
  });
}
