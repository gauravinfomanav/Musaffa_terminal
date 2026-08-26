import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/charts/custom/us_premium_palette.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

/// Clean world exposure map — top-10 countries in green, rest muted grey.
class PremiumMapChart extends StatefulWidget {
  const PremiumMapChart({super.key, required this.dark});

  final bool dark;

  @override
  State<PremiumMapChart> createState() => _PremiumMapChartState();
}

class _PremiumMapChartState extends State<PremiumMapChart> {
  static const Color _greenDeep = Color(0xFF1F7A54);
  static const Color _greenMid = Color(0xFF2F9E6B);
  static const Color _greenSoft = Color(0xFF5BBF8A);
  static const Color _greyLight = Color(0xFFE6EAF0);
  static const Color _greyDark = Color(0xFF2A3140);
  static const Color _strokeLight = Color(0xFFFFFFFF);
  static const Color _strokeDark = Color(0xFF151A24);

  /// World-atlas bounds without Antarctica (~360° × ~139° → aspect ≈ 2.59).
  static const double _mapAspect = 2.6;

  List<_CountryDatum> _countries = const <_CountryDatum>[];
  MapShapeSource? _source;
  int _selectedIndex = -1;
  bool _loading = true;
  String? _error;
  double _maxValue = 1;

  Color _fillFor(double value, bool dark) {
    if (value <= 0) return dark ? _greyDark : _greyLight;
    final double t = (value / _maxValue).clamp(0.0, 1.0);
    if (t > 0.66) return dark ? const Color(0xFF3CB87A) : _greenDeep;
    if (t > 0.33) return dark ? const Color(0xFF4BC78A) : _greenMid;
    return dark ? const Color(0xFF6FD4A0) : _greenSoft;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final String raw =
          await rootBundle.loadString('assets/maps/country_data.json');
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      final List<_CountryDatum> countries = list
          .map(
            (dynamic e) => _CountryDatum(
              id: e['id'] as String,
              name: e['name'] as String,
              value: (e['value'] as num).toDouble(),
            ),
          )
          .toList();

      final double maxValue = countries.fold<double>(
        1,
        (double m, _CountryDatum c) => c.value > m ? c.value : m,
      );

      if (!mounted) return;
      setState(() {
        _countries = countries;
        _maxValue = maxValue;
        _source = MapShapeSource.asset(
          'assets/maps/world_countries.json',
          shapeDataField: 'id',
          dataCount: countries.length,
          primaryValueMapper: (int index) => countries[index].id,
          shapeColorValueMapper: (int index) =>
              _fillFor(countries[index].value, widget.dark),
        );
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to load map data';
      });
    }
  }

  @override
  void didUpdateWidget(covariant PremiumMapChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dark != widget.dark && _countries.isNotEmpty) {
      setState(() {
        _source = MapShapeSource.asset(
          'assets/maps/world_countries.json',
          shapeDataField: 'id',
          dataCount: _countries.length,
          primaryValueMapper: (int index) => _countries[index].id,
          shapeColorValueMapper: (int index) =>
              _fillFor(_countries[index].value, widget.dark),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = widget.dark;
    final Color grey = dark ? _greyDark : _greyLight;
    final Color canvas =
        dark ? const Color(0xFF0F131A) : const Color(0xFFF7F8FA);

    return Container(
      // Tall enough that width/_mapAspect fits without vertical squeeze.
      height: 620,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: UsPremiumPalette.surface(dark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UsPremiumPalette.border(dark)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.28 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: Text(
              'Geographic Exposure',
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
                color: UsPremiumPalette.text(dark),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 6),
            child: Text(
              'Top 10 markets by allocation',
              style: TextStyle(
                fontFamily: Constants.FONT_DEFAULT_NEW,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: UsPremiumPalette.muted(dark),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: canvas,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildBody(dark, grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool dark, Color grey) {
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: UsPremiumPalette.muted(dark),
          ),
        ),
      );
    }
    if (_error != null || _source == null) {
      return Center(
        child: Text(
          _error ?? 'Map unavailable',
          style: TextStyle(
            fontFamily: Constants.FONT_DEFAULT_NEW,
            fontSize: 13,
            color: UsPremiumPalette.muted(dark),
          ),
        ),
      );
    }

    // Give Syncfusion a box matching world aspect so default fit shows
    // the FULL shape file (no zoomPan / no latLngBounds = no north crop).
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double width = constraints.maxWidth;
        double height = width / _mapAspect;
        if (height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height * _mapAspect;
        }
        // Tiny inset so ClipRRect radius doesn't nibble Greenland.
        const double inset = 4;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(inset),
            child: SizedBox(
              width: width - inset * 2,
              height: height - inset * 2,
              child: SfMaps(
                layers: <MapLayer>[
                  MapShapeLayer(
                    source: _source!,
                    // No zoomPanBehavior / initialLatLngBounds —
                    // Syncfusion auto-fits every shape into this box.
                    color: grey,
                    strokeColor: dark ? _strokeDark : _strokeLight,
                    strokeWidth: 0.45,
                    selectedIndex: _selectedIndex,
                    onSelectionChanged: (int index) {
                      setState(() => _selectedIndex = index);
                    },
                    selectionSettings: MapSelectionSettings(
                      color: _greenDeep.withValues(alpha: dark ? 0.92 : 0.95),
                      strokeColor: Colors.white,
                      strokeWidth: 1.25,
                    ),
                    tooltipSettings: MapTooltipSettings(
                      color: UsPremiumPalette.surface(dark),
                      strokeColor: UsPremiumPalette.border(dark),
                      strokeWidth: 1,
                    ),
                    shapeTooltipBuilder: (BuildContext context, int index) {
                      if (index < 0 || index >= _countries.length) {
                        return const SizedBox.shrink();
                      }
                      final _CountryDatum c = _countries[index];
                      if (c.value <= 0) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Text(
                            c.name,
                            style: TextStyle(
                              fontFamily: Constants.FONT_DEFAULT_NEW,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: UsPremiumPalette.text(dark),
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              c.name,
                              style: TextStyle(
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: UsPremiumPalette.text(dark),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              c.value.toStringAsFixed(1),
                              style: TextStyle(
                                fontFamily: Constants.FONT_DEFAULT_NEW,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: dark
                                    ? const Color(0xFF3CB87A)
                                    : _greenDeep,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CountryDatum {
  const _CountryDatum({
    required this.id,
    required this.name,
    required this.value,
  });

  final String id;
  final String name;
  final double value;
}
