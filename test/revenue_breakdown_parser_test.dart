import 'package:flutter_test/flutter_test.dart';
import 'package:musaffa_terminal/models/revenue_breakdown_model.dart';

void main() {
  group('RevenueBreakdownParser', () {
    test('parses nested product and geography axes from filings', () {
      final model = RevenueBreakdownModel.parse(<String, dynamic>{
        'symbol': 'AAPL',
        'cik': '320193',
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'accessNumber': '0000320193-26-000013',
            'breakdown': <String, dynamic>{
              'startDate': '2025-09-28',
              'endDate': '2026-03-28',
              'value': 254940000000.0,
              'unit': 'usd',
              'revenueBreakdown': <Map<String, dynamic>>[
                <String, dynamic>{
                  'axis': 'srt_ProductOrServiceAxis',
                  'data': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'label': 'Products',
                      'value': 193951000000.0,
                      'percentage': 76.0,
                    },
                    <String, dynamic>{
                      'label': 'Services',
                      'value': 60989000000.0,
                      'percentage': 24.0,
                    },
                  ],
                },
                <String, dynamic>{
                  'axis': 'srt_ProductOrServiceAxis',
                  'data': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'label': 'iPhone',
                      'value': 142263000000.0,
                      'percentage': 55.8,
                    },
                    <String, dynamic>{
                      'label': 'Services',
                      'value': 60989000000.0,
                      'percentage': 23.9,
                    },
                    <String, dynamic>{
                      'label': 'Wearables, Home and Accessories',
                      'value': 19394000000.0,
                      'percentage': 7.6,
                    },
                    <String, dynamic>{
                      'label': 'Mac',
                      'value': 16785000000.0,
                      'percentage': 6.6,
                    },
                    <String, dynamic>{
                      'label': 'iPad',
                      'value': 15509000000.0,
                      'percentage': 6.1,
                    },
                  ],
                },
              ],
            },
          },
          <String, dynamic>{
            'accessNumber': '0000320193-25-000050',
            'breakdown': <String, dynamic>{
              'startDate': '2024-09-29',
              'endDate': '2025-06-28',
              'value': 313695000000.0,
              'unit': 'usd',
              'revenueBreakdown': <Map<String, dynamic>>[
                <String, dynamic>{
                  'axis': 'us-gaap_StatementBusinessSegmentsAxis',
                  'data': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'label': 'Americas',
                      'value': 130000000000.0,
                      'percentage': 41.4,
                    },
                    <String, dynamic>{
                      'label': 'Europe',
                      'value': 80000000000.0,
                      'percentage': 25.5,
                    },
                    <String, dynamic>{
                      'label': 'Greater China',
                      'value': 50000000000.0,
                      'percentage': 15.9,
                    },
                    <String, dynamic>{
                      'label': 'Japan',
                      'value': 28000000000.0,
                      'percentage': 8.9,
                    },
                    <String, dynamic>{
                      'label': 'Rest of Asia Pacific',
                      'value': 25695000000.0,
                      'percentage': 8.2,
                    },
                  ],
                },
              ],
            },
          },
          <String, dynamic>{
            'accessNumber': '0000320193-25-000079',
            'breakdown': <String, dynamic>{
              'startDate': '2024-09-29',
              'endDate': '2025-09-27',
              'value': 416161000000.0,
              'unit': 'usd',
              'revenueBreakdown': <Map<String, dynamic>>[
                <String, dynamic>{
                  'axis': 'srt_StatementGeographicalAxis',
                  'data': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'label': 'U.S.',
                      'value': 180000000000.0,
                      'percentage': 43.0,
                    },
                    <String, dynamic>{
                      'label': 'China',
                      'value': 70000000000.0,
                      'percentage': 17.0,
                    },
                    <String, dynamic>{
                      'label': 'Other countries',
                      'value': 166161000000.0,
                      'percentage': 40.0,
                    },
                  ],
                },
              ],
            },
          },
        ],
      });

      expect(model, isNotNull);
      expect(model!.hasData, isTrue);
      expect(model.product, isNotNull);
      expect(model.geography, isNotNull);

      expect(model.product!.items.first.label, 'iPhone');
      expect(model.product!.items.length, 5);
      expect(model.product!.periodLabel, contains('2026'));

      // Prefer richer 5-region geography over coarser 3-country split.
      expect(model.geography!.items.length, 5);
      expect(model.geography!.items.first.label, 'Americas');
    });

    test('parses legacy percent/actual product and geographic maps', () {
      final model = RevenueBreakdownModel.parse(<String, dynamic>{
        'symbol': 'MSFT',
        'data': <Map<String, dynamic>>[
          <String, dynamic>{
            'period': '2024-06-30',
            'actual': <String, dynamic>{
              'product': <String, dynamic>{
                'Server products': 90000000000.0,
                'Office': 50000000000.0,
                'Windows': 20000000000.0,
              },
              'geographic': <String, dynamic>{
                'United States': 100000000000.0,
                'Other countries': 60000000000.0,
              },
            },
            'percent': <String, dynamic>{
              'product': <String, dynamic>{
                'Server products': 56.0,
                'Office': 31.0,
                'Windows': 13.0,
              },
              'geographic': <String, dynamic>{
                'United States': 62.5,
                'Other countries': 37.5,
              },
            },
          },
        ],
      });

      expect(model, isNotNull);
      expect(model!.product!.items.map((e) => e.label), contains('Server products'));
      expect(model.geography!.items.map((e) => e.label), contains('United States'));
      expect(model.product!.items.first.percentage, 56.0);
    });

    test('returns null for empty payloads', () {
      expect(RevenueBreakdownModel.parse(<String, dynamic>{}), isNull);
      expect(
        RevenueBreakdownModel.parse(<String, dynamic>{
          'data': <dynamic>[],
        }),
        isNull,
      );
    });
  });
}
