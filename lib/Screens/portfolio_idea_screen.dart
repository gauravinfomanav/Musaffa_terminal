import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musaffa_terminal/Components/tabbar.dart';
import 'package:musaffa_terminal/Components/watchlist_sidebar.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/watchlist/controllers/watchlist_controller.dart';
import 'package:musaffa_terminal/Screens/portfolio_builder_form.dart';

class PortfolioIdeaScreen extends StatefulWidget {
  const PortfolioIdeaScreen({super.key});

  @override
  State<PortfolioIdeaScreen> createState() => _PortfolioIdeaScreenState();
}

class _PortfolioIdeaScreenState extends State<PortfolioIdeaScreen> with SingleTickerProviderStateMixin {
  late final WatchlistController _watchlistController;
  bool _isWatchlistOpen = false;
  bool _isNewIdeaExpanded = false;
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _watchlistController = Get.put(WatchlistController());
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleWatchlist() {
    setState(() {
      _isWatchlistOpen = !_isWatchlistOpen;
      if (_isWatchlistOpen) {
        _watchlistController.resetToDefaultWatchlist();
      }
    });
  }

  void _toggleNewIdeaForm() {
    setState(() {
      _isNewIdeaExpanded = !_isNewIdeaExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
      body: GestureDetector(
        onTap: () {
          if (_isWatchlistOpen) {
            setState(() => _isWatchlistOpen = false);
          }
        },
        child: Stack(
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
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Padding(
                      padding: LayoutConstants.screenPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 16),
                          // Content will be added here
                          _buildPlaceholderContent(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isWatchlistOpen)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {},
                  child: WatchlistSidebar(
                    isDarkMode: isDark,
                    onClose: () => setState(() => _isWatchlistOpen = false),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio Ideas',
              style: DashboardTextStyles.titleSmall.copyWith(
                fontSize: 20,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const Spacer(),
        _PrimaryPillButton(
          label: _isNewIdeaExpanded ? 'Cancel' : 'New Idea',
          icon: _isNewIdeaExpanded ? Icons.close : Icons.add,
          onTap: _toggleNewIdeaForm,
          isDarkMode: isDark,
        ),
      ],
    );
  }

  Widget _buildPlaceholderContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expandable New Idea Form
        if (_isNewIdeaExpanded) ...[
          PortfolioBuilderForm(
            onCancel: () {
              setState(() {
                _isNewIdeaExpanded = false;
              });
            },
            onSaveDraft: () {
              // Save draft logic
              setState(() {
                _isNewIdeaExpanded = false;
              });
            },
            onSavePortfolio: () {
              // Save portfolio logic
              setState(() {
                _isNewIdeaExpanded = false;
              });
            },
          ),
          const SizedBox(height: 16),
        ],
        // Tabs for Active/Drafts/Archived
        _buildTabs(context),
        const SizedBox(height: 16),
        // Existing Portfolios List
        _buildPortfoliosList(context),
      ],
    );
  }

  Widget _buildTabs(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabs = ['Active Portfolios', 'Drafts', 'Archived'];
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151718) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final label = entry.value;
          final isSelected = _selectedTabIndex == index;
          
          return GestureDetector(
            onTap: () {
              _tabController.animateTo(index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF81AACE) : const Color(0xFF3B82F6))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(90),
              ),
              child: Text(
                label.toUpperCase(),
                style: DashboardTextStyles.columnHeader.copyWith(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPortfoliosList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2A2F33) : const Color(0xFFE5E7EB);
    final cardColor = isDark ? const Color(0xFF151718) : Colors.white;

    final tabLabels = ['Active Portfolios', 'Drafts', 'Archived'];
    final emptyMessages = [
      'No active portfolios',
      'No draft portfolios',
      'No archived portfolios',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tabLabels[_selectedTabIndex],
            style: DashboardTextStyles.titleSmall.copyWith(
              fontSize: 16,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              emptyMessages[_selectedTabIndex],
              style: DashboardTextStyles.stockName.copyWith(
                color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable Pill Button Components (matching trading_ideas_screen.dart style)
class _PrimaryPillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isDarkMode;

  const _PrimaryPillButton({
    required this.label,
    this.icon,
    required this.isDarkMode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final primaryColor =
        isDarkMode ? const Color(0xFF81AACE) : const Color(0xFF3B82F6);
    final disabledBg =
        isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: enabled ? primaryColor : disabledBg,
          borderRadius: BorderRadius.circular(90),
          border: Border.all(
            color: enabled ? primaryColor : disabledBg,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: enabled ? Colors.white : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label.toUpperCase(),
              style: DashboardTextStyles.columnHeader.copyWith(
                color: enabled ? Colors.white : const Color(0xFF9CA3AF),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

