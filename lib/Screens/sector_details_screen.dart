import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/watchlist/widgets/watchlist_dropdown.dart';
import 'package:musaffa_terminal/services/sector_mapping_service.dart';

class SectorDetailsScreen extends StatefulWidget {
  final String sectorName;

  const SectorDetailsScreen({Key? key, required this.sectorName}) : super(key: key);

  @override
  State<SectorDetailsScreen> createState() => _SectorDetailsScreenState();
}

class _SectorDetailsScreenState extends State<SectorDetailsScreen> {
  late WatchlistController watchlistController;
  bool _isWatchlistOpen = false;
  List<String>? _mappedSectors;

  @override
  void initState() {
    super.initState();
    watchlistController = Get.put(WatchlistController());
    _initializeSectorMapping();
  }

  void _initializeSectorMapping() async {
    // Initialize the sector mapping service
    await SectorMappingService.initialize();
    
    // Get the mapped sectors for the clicked sector
    _mappedSectors = SectorMappingService.getMappedSectors(widget.sectorName);
    
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleWatchlist() {
    setState(() {
      _isWatchlistOpen = !_isWatchlistOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0F0F0F) 
          : const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          Column(
            children: [
              HomeTabBar(
                showBackButton: true,
                isWatchlistOpen: _isWatchlistOpen,
                onWatchlistToggle: _toggleWatchlist,
                onThemeToggle: () {
                  final currentTheme = Theme.of(context).brightness;
                  Get.changeThemeMode(
                    currentTheme == Brightness.dark 
                        ? ThemeMode.light 
                        : ThemeMode.dark,
                  );
                },
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sector Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sector Details',
                              style: DashboardTextStyles.headerTitle.copyWith(
                                color: isDarkMode ? const Color(0xFFE0E0E0) : const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You clicked on: ${widget.sectorName}',
                              style: DashboardTextStyles.headerPrice.copyWith(
                                color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF81AACE),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_mappedSectors != null && _mappedSectors!.isNotEmpty) ...[
                              Text(
                                'This sector includes the following categories:',
                                style: DashboardTextStyles.dataCell.copyWith(
                                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: _mappedSectors!.map((sector) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      sector,
                                      style: DashboardTextStyles.dataCell.copyWith(
                                        color: isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF374151),
                                        fontSize: 11,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ] else ...[
                              Text(
                                'No mapping found for this sector.',
                                style: DashboardTextStyles.dataCell.copyWith(
                                  color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isDarkMode ? const Color(0xFF404040) : const Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Next Steps:',
                                    style: DashboardTextStyles.stockName.copyWith(
                                      color: isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF81AACE),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '• Show all stocks in this sector category\n• Display sector performance charts\n• Add sector-specific news and analysis\n• Enable stock filtering and sorting',
                                    style: DashboardTextStyles.dataCell.copyWith(
                                      color: isDarkMode ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
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
          // Watchlist Sidebar
          if (_isWatchlistOpen)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 400,
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFFFFFF),
                  border: Border(
                    left: BorderSide(
                      color: isDarkMode ? const Color(0xFF333333) : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                ),
                child: WatchlistDropdown(isDarkMode: isDarkMode),
              ),
            ),
        ],
      ),
    );
  }
}
