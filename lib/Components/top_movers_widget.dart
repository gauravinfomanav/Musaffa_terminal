import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Controllers/top_gainer_loosers.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/utils/constants.dart';

class TopMoversWidget extends StatefulWidget {
  const TopMoversWidget({Key? key}) : super(key: key);

  @override
  State<TopMoversWidget> createState() => _TopMoversWidgetState();
}

class _TopMoversWidgetState extends State<TopMoversWidget> {
  final TopGainerLosersController controller = Get.put(TopGainerLosersController());
  String _activeTab = 'gainers';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (_activeTab == 'gainers') {
      controller.loadGainers();
    } else {
      controller.loadLosers();
    }
  }

  void _switchTab(String tab) {
    if (_activeTab != tab) {
      setState(() {
        _activeTab = tab;
      });
      _loadData();
    }
  }

  List<SimpleRowModel> _buildRows(List<TopMoverItem> items) {
    return items.map((item) {
      final isPositive = (item.change1DPercent ?? 0) >= 0;
      final changeColor = isPositive ? Colors.green.shade600 : Colors.red.shade600;
      
      return SimpleRowModel(
        symbol: item.symbol,
        name: item.name,
        logo: item.logo,
        price: item.currentPrice,
        changePercent: item.change1DPercent,
        fields: {
          'price': item.currentPrice != null ? '\$${item.currentPrice!.toStringAsFixed(2)}' : '-',
          'change': item.change1DPercent != null ? '${item.change1DPercent!.toStringAsFixed(2)}%' : '-',
        },
        // Store color info for the change column
        changeColor: changeColor,
        isPositive: isPositive,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Top Movers Today',
                style: DashboardTextStyles.titleSmall,
              ),
              const SizedBox(width: 12),
              _buildToggleButton(),
            ],
          ),
          
          Obx(() {
            if (controller.isLoading.value) {
              return _buildShimmerLoader();
            }
            
                          if (controller.errorMessage.isNotEmpty) {
                return Center(
                  child: Text(
                    controller.errorMessage.value,
                    style: DashboardTextStyles.errorMessage,
                  ),
                );
              }

            final items = _activeTab == 'gainers' ? controller.gainers : controller.losers;
                          if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No data available',
                    style: DashboardTextStyles.noData,
                  ),
                );
              }

            return DynamicTable(
              columns: const [
                SimpleColumn(label: 'Price', fieldName: 'price', isNumeric: true),
                SimpleColumn(label: 'Change', fieldName: 'change', isNumeric: true),
              ],
              rows: _buildRows(items),
              showFixedColumn: true,
              considerPadding: false,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildToggleButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGainers = _activeTab == 'gainers';
    
    return GestureDetector(
      onTap: () => _switchTab(isGainers ? 'losers' : 'gainers'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF6B7280) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isGainers ? 'Gainers' : 'Losers',
              style: DashboardTextStyles.buttonText,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_up,
              size: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Column(
      children: List.generate(5, (i) => Container(
        height: 52,
        width: Get.width*0.3,
        margin: EdgeInsets.only(bottom: i == 4 ? 0 : 8),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
      )),
    );
  }
}
