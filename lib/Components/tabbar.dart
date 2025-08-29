import 'package:flutter/material.dart';
import 'package:musaffa_terminal/utils/auto_size_text.dart';

class HomeTabBar extends StatelessWidget {
  final ValueChanged<String>? onSearch;
  final VoidCallback? onSearchSubmit;

  const HomeTabBar({super.key, this.onSearch, this.onSearchSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Search bar (left half)
          Expanded(
            flex: 2,
            child: _SearchField(
              onChanged: onSearch,
              onSubmitted: (_) => onSearchSubmit?.call(),
            ),
          ),
          const SizedBox(width: 16),
          // Market indices (right half)
          const Expanded(
            flex: 2,
            child: _MarketIndicesStrip(),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _SearchField({this.onChanged, this.onSubmitted});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextField(
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, size: 20),
          hintText: 'Search for ETFs or stocks',
          hintStyle: const TextStyle(color: Colors.black54),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          filled: true,
          fillColor: const Color(0xFFF4F5F7),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _MarketIndicesStrip extends StatelessWidget {
  const _MarketIndicesStrip();

  @override
  Widget build(BuildContext context) {
    final items = const [
      _IndexItem(symbol: 'NASDAQ', changePct: 0.09),
      _IndexItem(symbol: 'S&P 500', changePct: -0.012),
      _IndexItem(symbol: 'DOW', changePct: 0.004),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: items
              .map((e) => Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: _IndexPill(item: e),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _IndexItem {
  final String symbol;
  final double changePct; // 0.09 => 9%
  const _IndexItem({required this.symbol, required this.changePct});
}

class _IndexPill extends StatelessWidget {
  final _IndexItem item;
  const _IndexPill({required this.item});

  @override
  Widget build(BuildContext context) {
    final isUp = item.changePct >= 0;
    final color = isUp ? const Color(0xFF0FA958) : const Color(0xFFD43C30);
    final icon = isUp ? Icons.arrow_upward : Icons.arrow_downward;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          MusaffaAutoSizeText.labelMedium(
            item.symbol,
            color: Colors.black87,
            group: MusaffaAutoSizeText.groups.labelMediumGroup,
          ),
          const SizedBox(width: 8),
          MusaffaAutoSizeText.labelMedium(
            _formatPct(item.changePct),
            color: color,
            group: MusaffaAutoSizeText.groups.labelMediumGroup,
          ),
        ],
      ),
    );
  }

  static String _formatPct(double value) {
    final sign = value >= 0 ? '+' : '';
    final pct = (value * 100).toStringAsFixed(2);
    return '$sign$pct%';
  }
}


