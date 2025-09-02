import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/models/ticker_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/utils.dart';

class TickerDetailScreen extends StatelessWidget {
  final TickerModel ticker;

  const TickerDetailScreen({Key? key, required this.ticker}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F0F0F) 
          : const Color(0xFFFAFAFA),
      body: Column(
        children: [
          // Tabbar at the top - same as main screen
          HomeTabBar(
            showBackButton: true,
            onThemeToggle: () {
              final currentTheme = Theme.of(context).brightness;
              Get.changeThemeMode(
                currentTheme == Brightness.dark 
                    ? ThemeMode.light 
                    : ThemeMode.dark,
              );
            },
          ),
          
          // Content area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stock Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Logo
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: ticker.logo != null && ticker.logo!.isNotEmpty
                                    ? Colors.transparent
                                    : (isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: showLogo(
                                ticker.symbol ?? ticker.ticker ?? '',
                                ticker.logo ?? '',
                                sideWidth: 40,
                                name: ticker.symbol ?? ticker.ticker ?? '',
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Ticker and Company Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ticker.symbol ?? ticker.ticker ?? '',
                                    style: DashboardTextStyles.stockName.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF1F2937),
                                    ),
                                  ),
                                  Text(
                                    ticker.companyName ?? ticker.name ?? '',
                                    style: DashboardTextStyles.stockName.copyWith(
                                      fontSize: 16,
                                      color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF6B7280),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Additional Details
                        Row(
                          children: [
                            _buildDetailItem('Type', ticker.isStock ? 'Stock' : 'ETF', isDarkMode),
                            const SizedBox(width: 24),
                            _buildDetailItem('Exchange', ticker.exchange ?? 'N/A', isDarkMode),
                            const SizedBox(width: 24),
                            _buildDetailItem('Country', ticker.countryName ?? 'N/A', isDarkMode),
                          ],
                        ),
                        
                        if (ticker.currentPrice != null) ...[
                          const SizedBox(height: 16),
                          _buildDetailItem('Current Price', '\$${ticker.currentPrice!.toStringAsFixed(2)}', isDarkMode),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Message
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You are now viewing the ${ticker.symbol ?? ticker.ticker} stock page. This is a placeholder for the detailed stock information screen.',
                            style: DashboardTextStyles.stockName.copyWith(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DashboardTextStyles.tickerSymbol.copyWith(
            color: isDarkMode ? const Color(0xFF6B7280) : const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: DashboardTextStyles.stockName.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}
