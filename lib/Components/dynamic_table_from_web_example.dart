import 'package:flutter/material.dart';
import 'package:musaffa_terminal/Components/dynamic_table_from_web.dart';

/// Example: How to use DynamicTableFromWeb
class DynamicTableFromWebExample extends StatefulWidget {
  const DynamicTableFromWebExample({Key? key}) : super(key: key);

  @override
  State<DynamicTableFromWebExample> createState() =>
      _DynamicTableFromWebExampleState();
}

class _DynamicTableFromWebExampleState
    extends State<DynamicTableFromWebExample> {
  late List<DynamicTableRow> _tableRows;
  late SortState? _sortState;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _sortState = null;
    _currentPage = 1;
    _tableRows = _generateSampleData();
  }

  /// Generate sample data
  List<DynamicTableRow> _generateSampleData() {
    return [
      DynamicTableRow(
        id: '1',
        data: {
          'ticker': 'AAPL',
          'company': 'Apple Inc.',
          'price': 189.45,
          'change': 2.35,
          'marketCap': '2.9T',
          'volume': '52.3M',
          'pe': 28.4,
          'status': 'Active',
        },
      ),
      DynamicTableRow(
        id: '2',
        data: {
          'ticker': 'MSFT',
          'company': 'Microsoft Corp.',
          'price': 378.91,
          'change': 1.82,
          'marketCap': '2.8T',
          'volume': '18.6M',
          'pe': 32.1,
          'status': 'Active',
        },
      ),
      DynamicTableRow(
        id: '3',
        data: {
          'ticker': 'GOOGL',
          'company': 'Alphabet Inc.',
          'price': 140.23,
          'change': -0.45,
          'marketCap': '1.8T',
          'volume': '21.2M',
          'pe': 25.6,
          'status': 'Active',
        },
      ),
      DynamicTableRow(
        id: '4',
        data: {
          'ticker': 'AMZN',
          'company': 'Amazon.com Inc.',
          'price': 175.84,
          'change': 3.12,
          'marketCap': '1.8T',
          'volume': '35.7M',
          'pe': 51.3,
          'status': 'Active',
        },
      ),
      DynamicTableRow(
        id: '5',
        data: {
          'ticker': 'NVDA',
          'company': 'NVIDIA Corp.',
          'price': 875.23,
          'change': 5.67,
          'marketCap': '2.1T',
          'volume': '28.4M',
          'pe': 67.2,
          'status': 'Active',
        },
      ),
      DynamicTableRow(
        id: '6',
        data: {
          'ticker': 'META',
          'company': 'Meta Platforms Inc.',
          'price': 312.45,
          'change': -2.10,
          'marketCap': '789B',
          'volume': '12.3M',
          'pe': 18.9,
          'status': 'Active',
        },
      ),
      DynamicTableRow(
        id: '7',
        data: {
          'ticker': 'TSLA',
          'company': 'Tesla Inc.',
          'price': 242.84,
          'change': 4.23,
          'marketCap': '767B',
          'volume': '102.1M',
          'pe': 72.4,
          'status': 'Active',
        },
      ),
      DynamicTableRow(
        id: '8',
        data: {
          'ticker': 'JPM',
          'company': 'JPMorgan Chase',
          'price': 189.32,
          'change': -1.23,
          'marketCap': '524B',
          'volume': '8.2M',
          'pe': 10.5,
          'status': 'Active',
        },
      ),
      DynamicTableRow(
        id: '9',
        data: {
          'ticker': 'V',
          'company': 'Visa Inc.',
          'price': 264.21,
          'change': 2.09,
          'marketCap': '548B',
          'volume': '5.9M',
          'pe': 35.2,
          'status': 'Active',
        },
      ),
      DynamicTableRow(
        id: '10',
        data: {
          'ticker': 'JNJ',
          'company': 'Johnson & Johnson',
          'price': 159.86,
          'change': 0.82,
          'marketCap': '425B',
          'volume': '4.3M',
          'pe': 14.6,
          'status': 'Active',
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Table Example'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: DynamicTableFromWeb(
          // Data & Structure
          columns: [
            DynamicTableColumn(
              key: 'ticker',
              label: 'Ticker',
              width: 100,
              sortable: true,
              searchable: true,
            ),
            DynamicTableColumn(
              key: 'company',
              label: 'Company',
              width: 200,
              sortable: true,
              searchable: true,
            ),
            DynamicTableColumn(
              key: 'price',
              label: 'Price',
              width: 100,
              sortable: true,
              searchable: false,
              align: TextAlign.right,
            ),
            DynamicTableColumn(
              key: 'change',
              label: 'Change %',
              width: 100,
              sortable: true,
              searchable: false,
              align: TextAlign.right,
            ),
            DynamicTableColumn(
              key: 'marketCap',
              label: 'Market Cap',
              width: 120,
              sortable: true,
              searchable: false,
              align: TextAlign.right,
            ),
            DynamicTableColumn(
              key: 'volume',
              label: 'Volume',
              width: 120,
              sortable: true,
              searchable: false,
              align: TextAlign.right,
            ),
            DynamicTableColumn(
              key: 'pe',
              label: 'P/E Ratio',
              width: 100,
              sortable: true,
              searchable: false,
              align: TextAlign.right,
            ),
            DynamicTableColumn(
              key: 'status',
              label: 'Status',
              width: 100,
              sortable: false,
              filterable: true,
              filterType: 'select',
              filterOptions: ['Active', 'Inactive', 'Pending'],
            ),
          ],
          rows: _tableRows,
          // UI Features
          title: 'Stocks Portfolio',
          subtitle: 'Real-time stock data with sorting, filtering & pagination',
          searchable: true,
          paginated: true,
          selectable: true,
          enableColumnVisibilityToggle: true,
          enableColumnReorder: true,
          enableColumnPinning: true,
          enableRowReorder: true,
          enableColumnFilters: true,
          stickyHeader: true,
          showSortIndicators: true,
          pageSize: 10,
          maxHeight: 600,
          // Callbacks
          sortState: _sortState,
          onSortChange: (key, direction) {
            setState(() {
              _sortState = SortState(key: key, direction: direction);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sorted by $key ($direction)')),
            );
          },
          onSelectionChange: (selectedRows) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selected ${selectedRows.length} rows'),
              ),
            );
          },
          onRowDoubleClick: (row) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Row clicked: ${row.data['ticker']}')),
            );
          },
          onPageChange: (page) {
            setState(() => _currentPage = page);
          },
          emptyStateTitle: 'No stocks found',
          emptyStateDescription:
              'Try adjusting your filters or search query.',
        ),
      ),
    );
  }
}

/// Main exit point for testing
void main() {
  runApp(
    const MaterialApp(
      home: DynamicTableFromWebExample(),
    ),
  );
}
