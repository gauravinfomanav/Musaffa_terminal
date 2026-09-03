import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/portfolio/models/portfolio_analytics_snapshot.dart';
import 'package:musaffa_terminal/utils/home_ui.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

/// Compact geographic exposure map driven by portfolio country data.
class PortfolioCountryMap extends StatefulWidget {
  const PortfolioCountryMap({
    super.key,
    required this.isDark,
    required this.countries,
    this.height = 280,
  });

  final bool isDark;
  final List<CountryAllocation> countries;
  final double height;

  @override
  State<PortfolioCountryMap> createState() => _PortfolioCountryMapState();
}

class _PortfolioCountryMapState extends State<PortfolioCountryMap> {
  MapShapeSource? _source;
  List<_MapCountry> _allCountries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PortfolioCountryMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.countries != widget.countries ||
        oldWidget.isDark != widget.isDark) {
      _rebuildSource();
    }
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/maps/country_data.json');
      final list = jsonDecode(raw) as List<dynamic>;
      _allCountries = list
          .map(
            (e) => _MapCountry(
              id: e['id'] as String,
              name: e['name'] as String,
            ),
          )
          .toList();
      _rebuildSource();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _rebuildSource() {
    if (_allCountries.isEmpty) return;

    final allocById = {
      for (final c in widget.countries)
        if (c.mapId != null) c.mapId!: c.percent,
    };
    final maxVal = widget.countries.isEmpty
        ? 1.0
        : widget.countries.first.percent.clamp(1.0, 100.0);

    setState(() {
      _source = MapShapeSource.asset(
        'assets/maps/world_countries.json',
        shapeDataField: 'id',
        dataCount: _allCountries.length,
        primaryValueMapper: (index) => _allCountries[index].id,
        shapeColorValueMapper: (index) {
          final id = _allCountries[index].id;
          final v = allocById[id] ?? 0;
          return _fill(v, maxVal, widget.isDark);
        },
      );
      _loading = false;
    });
  }

  Color _fill(double value, double max, bool dark) {
    if (value <= 0) {
      return dark ? const Color(0xFF2A3140) : const Color(0xFFE6EAF0);
    }
    final t = (value / max).clamp(0.0, 1.0);
    if (t > 0.66) return HomeUi.accent(dark);
    if (t > 0.33) return HomeUi.accent(dark).withValues(alpha: 0.72);
    return HomeUi.accent(dark).withValues(alpha: 0.45);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    if (_loading || _source == null) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: HomeUi.accent(isDark),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: SfMaps(
        layers: [
          MapShapeLayer(
            source: _source!,
            strokeColor: isDark ? const Color(0xFF151A24) : Colors.white,
            strokeWidth: 0.4,
            tooltipSettings: MapTooltipSettings(
              color: HomeUi.cardBg(isDark),
              strokeColor: HomeUi.borderLight(isDark),
            ),
            shapeTooltipBuilder: (context, index) {
              if (index < 0 || index >= _allCountries.length) {
                return const SizedBox.shrink();
              }
              final c = _allCountries[index];
              final match = widget.countries.where((x) => x.mapId == c.id);
              final pct = match.isEmpty ? 0.0 : match.first.percent;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(
                  pct > 0 ? '${c.name}\n${pct.toStringAsFixed(1)}%' : c.name,
                  style: HomeUi.control(isDark).copyWith(fontSize: 11),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MapCountry {
  const _MapCountry({required this.id, required this.name});
  final String id;
  final String name;
}
