import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/portfolio/utils/allocation_format.dart';
import 'package:musaffa_terminal/utils/constants.dart';

/// Visual tokens for dashboard and shared card surfaces.
class HomeUi {
  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 10;
  static const double radiusCard = 16;
  static const double radiusPill = 100;
  static const EdgeInsets cardPadding = EdgeInsets.fromLTRB(18, 16, 18, 16);

  static const double controlHeight = 36;
  static const double filterFieldHeight = 40;
  static const double indicesStripHeight = 32;

  /// Even sizes so glyphs land on pixel boundaries at 1x–3x DPR.
  static const double iconXs = 12;
  static const double iconSm = 14;
  static const double iconMd = 16;
  static const double iconLg = 20;
  static const double iconXl = 24;

  static Color pageBg(bool dark) =>
      dark ? const Color(0xFF0C0D0F) : const Color(0xFFF5F6F8);

  static Color headerBg(bool dark) =>
      dark ? const Color(0xFF121417) : const Color(0xFFFFFFFF);

  static Color cardBg(bool dark) =>
      dark ? const Color(0xFF14161A) : const Color(0xFFFFFFFF);

  static Color elevatedBg(bool dark) =>
      dark ? const Color(0xFF1A1D22) : const Color(0xFFF3F4F6);

  static Color border(bool dark) =>
      dark ? const Color(0xFF2A2E34) : const Color(0xFFE6E8EC);

  static Color borderLight(bool dark) =>
      dark ? const Color(0xFF2A2E34) : const Color(0xFFE8EAED);

  static Color borderStrong(bool dark) =>
      dark ? const Color(0xFF3A4048) : const Color(0xFFD5D8DE);

  static Color title(bool dark) =>
      dark ? const Color(0xFFF4F5F7) : const Color(0xFF111827);

  static Color body(bool dark) =>
      dark ? const Color(0xFFC9CDD4) : const Color(0xFF4B5563);

  static Color muted(bool dark) =>
      dark ? const Color(0xFF8B929C) : const Color(0xFF6B7280);

  static Color accent(bool dark) =>
      dark ? const Color(0xFF8FB4D4) : const Color(0xFF1F4E79);

  /// Infomanav wordmark: orange “i” into navy–crimson.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE4681F),
      Color(0xFFDB3E20),
      Color(0xFFC42329),
      Color(0xFF88123E),
      Color(0xFF1F2760),
    ],
    stops: [0.0, 0.22, 0.45, 0.72, 1.0],
  );

  /// Quiet well behind section icons — light grey, never brand.
  static const LinearGradient iconWellGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x14787F8C),
      Color(0x1A6B7280),
    ],
  );

  static const Color iconWellBorder = Color(0x336B7280);

  static const Color buttonBorder = Color(0xE3E4621E);

  /// Homepage card icon well — soft multi-stop brand wash (very light).
  static const LinearGradient softBrandWellGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[
      Color(0x17E4621E), // rgba(228, 98, 30, 0.09)
      Color(0x1AD2364C), // rgba(210, 54, 76, 0.10)
      Color(0x1AA72669), // rgba(167, 38, 105, 0.10)
      Color(0x1A6A2C72), // rgba(106, 44, 114, 0.10)
      Color(0x1A232C64), // rgba(35, 44, 100, 0.10)
    ],
    stops: <double>[0.0, 0.25, 0.50, 0.75, 1.0],
  );

  /// Soft brand glyph tint for homepage-style decorative icons.
  static const LinearGradient softBrandIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      Color(0xFFE2A88A),
      Color(0xFFD0909A),
      Color(0xFFB890B0),
      Color(0xFF9898B8),
      Color(0xFF888EB0),
    ],
  );

  /// Muted glyph for decorative wells. Brand color is reserved for real focus.
  static const LinearGradient quietIconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF9CA3AF),
      Color(0xFF6B7280),
    ],
  );

  static const LinearGradient iconFillGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xE3E4621E),
      Color(0xFFD2364C),
      Color(0xFFA72669),
      Color(0xFF6A2C72),
      Color(0xFF232C64),
    ],
    stops: [0.0, 0.25, 0.50, 0.75, 1.0],
  );

  /// Faded brand fill for chart bars — same stops as [iconFillGradient].
  static LinearGradient chartBarGradient(bool dark) {
    final base = dark ? const Color(0xFF14161A) : const Color(0xFFFFFFFF);
    final amount = dark ? 0.62 : 0.50;
    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        for (final color in iconFillGradient.colors)
          Color.lerp(base, color, amount)!,
      ],
      stops: iconFillGradient.stops,
    );
  }

  static BoxDecoration primaryButton({double radius = radiusPill}) {
    return BoxDecoration(
      gradient: iconFillGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: buttonBorder, width: 0.856),
    );
  }

  static TextStyle primaryActionLabel() => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1,
        letterSpacing: 0.1,
        color: Colors.white,
      );

  static Widget primaryAction({
    required String label,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: primaryButton(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(label, style: primaryActionLabel()),
            ],
          ),
        ),
      ),
    );
  }

  /// Shared shell for header Menu / Search / Watchlist — same height and chrome.
  static BoxDecoration headerControlDecoration(
    bool dark, {
    bool hover = false,
    bool active = false,
  }) {
    final highlighted = hover || active;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radiusMd),
      border: Border.all(
        color: highlighted ? borderStrong(dark) : borderLight(dark),
        width: 0.9,
      ),
      color: highlighted
          ? (dark ? Colors.white.withValues(alpha: 0.10) : const Color(0xFFF8FAFC))
          : null,
      gradient: highlighted
          ? null
          : LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dark
                  ? [const Color(0xFF1A1D22), const Color(0xFF13161A)]
                  : [Colors.white, const Color(0xFFF6F7F9)],
            ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.16 : 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static TextStyle headerControlLabel(bool dark, {bool active = false}) =>
      TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1,
        letterSpacing: 0.1,
        color: active
            ? (dark ? const Color(0xFFF3F4F6) : const Color(0xFF111827))
            : (dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
      );

  /// Outlined header control — same height as [primaryAction].
  static Widget ghostAction({
    required String label,
    required VoidCallback? onTap,
    required bool dark,
    IconData? icon,
  }) {
    return _GhostAction(
      label: label,
      onTap: onTap,
      dark: dark,
      icon: icon,
    );
  }

  /// Compact table footer control for collapsed row lists.
  static Widget expandToggle({
    required bool dark,
    required bool expanded,
    required VoidCallback onTap,
    int remaining = 0,
  }) {
    return Center(
      child: _ExpandToggle(
        dark: dark,
        expanded: expanded,
        remaining: remaining,
        onTap: onTap,
      ),
    );
  }

  /// Quiet grey glyph for decorative wells (no ShaderMask raster).
  static Widget brandIcon({
    required IconData icon,
    double size = iconSm,
    LinearGradient? gradient,
  }) {
    final s = size.roundToDouble();
    return SizedBox(
      width: s,
      height: s,
      child: CustomPaint(
        painter: _BrandGlyphPainter(
          icon: icon,
          glyphSize: s,
          gradient: gradient ?? quietIconGradient,
        ),
      ),
    );
  }

  static Widget brandGraphic({
    required Widget child,
    double size = iconSm,
  }) {
    final s = size.roundToDouble();
    return SizedBox(
      width: s,
      height: s,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  static Widget vectorIcon({
    required IconData icon,
    double size = iconMd,
    Color? color,
  }) {
    final s = size.roundToDouble();
    return SizedBox(
      width: s,
      height: s,
      child: Icon(icon, size: s, color: color),
    );
  }

  static Color tableHeaderBg(bool dark) =>
      dark ? const Color(0xFF16191E) : const Color(0xFFF3F5F9);

  /// Zebra body rows — white / soft blush (light), muted slate pair (dark).
  static Color tableRowEven(bool dark) =>
      dark ? const Color(0xFF16191E) : const Color(0xFFFFFFFF);

  static Color tableRowOdd(bool dark) =>
      dark ? const Color(0xFF171A1C) : const Color(0xFFF8FDFF);

  static Color tableRowHover(bool dark) =>
      dark ? const Color(0xFF1E232A) : const Color(0xFFECF7FB);

  /// Table grid / inner borders.
  static Color tableBorder(bool dark) =>
      dark ? const Color(0xFF2A2E34) : const Color(0xFFE6EAF0);

  static TextStyle tableHeader(bool dark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.55,
        height: 1.2,
        color: dark ? muted(dark) : const Color(0xFF48525D),
      );

  static TextStyle tableCell(bool dark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: -0.1,
        color: title(dark),
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle tableNumeric(bool dark, {bool? positiveValue}) {
    final color = positiveValue == null
        ? body(dark)
        : (positiveValue ? positive(dark) : negative(dark));
    return TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontFamilyFallback: Constants.FONT_FALLBACK,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.15,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Primary metrics — price, market cap (dark text, optional inset).
  static TextStyle tableCellEmphasis(bool dark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.2,
        color: title(dark),
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Supporting columns — sector, labels (lighter).
  static TextStyle tableCellSecondary(bool dark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        height: 1.3,
        letterSpacing: -0.1,
        color: muted(dark),
      );

  static String _normTableKey(String key) =>
      key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Headline money / size metrics — darker, heavier.
  static bool isEmphasisTableColumn(String key) {
    final k = _normTableKey(key);
    const keys = {
      'price',
      'pricedisplay',
      'currentprice',
      'marketcap',
      'usdmarketcap',
      'addedprice',
      'target',
      'targetprice',
      'current',
      'capital',
      'holdings',
      'allocation',
      'returns',
      'enterprisevalue',
      'ev',
      'revenue',
      'revenueannual',
      'netincome',
      'netincomeannual',
    };
    if (keys.contains(k)) return true;
    if (k.endsWith('marketcap') || k.contains('enterprisevalue')) return true;
    if ((k.contains('revenue') || k.contains('netincome')) &&
        !k.contains('growth') &&
        !k.contains('change')) {
      return true;
    }
    return false;
  }

  /// Supporting / meta columns — muted grey for premium hierarchy.
  static bool isSecondaryTableColumn(String key) {
    if (isEmphasisTableColumn(key)) return false;
    final k = _normTableKey(key);
    const keys = {
      'sector',
      'recommendation',
      'rec',
      'industry',
      'country',
      'exchange',
      'analyst',
      'researchorg',
      'dateadded',
      'client',
      'updated',
      'volume',
      'avgvol10d',
      'beta',
      'notes',
      'shares',
      'sharesoutstanding',
      'pettm',
      'pe',
      'pb',
      'ps',
      'peg',
      'dividendyield',
      'divyld',
      'divyield',
      'currentdividendyieldttm',
      'epsttm',
      'eps',
    };
    if (keys.contains(k)) return true;
    if (k.contains('volume') || k.contains('avgvol')) return true;
    if (k == 'beta' || k.endsWith('beta')) return true;
    if (k.startsWith('pe') || k.contains('peratio') || k.contains('pettm')) {
      return true;
    }
    if (k.contains('dividend') || k.contains('divyld') || k.contains('divyield')) {
      return true;
    }
    if (k.contains('shares') || k.contains('float')) return true;
    if (k.contains('sector') ||
        k.contains('industry') ||
        k.contains('country') ||
        k.contains('exchange')) {
      return true;
    }
    if (k.contains('recommendation') || k.endsWith('rec')) return true;
    if (k.contains('date') ||
        k.contains('notes') ||
        k.contains('comment') ||
        k.contains('analyst')) {
      return true;
    }
    if (k.contains('pbratio') ||
        k.contains('psratio') ||
        k.contains('pegratio') ||
        k == 'pb' ||
        k == 'ps' ||
        k == 'peg') {
      return true;
    }
    // Generic ratios / TTM supporting stats (not headline P&L).
    if ((k.contains('ratio') || k.endsWith('ttm') || k.contains('ttm')) &&
        !k.contains('revenue') &&
        !k.contains('income') &&
        !k.contains('price')) {
      return true;
    }
    return false;
  }

  /// Long text labels that need a wider floor (not short enums like REC).
  static bool isWideLabelTableColumn(String key) {
    const keys = {
      'sector',
      'industry',
      'country',
      'exchange',
    };
    return keys.contains(key);
  }

  /// Currency / price values — never character-truncate; keep a usable width floor.
  static bool isPriceTableColumn(String key) {
    final k = key.toLowerCase();
    return k == 'price' ||
        k == 'currentprice' ||
        k == 'addedprice' ||
        k == 'targetprice' ||
        k == 'marketcap' ||
        k == 'current';
  }

  /// Short status / enum columns — keep tight; do not absorb stretch space.
  static bool isCompactTableColumn(String key) {
    final String k = key.toLowerCase();
    return k == 'recommendation' ||
        k == 'rec' ||
        k.endsWith('_rec') ||
        k.contains('recommendation');
  }

  /// Long prose (notes/comments) may ellipsize. Short labels/values must not.
  static bool isCommentLikeTableText(String text, {String? columnKey}) {
    final key = (columnKey ?? '').toLowerCase();
    if (key.contains('comment') ||
        key.contains('note') ||
        key.contains('desc') ||
        key.contains('narrat') ||
        key.contains('thesis') ||
        key.contains('reason') ||
        key.contains('summary') ||
        key.contains('detail') ||
        key.contains('commentary')) {
      return true;
    }
    final trimmed = text.trim();
    if (trimmed.length > 40) return true;
    final words = trimmed
        .split(RegExp(r'\s+'))
        .where((String word) => word.isNotEmpty)
        .length;
    return words >= 6;
  }

  static const int tableCellMaxChars = 25;
  static const int tableHeaderMaxChars = 10;

  /// Shows up to [maxChars] characters; truncates with ellipsis from the 26th.
  /// Price / currency strings are never truncated.
  static String truncateTableText(
    String text, {
    int maxChars = tableCellMaxChars,
    String? columnKey,
  }) {
    if (columnKey != null && isPriceTableColumn(columnKey)) return text;
    // Bare currency like $213.45 — keep intact even without a column key.
    if (RegExp(r'^\$?\s*-?\d[\d,]*\.?\d*$').hasMatch(text.trim())) {
      return text;
    }
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}…';
  }

  /// Compact header label for dense tables. Full name belongs in a tooltip.
  static String shortTableHeader({
    required String label,
    String? key,
  }) {
    final id = (key ?? '').toLowerCase().trim();
    final byId = <String, String>{
      'enterprisevalue': 'EV',
      'recommendation': 'REC',
      'sharesoutstanding': 'SHARES',
      'marketcap': 'MKT CAP',
      'dividendyield': 'DIV YLD',
      'revenueannual': 'REV',
      'netincome': 'NET INC',
      'change1d': '1D',
      'sparkline': '1D',
      'grossmargin': 'GROSS %',
      'operatingmargin': 'OP MGN',
      'netprofitmargin': 'NPM',
      'currentratio': 'CUR R',
      'quickratio': 'QUICK',
      'assetturnover': 'AT',
      'inventoryturnover': 'INV TO',
      'receivablesturnover': 'AR TO',
      'payoutratio': 'PAYOUT',
      'bookvaluepershare': 'BV/SH',
      'bvps': 'BV/SH',
      'dividendpershare': 'DIV/SH',
      'cashflowpershare': 'CF/SH',
      'epsannual': 'EPS Y',
      'epsttm': 'EPS',
      'pettm': 'P/E',
      'peannual': 'P/E Y',
      'pbannual': 'P/B',
      'psttm': 'P/S',
      'psannual': 'P/S Y',
      'evebit': 'EV/EBIT',
      'evfcf': 'EV/FCF',
      'pfcfttm': 'P/FCF',
      'pcfttm': 'P/CF',
      'ptbvannual': 'P/TBV',
      'priceTangibleBook': 'P/TB',
      'pricetangiblebook': 'P/TB',
      'roaTtm': 'ROA',
      'roattm': 'ROA',
      'debtToEquity': 'D/E',
      'debttoequity': 'D/E',
      'debtEquity': 'D/E',
      'avgvol10d': 'VOL 10D',
      'avgvol30d': 'VOL 30D',
      'mktcapchg3y': 'MC 3Y',
      'previousclose': 'PREV',
      'revgrowth3y': 'REV 3Y',
      'revgrowth5y': 'REV 5Y',
      'epsgrowth3y': 'EPS 3Y',
      'epsgrowth5y': 'EPS 5Y',
      'revgrowthqoq': 'REV QoQ',
      'revgrowthttm': 'REV TTM',
      'epsgrowthqoq': 'EPS QoQ',
      'epsgrowthttm': 'EPS TTM',
      'revsharegrowth5y': 'R/S 5Y',
      'roe5y': 'ROE 5Y',
      'roa5y': 'ROA 5Y',
      'revenuegrowth1y': 'REV 1Y',
      'revenueshare': 'REV/SH',
      '52whigh': '52W H',
      '52wlow': '52W L',
      'range52': '52W RANGE',
      'range52w': '52W RANGE',
      'high52w': '52W H',
      'low52w': '52W L',
      'analystrec': 'REC',
    };
    if (id.isNotEmpty && byId.containsKey(id)) {
      return byId[id]!;
    }

    final normalized = label.toLowerCase().trim();
    final byLabel = <String, String>{
      'enterprise value': 'EV',
      'analyst rec': 'REC',
      'shares out': 'SHARES',
      'market cap': 'MKT CAP',
      'div yield': 'DIV YLD',
      'revenue annual': 'REV',
      'net income': 'NET INC',
      'change %': '1D',
      'chg %': '1D',
      'gross margin': 'GROSS %',
      'operating margin': 'OP MGN',
      'net profit margin': 'NPM',
      'current ratio': 'CUR R',
      'quick ratio': 'QUICK',
      'asset turnover': 'AT',
      'inventory turnover': 'INV TO',
      'receivables turnover': 'AR TO',
      'payout ratio': 'PAYOUT',
      'book value/share': 'BV/SH',
      'dividend/share': 'DIV/SH',
      'cash flow/share': 'CF/SH',
      'eps annual': 'EPS Y',
      'eps ttm': 'EPS',
      'p/e ttm': 'P/E',
      'p/e annual': 'P/E Y',
      'p/b annual': 'P/B',
      'p/s ttm': 'P/S',
      'p/s annual': 'P/S Y',
      'p/fcf ttm': 'P/FCF',
      'p/cf ttm': 'P/CF',
      'p/tbv annual': 'P/TBV',
      'price/tangible book': 'P/TB',
      'roa ttm': 'ROA',
      'debt/equity': 'D/E',
      'avg vol 10d': 'VOL 10D',
      'avg vol 30d': 'VOL 30D',
      'mkt cap chg 3y': 'MC 3Y',
      'previous close': 'PREV',
      'rev growth 3y': 'REV 3Y',
      'rev growth 5y': 'REV 5Y',
      'eps growth 3y': 'EPS 3Y',
      'eps growth 5y': 'EPS 5Y',
      'rev growth qoq': 'REV QoQ',
      'rev growth ttm': 'REV TTM',
      'eps growth qoq': 'EPS QoQ',
      'eps growth ttm': 'EPS TTM',
      'rev/share growth 5y': 'R/S 5Y',
      'revenue growth 1y': 'REV 1Y',
      'revenue/share': 'REV/SH',
      '52w high': '52W H',
      '52w low': '52W L',
    };
    if (byLabel.containsKey(normalized)) {
      return byLabel[normalized]!;
    }

    if (label.length <= tableHeaderMaxChars) return label;
    return truncateTableText(label, maxChars: tableHeaderMaxChars);
  }

  static TextOverflow tableCellOverflow(String text, {String? columnKey}) {
    if (columnKey != null && isPriceTableColumn(columnKey)) {
      return TextOverflow.visible;
    }
    return isCommentLikeTableText(text, columnKey: columnKey)
        ? TextOverflow.ellipsis
        : TextOverflow.clip;
  }

  static Widget signedPercentPill(bool dark, String text, double value) {
    final positive = value > 0 ? true : value < 0 ? false : null;
    final display = truncateTableText(text);
    final child = Text(
      display,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: tableNumeric(dark, positiveValue: positive),
    );
    if (display == text) return child;
    return premiumTooltip(message: text, child: child);
  }

  /// Dark premium tooltip used across tables and chrome.
  static Widget premiumTooltip({
    required String message,
    required Widget child,
    bool? dark,
    Duration waitDuration = const Duration(milliseconds: 350),
    Duration showDuration = const Duration(seconds: 4),
    bool preferBelow = true,
    double verticalOffset = 12,
  }) {
    return Builder(
      builder: (BuildContext context) {
        final bool isDark =
            dark ?? Theme.of(context).brightness == Brightness.dark;
        return Tooltip(
          message: message,
          waitDuration: waitDuration,
          showDuration: showDuration,
          preferBelow: preferBelow,
          verticalOffset: verticalOffset,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: premiumTooltipDecoration(isDark),
          textStyle: premiumTooltipTextStyle(isDark),
          child: child,
        );
      },
    );
  }

  static BoxDecoration premiumTooltipDecoration(bool dark) {
    return BoxDecoration(
      color: dark ? const Color(0xFF1A1D22) : const Color(0xFF111827),
      borderRadius: BorderRadius.circular(radiusMd),
      border: Border.all(
        color: dark ? const Color(0xFF3A4048) : const Color(0xFF1F2937),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: dark ? 0.40 : 0.18),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static TextStyle premiumTooltipTextStyle(bool dark) {
    return TextStyle(
      fontFamily: Constants.FONT_DEFAULT_NEW,
      fontFamilyFallback: Constants.FONT_FALLBACK,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.3,
      color: dark ? const Color(0xFFF3F4F6) : Colors.white,
    );
  }

  static Color accentSoft(bool dark) => dark
      ? const Color(0xFF8FB4D4).withOpacity(0.10)
      : const Color(0xFF1F4E79).withOpacity(0.07);

  static Color positive(bool dark) =>
      dark ? const Color(0xFF34D399) : const Color(0xFF059669);

  static Color negative(bool dark) =>
      dark ? const Color(0xFFF87171) : const Color(0xFFDC2626);

  static Color positiveSoft(bool dark) =>
      dark ? const Color(0xFF34D399).withOpacity(0.10) : const Color(0xFFF3FBF6);

  static Color negativeSoft(bool dark) =>
      dark ? const Color(0xFFF87171).withOpacity(0.10) : const Color(0xFFFDF6F6);

  static List<BoxShadow> cardShadow(bool dark, {bool hover = false}) {
    if (dark) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(hover ? 0.28 : 0.18),
          blurRadius: hover ? 10 : 6,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(hover ? 0.07 : 0.04),
        blurRadius: hover ? 10 : 6,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> headerShadow(bool dark) => [
        BoxShadow(
          color: Colors.black.withOpacity(dark ? 0.22 : 0.035),
          blurRadius: 10,
          offset: const Offset(0, 1),
        ),
      ];

  static BoxDecoration cardDecoration(bool dark, {bool hover = false}) =>
      BoxDecoration(
        color: cardBg(dark),
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border.all(
          color: hover ? borderStrong(dark) : borderLight(dark),
          width: 1,
        ),
        boxShadow: cardShadow(dark, hover: hover),
      );

  /// Premium date picker with brand gradient selection and actions.
  static Future<DateTime?> pickDate(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    final clamped = initialDate.isBefore(firstDate)
        ? firstDate
        : (initialDate.isAfter(lastDate) ? lastDate : initialDate);

    return showGeneralDialog<DateTime>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Select date',
      barrierColor: Colors.black.withValues(alpha: 0.46),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: _PremiumDatePicker(
              initialDate: clamped,
              firstDate: firstDate,
              lastDate: lastDate,
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static TextStyle overline(bool dark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        height: 1.2,
        color: muted(dark),
      );

  static TextStyle display(bool dark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.8,
        height: 1.15,
        color: title(dark),
      );

  static TextStyle heading(bool dark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.35,
        height: 1.2,
        color: title(dark),
      );

  static TextStyle sectionTitle(bool dark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        height: 1.25,
        color: title(dark),
      );

  /// Alias — same style whether the title sits inside or above a card.
  static TextStyle cardTitle(bool dark) => sectionTitle(dark);

  /// Label above screener-style filter controls.
  static TextStyle filterFieldLabelStyle(bool dark) => label(dark).copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        height: 1.2,
      );

  /// Outer + inner shell matching [ScreenerDropdown] field height and shadow.
  static Widget filterFieldShell({
    required bool dark,
    required Widget child,
    bool accent = false,
    bool hover = false,
    double? height,
    double radius = 10,
    EdgeInsetsGeometry? padding,
    AlignmentGeometry alignment = Alignment.centerLeft,
  }) {
    final showAccent = accent;
    final showHover = hover && !accent;
    final innerHeight = height ?? filterFieldHeight;
    final innerRadius = (radius - (showAccent ? 1.5 : 1)).clamp(0.0, radius);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: showAccent ? iconFillGradient : null,
        color: showAccent
            ? null
            : (showHover ? borderStrong(dark) : borderLight(dark)),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: dark
                  ? (showAccent ? 0.28 : (showHover ? 0.20 : 0.16))
                  : (showAccent ? 0.08 : (showHover ? 0.06 : 0.04)),
            ),
            blurRadius: showAccent ? 12 : (showHover ? 10 : 8),
            offset: Offset(0, showAccent ? 4 : 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(showAccent ? 1.5 : 1),
      child: Container(
        height: innerHeight,
        decoration: BoxDecoration(
          color: cardBg(dark),
          borderRadius: BorderRadius.circular(innerRadius),
        ),
        padding: padding ?? const EdgeInsets.only(left: 12, right: 8),
        alignment: alignment,
        child: child,
      ),
    );
  }

  static Widget filterChevron(bool dark) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: elevatedBg(dark),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 16,
        color: muted(dark),
      ),
    );
  }

  static Widget filterFieldColumn({
    required bool dark,
    required String label,
    required Widget field,
    Widget? labelTrailing,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: filterFieldLabelStyle(dark)),
            ),
            if (labelTrailing != null) labelTrailing,
          ],
        ),
        const SizedBox(height: 8),
        field,
        if (errorText != null && errorText.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: TextStyle(
              fontFamily: Constants.FONT_DEFAULT_NEW,
              fontFamilyFallback: Constants.FONT_FALLBACK,
              fontSize: 11.5,
              color: negative(dark),
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  static InputDecoration filterTextFieldDecoration(
    bool dark, {
    String? hintText,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: control(dark).copyWith(
        fontSize: 13,
        color: muted(dark),
      ),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      isCollapsed: true,
    );
  }

  /// Premium form field decoration — matches screener filter fields.
  static InputDecoration filterFieldDecoration(
    bool dark, {
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? errorText,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      isDense: true,
      labelStyle: label(dark).copyWith(fontSize: 12),
      floatingLabelStyle: label(dark).copyWith(
        fontSize: 12,
        color: muted(dark),
      ),
      hintStyle: control(dark).copyWith(fontSize: 13),
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixIcon != null
          ? const BoxConstraints(minWidth: 40, minHeight: 40)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: elevatedBg(dark),
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: borderLight(dark)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: borderLight(dark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: const BorderSide(color: buttonBorder),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: negative(dark)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMd),
        borderSide: BorderSide(color: negative(dark)),
      ),
    );
  }

  /// Popup / context menu row with brand icon well.
  static Widget actionMenuItem({
    required bool dark,
    required IconData icon,
    required String label,
    bool destructive = false,
  }) {
    final tint = destructive ? negative(dark) : null;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: destructive ? null : iconWellGradient,
            color: destructive ? negative(dark).withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: destructive
                  ? negative(dark).withValues(alpha: 0.28)
                  : iconWellBorder,
            ),
          ),
          child: destructive
              ? Icon(icon, size: 14, color: negative(dark))
              : brandIcon(icon: icon, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: control(dark, active: true).copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tint,
            ),
          ),
        ),
      ],
    );
  }

  /// Left header inside a table card — icon well + title + optional subtitle.
  static Widget tableToolbarHeader(
    bool dark, {
    required String title,
    String? subtitleText,
    Widget? subtitle,
    IconData? icon,
    double titleFontSize = 16,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: softBrandWellGradient,
            ),
            child: brandIcon(
              icon: icon,
              size: iconMd,
              gradient: softBrandIconGradient,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: cardTitle(dark).copyWith(
                  fontSize: titleFontSize,
                  height: 1.15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                DefaultTextStyle.merge(
                  style: HomeUi.subtitle(dark).copyWith(
                    fontSize: 12,
                    height: 1.25,
                  ),
                  child: subtitle,
                ),
              ] else if (subtitleText != null && subtitleText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitleText,
                  style: HomeUi.subtitle(dark).copyWith(
                    fontSize: 12,
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Read-only summary tile for detail modals — premium glass card style.
  static Widget detailSummaryMetric({
    required bool dark,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [const Color(0xFF1A1D2E), const Color(0xFF151822)]
              : [const Color(0xFFF9FAFB), const Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark
              ? const Color(0xFF2A2D3E).withValues(alpha: 0.8)
              : const Color(0xFFE5E7EB).withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFF6366F1).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          decorativeCardSparkline(dark: dark, seed: label, height: 44),
          Padding(
            // Extra bottom space so value text clears the sparkline.
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 52),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: dark
                        ? const Color(0xFF8B8FA3)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: tableCellEmphasis(dark).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Full-width decorative sparkline for summary cards (very light grey).
  static Widget decorativeCardSparkline({
    required bool dark,
    required String seed,
    double height = 56,
  }) {
    final Color lineColor = dark
        ? const Color(0xFF6B7280).withValues(alpha: 0.28)
        : const Color(0xFFE8EAED);
    final Color fillColor = dark
        ? const Color(0xFF6B7280).withValues(alpha: 0.06)
        : const Color(0xFFF1F4F8).withValues(alpha: 0.90);

    return Positioned(
      left: 0,
      right: 0,
      bottom: -2,
      height: height,
      child: IgnorePointer(
        child: CustomPaint(
          painter: _DecorativeSparklinePainter(
            values: _sparklineSeriesFor(seed),
            lineColor: lineColor,
            fillColor: fillColor,
          ),
        ),
      ),
    );
  }

  static List<double> _sparklineSeriesFor(String seed) {
    switch (seed.toLowerCase()) {
      case 'p/e ratio':
      case 'latest analysts':
        return const [0.42, 0.38, 0.48, 0.44, 0.55, 0.52, 0.62, 0.58, 0.72, 0.78];
      case 'roe':
      case 'trend':
        return const [0.35, 0.48, 0.40, 0.55, 0.50, 0.68, 0.60, 0.74, 0.70, 0.86];
      case 'current consensus':
        return const [0.45, 0.40, 0.52, 0.48, 0.60, 0.55, 0.68, 0.64, 0.76, 0.82];
      default:
        return const [0.40, 0.35, 0.48, 0.42, 0.58, 0.52, 0.66, 0.60, 0.78, 0.88];
    }
  }

  /// Grouped read-only rows — label left, value right.
  static Widget detailPanel({
    required bool dark,
    required String title,
    required List<(String label, String value)> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        // Match modal / summary cards — avoid elevated grey wash.
        color: cardBg(dark),
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: borderLight(dark)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Text(
              title,
              style: sectionTitle(dark).copyWith(fontSize: 13),
            ),
          ),
          Divider(height: 1, color: borderLight(dark)),
          ...List.generate(rows.length, (index) {
            final (label, value) = rows[index];
            return Column(
              children: [
                if (index > 0)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: borderLight(dark).withValues(alpha: 0.65),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(label, style: tableCellSecondary(dark)),
                      ),
                      Expanded(
                        flex: 6,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            value,
                            textAlign: TextAlign.right,
                            style: tableCellEmphasis(dark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Accent callout for commentary / notes in detail views.
  static Widget detailCallout({
    required bool dark,
    required String label,
    required String body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: elevatedBg(dark),
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: borderLight(dark)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            constraints: const BoxConstraints(minHeight: 40),
            decoration: BoxDecoration(
              gradient: brandGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: overline(dark).copyWith(
                    fontSize: 10,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: bodyText(dark).copyWith(height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static TextStyle bodyText(bool dark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: body(dark),
      );

  /// Label-free pill segmented control — Overview / Financial / Charts style.
  static Widget segmentedControl({
    required bool dark,
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
  }) {
    final index = options.isEmpty
        ? 0
        : selectedIndex.clamp(0, options.length - 1);

    return filterFieldShell(
      dark: dark,
      height: filterFieldHeight,
      radius: radiusPill,
      padding: const EdgeInsets.all(3),
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = options.length;
          final segmentWidth =
              count > 0 ? constraints.maxWidth / count : constraints.maxWidth;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                left: index * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: primaryButton(radius: radiusPill),
                ),
              ),
              Row(
                children: List.generate(count, (i) {
                  final isSelected = i == index;
                  return Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Center(
                          child: Text(
                            options[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: control(dark, active: true).copyWith(
                              fontSize: 11.5,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : body(dark),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Subtle pill segmented control — selected state uses surface tint, not brand gradient.
  static Widget segmentedControlLight({
    required bool dark,
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
    double height = 32,
  }) {
    final index = options.isEmpty
        ? 0
        : selectedIndex.clamp(0, options.length - 1);

    return Container(
      height: height,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: elevatedBg(dark),
        borderRadius: BorderRadius.circular(radiusPill),
        border: Border.all(color: borderLight(dark)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = options.length;
          final segmentWidth =
              count > 0 ? constraints.maxWidth / count : constraints.maxWidth;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                left: index * segmentWidth,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cardBg(dark),
                    borderRadius: BorderRadius.circular(radiusPill),
                    border: Border.all(
                      color: accent(dark).withValues(alpha: dark ? 0.28 : 0.22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: dark ? 0.12 : 0.05,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: List.generate(count, (i) {
                  final isSelected = i == index;
                  return Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Center(
                          child: Text(
                            options[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: control(dark, active: true).copyWith(
                              fontSize: 11,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? accent(dark) : muted(dark),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Brand-themed allocation progress card for portfolio builder.
  static Widget allocationProgressCard({
    required bool dark,
    required String title,
    required String amountLabel,
    required double percentage,
    IconData icon = Icons.donut_large_rounded,
  }) {
    final normalized = percentage / 100;
    final isComplete = isAllocationBalanced(percentage);
    final isOver = isAllocationOver(percentage);
    final chipColor = isComplete
        ? const Color(0xFF10B981)
        : isOver
            ? negative(dark)
            : const Color(0xFFC42329);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: elevatedBg(dark),
        borderRadius: BorderRadius.circular(radiusMd),
        border: Border.all(color: borderLight(dark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: iconWellGradient,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: iconWellBorder),
                ),
                child: brandIcon(
                  icon: icon,
                  size: iconSm,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: sectionTitle(dark).copyWith(fontSize: 13)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: iconWellGradient,
                  borderRadius: BorderRadius.circular(radiusPill),
                  border: Border.all(color: iconWellBorder),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: control(dark, active: true).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: chipColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(amountLabel, style: tableCellSecondary(dark)),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: normalized.clamp(0.0, 1.0),
            ),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Container(
                height: 10,
                decoration: BoxDecoration(
                  color: cardBg(dark),
                  borderRadius: BorderRadius.circular(radiusPill),
                  border: Border.all(color: borderLight(dark)),
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fillWidth = value * constraints.maxWidth;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (fillWidth > 0)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            width: fillWidth,
                            decoration: BoxDecoration(
                              gradient: isComplete || isOver ? null : iconFillGradient,
                              color: isComplete
                                  ? const Color(0xFF10B981)
                                  : isOver
                                      ? negative(dark)
                                      : null,
                              borderRadius: BorderRadius.circular(radiusPill),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Compact inline field styling for editable table cells.
  static InputDecoration tableInlineFieldDecoration(
    bool dark, {
    String hintText = '--',
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: control(dark).copyWith(
        fontSize: 12,
        color: muted(dark),
      ),
      filled: true,
      fillColor: cardBg(dark),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: BorderSide(color: borderLight(dark)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: BorderSide(color: borderLight(dark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSm),
        borderSide: const BorderSide(color: buttonBorder, width: 1.2),
      ),
    );
  }

  static TextStyle subtitle(bool dark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: muted(dark),
      );

  static TextStyle label(bool dark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.2,
        color: muted(dark),
      );

  static TextStyle control(bool dark, {bool active = false}) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1,
        color: active ? title(dark) : muted(dark),
      );

  static TextStyle wordmark(bool dark) => TextStyle(
        fontFamily: Constants.FONT_DEFAULT_NEW,
        fontFamilyFallback: Constants.FONT_FALLBACK,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1,
        color: title(dark),
      );

  static EdgeInsets pagePadding(double width) {
    if (width < 700) return const EdgeInsets.fromLTRB(16, 18, 16, 28);
    if (width < 1200) return const EdgeInsets.fromLTRB(22, 22, 22, 36);
    return const EdgeInsets.fromLTRB(28, 24, 28, 40);
  }

  static double pageGutter(double width) {
    if (width < 700) return 16;
    if (width < 1200) return 22;
    return 28;
  }

  static double sectionGap(double width) => width < 1000 ? 20 : 28;
}

class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.child,
    this.padding,
    this.hover = false,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool hover;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: HomeUi.cardDecoration(dark, hover: hover),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _GhostAction extends StatefulWidget {
  const _GhostAction({
    required this.label,
    required this.onTap,
    required this.dark,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final bool dark;
  final IconData? icon;

  @override
  State<_GhostAction> createState() => _GhostActionState();
}

class _GhostActionState extends State<_GhostAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: HomeUi.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _hover ? HomeUi.elevatedBg(dark) : HomeUi.cardBg(dark),
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            border: Border.all(
              color: _hover
                  ? HomeUi.borderStrong(dark)
                  : HomeUi.borderLight(dark),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: HomeUi.muted(dark)),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: HomeUi.control(dark).copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandToggle extends StatefulWidget {
  const _ExpandToggle({
    required this.dark,
    required this.expanded,
    required this.onTap,
    this.remaining = 0,
  });

  final bool dark;
  final bool expanded;
  final VoidCallback onTap;
  final int remaining;

  @override
  State<_ExpandToggle> createState() => _ExpandToggleState();
}

class _ExpandToggleState extends State<_ExpandToggle> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;
    final label = widget.expanded
        ? 'Show less'
        : widget.remaining > 0
            ? 'Show more · ${widget.remaining}'
            : 'Show more';

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: HomeUi.controlHeight,
          padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
          decoration: BoxDecoration(
            gradient: _hover ? HomeUi.iconWellGradient : null,
            color: _hover ? null : HomeUi.cardBg(dark),
            borderRadius: BorderRadius.circular(HomeUi.radiusPill),
            border: Border.all(
              color: _hover ? HomeUi.iconWellBorder : HomeUi.borderLight(dark),
            ),
            boxShadow: _hover ? HomeUi.cardShadow(dark, hover: true) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: HomeUi.iconWellGradient,
                  shape: BoxShape.circle,
                  border: Border.all(color: HomeUi.iconWellBorder),
                ),
                child: AnimatedRotation(
                  turns: widget.expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: HomeUi.brandIcon(
                    icon: Icons.expand_more_rounded,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: HomeUi.control(dark, active: true).copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandGlyphPainter extends CustomPainter {
  _BrandGlyphPainter({
    required this.icon,
    required this.glyphSize,
    required this.gradient,
  });

  final IconData icon;
  final double glyphSize;
  final LinearGradient gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = gradient.createShader(Offset.zero & size);
    final paint = Paint()
      ..shader = shader
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: glyphSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          foreground: paint,
          height: 1,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        (size.width - painter.width) / 2,
        (size.height - painter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _BrandGlyphPainter oldDelegate) {
    return oldDelegate.icon != icon ||
        oldDelegate.glyphSize != glyphSize ||
        oldDelegate.gradient != gradient;
  }
}

/// Screener-style text field — label above, fixed 40px shell.
class FilterTextField extends StatefulWidget {
  const FilterTextField({
    super.key,
    required this.dark,
    required this.label,
    required this.controller,
    this.hintText,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.readOnly = false,
    this.minLines,
    this.maxLines = 1,
    this.suffix,
    this.prefix,
    this.onChanged,
  });

  final bool dark;
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? errorText;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool readOnly;
  final int? minLines;
  final int maxLines;
  final Widget? suffix;
  final Widget? prefix;
  final ValueChanged<String>? onChanged;

  @override
  State<FilterTextField> createState() => _FilterTextFieldState();
}

class _FilterTextFieldState extends State<FilterTextField> {
  bool _focused = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final multiline = widget.maxLines > 1 || (widget.minLines ?? 1) > 1;
    final shellHeight = multiline ? 96.0 : HomeUi.filterFieldHeight;

    return FormField<String>(
      validator: widget.validator,
      builder: (field) {
        return HomeUi.filterFieldColumn(
          dark: widget.dark,
          label: widget.label,
          errorText: widget.errorText ?? field.errorText,
          field: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: Focus(
              onFocusChange: (focused) => setState(() => _focused = focused),
              child: HomeUi.filterFieldShell(
                dark: widget.dark,
                accent: _focused,
                hover: _hover,
                height: shellHeight,
                padding: multiline
                    ? const EdgeInsets.fromLTRB(12, 10, 12, 10)
                    : null,
                alignment: multiline ? Alignment.topLeft : Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: multiline
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    if (widget.prefix != null) ...[
                      widget.prefix!,
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: TextFormField(
                        controller: widget.controller,
                        keyboardType: widget.keyboardType,
                        readOnly: widget.readOnly,
                        minLines: widget.minLines,
                        maxLines: widget.maxLines,
                        inputFormatters: widget.inputFormatters,
                        cursorColor: HomeUi.title(widget.dark),
                        style: HomeUi.control(widget.dark, active: true)
                            .copyWith(fontSize: 13),
                        decoration: HomeUi.filterTextFieldDecoration(
                          widget.dark,
                          hintText: widget.hintText,
                        ),
                        onChanged: (value) {
                          field.didChange(value);
                          widget.onChanged?.call(value);
                        },
                      ),
                    ),
                    if (widget.suffix != null) widget.suffix!,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Screener-style dropdown — label above, fixed 40px shell.
class FilterDropdown<T> extends StatefulWidget {
  const FilterDropdown({
    super.key,
    required this.dark,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final bool dark;
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  State<FilterDropdown<T>> createState() => _FilterDropdownState<T>();
}

class _FilterDropdownState<T> extends State<FilterDropdown<T>> {
  bool _hover = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return HomeUi.filterFieldColumn(
      dark: widget.dark,
      label: widget.label,
      field: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Focus(
          onFocusChange: (focused) => setState(() => _focused = focused),
          child: HomeUi.filterFieldShell(
            dark: widget.dark,
            hover: _hover,
            accent: _focused,
            child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: widget.value,
              dropdownColor: HomeUi.cardBg(widget.dark),
              borderRadius: BorderRadius.circular(HomeUi.radiusMd),
              icon: HomeUi.filterChevron(widget.dark),
              style: HomeUi.control(widget.dark, active: true).copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              items: widget.items,
              onChanged: widget.onChanged,
            ),
          ),
          ),
        ),
      ),
    );
  }
}

/// Screener-style range slider with aligned 0 / mid / max labels.
class FilterRangeSlider extends StatelessWidget {
  const FilterRangeSlider({
    super.key,
    required this.dark,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.midLabel,
    this.minLabel,
    this.maxLabel,
    this.labelTrailing,
    this.activeColor,
  });

  final bool dark;
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
  final String? midLabel;
  final String? minLabel;
  final String? maxLabel;
  final Widget? labelTrailing;
  final Color? activeColor;

  static const double _thumbRadius = 8;

  @override
  Widget build(BuildContext context) {
    final trackColor = activeColor ?? const Color(0xFFE4681F);

    return HomeUi.filterFieldColumn(
      dark: dark,
      label: label,
      labelTrailing: labelTrailing,
      field: HomeUi.filterFieldShell(
        dark: dark,
        height: 88,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: _thumbRadius),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackShape: _GradientSliderTrackShape(
                    gradient: HomeUi.iconFillGradient,
                    inactiveColor: HomeUi.borderLight(dark),
                  ),
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: HomeUi.borderLight(dark),
                  thumbShape: const _GradientSliderThumbShape(
                    gradient: HomeUi.iconFillGradient,
                    radius: _thumbRadius,
                  ),
                  thumbColor: Colors.transparent,
                  overlayColor: trackColor.withValues(alpha: 0.14),
                  trackHeight: 6,
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                  tickMarkShape: const RoundSliderTickMarkShape(
                    tickMarkRadius: 2,
                  ),
                  activeTickMarkColor: Colors.transparent,
                  inactiveTickMarkColor:
                      HomeUi.muted(dark).withValues(alpha: 0.45),
                ),
                child: Slider(
                  value: value,
                  min: min,
                  max: max,
                  divisions: divisions,
                  label: value.toStringAsFixed(1),
                  onChanged: onChanged,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: _thumbRadius),
              child: SizedBox(
                height: 16,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        minLabel ?? min.toStringAsFixed(0),
                        style: HomeUi.label(dark),
                      ),
                    ),
                    if (midLabel != null)
                      Align(
                        alignment: Alignment.center,
                        child: Text(midLabel!, style: HomeUi.label(dark)),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        maxLabel ?? max.toStringAsFixed(0),
                        style: HomeUi.label(dark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientSliderTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const _GradientSliderTrackShape({
    required this.gradient,
    required this.inactiveColor,
  });

  final LinearGradient gradient;
  final Color inactiveColor;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    if (sliderTheme.trackHeight == null || sliderTheme.trackHeight! <= 0) {
      return;
    }

    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final radius = Radius.circular(trackRect.height / 2);
    final canvas = context.canvas;

    final inactivePaint = Paint()..color = inactiveColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, radius),
      inactivePaint,
    );

    final activeRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx.clamp(trackRect.left, trackRect.right),
      trackRect.bottom,
    );

    if (activeRect.width <= 0) return;

    final activePaint = Paint()..shader = gradient.createShader(activeRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(activeRect, radius),
      activePaint,
    );
  }
}

class _GradientSliderThumbShape extends SliderComponentShape {
  const _GradientSliderThumbShape({
    required this.gradient,
    required this.radius,
  });

  final LinearGradient gradient;
  final double radius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center.translate(0, 1), radius, shadowPaint);

    final fillPaint = Paint()..shader = gradient.createShader(rect);
    canvas.drawCircle(center, radius, fillPaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius, borderPaint);
  }
}

/// Full-width single-row segmented selector — fits inside screener field shell.
class FilterSegmentedSelector extends StatelessWidget {
  const FilterSegmentedSelector({
    super.key,
    required this.dark,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final bool dark;
  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = options.indexOf(selected).clamp(0, options.length - 1);

    return HomeUi.filterFieldColumn(
      dark: dark,
      label: label,
      field: HomeUi.segmentedControl(
        dark: dark,
        options: options,
        selectedIndex: selectedIndex,
        onChanged: (index) => onChanged(options[index]),
      ),
    );
  }
}

class _PremiumDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _PremiumDatePicker({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_PremiumDatePicker> createState() => _PremiumDatePickerState();
}

class _PremiumDatePickerState extends State<_PremiumDatePicker> {
  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _weekdaysLong = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  late DateTime _selected;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _selected = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _visibleMonth = DateTime(_selected.year, _selected.month);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSelectable(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final first = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
      widget.firstDate.day,
    );
    final last = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
      widget.lastDate.day,
    );
    return !d.isBefore(first) && !d.isAfter(last);
  }

  void _shiftMonth(int delta) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    final firstMonth = DateTime(widget.firstDate.year, widget.firstDate.month);
    final lastMonth = DateTime(widget.lastDate.year, widget.lastDate.month);
    if (next.isBefore(firstMonth) || next.isAfter(lastMonth)) return;
    setState(() => _visibleMonth = next);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime.now();
    final headline =
        '${_weekdaysLong[(_selected.weekday + 6) % 7]}, ${_months[_selected.month - 1].substring(0, 3)} ${_selected.day}';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 380),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: BoxDecoration(
          color: HomeUi.cardBg(isDark),
          borderRadius: BorderRadius.circular(HomeUi.radiusCard),
          border: Border.all(color: HomeUi.borderLight(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.10),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: HomeUi.tableToolbarHeader(
                      isDark,
                      icon: Icons.calendar_month_rounded,
                      title: 'Select date',
                      subtitleText: headline,
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: HomeUi.controlHeight,
                        height: HomeUi.controlHeight,
                        decoration: BoxDecoration(
                          color: HomeUi.elevatedBg(isDark),
                          shape: BoxShape.circle,
                          border: Border.all(color: HomeUi.borderLight(isDark)),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: HomeUi.muted(isDark),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: HomeUi.borderLight(isDark)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_months[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                      style: HomeUi.sectionTitle(isDark),
                    ),
                  ),
                  _MonthNavButton(
                    isDark: isDark,
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _shiftMonth(-1),
                  ),
                  const SizedBox(width: 4),
                  _MonthNavButton(
                    isDark: isDark,
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _shiftMonth(1),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Column(
                children: [
                  Row(
                    children: _weekdays
                        .map(
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: HomeUi.overline(isDark).copyWith(
                                  fontSize: 10,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                  ..._buildWeeks(isDark, today),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Divider(height: 1, color: HomeUi.borderLight(isDark)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: HomeUi.ghostAction(
                      label: 'Cancel',
                      dark: isDark,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: HomeUi.primaryAction(
                      label: 'OK',
                      onTap: () => Navigator.of(context).pop(_selected),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWeeks(bool isDark, DateTime today) {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final leading = first.weekday % 7;
    final cells = <Widget>[];

    for (var i = 0; i < leading; i++) {
      cells.add(const Expanded(child: SizedBox(height: 40)));
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
      cells.add(
        Expanded(
          child: _DayCell(
            isDark: isDark,
            day: day,
            selected: _isSameDay(date, _selected),
            today: _isSameDay(date, today),
            enabled: _isSelectable(date),
            onTap: () => setState(() => _selected = date),
          ),
        ),
      );
    }
    while (cells.length % 7 != 0) {
      cells.add(const Expanded(child: SizedBox(height: 40)));
    }

    final weeks = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      weeks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(children: cells.sublist(i, i + 7)),
        ),
      );
    }
    return weeks;
  }
}

class _MonthNavButton extends StatefulWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;

  const _MonthNavButton({
    required this.isDark,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_MonthNavButton> createState() => _MonthNavButtonState();
}

class _MonthNavButtonState extends State<_MonthNavButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: _hover ? HomeUi.iconWellGradient : null,
            color: _hover ? null : HomeUi.elevatedBg(widget.isDark),
            shape: BoxShape.circle,
            border: Border.all(
              color: _hover
                  ? HomeUi.iconWellBorder
                  : HomeUi.borderLight(widget.isDark),
            ),
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: HomeUi.title(widget.isDark),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatefulWidget {
  final bool isDark;
  final int day;
  final bool selected;
  final bool today;
  final bool enabled;
  final VoidCallback onTap;

  const _DayCell({
    required this.isDark,
    required this.day,
    required this.selected,
    required this.today,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.enabled) setState(() => _hover = true);
      },
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: SizedBox(
          height: 40,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: widget.selected ? HomeUi.iconFillGradient : null,
                color: widget.selected
                    ? null
                    : (_hover && widget.enabled
                        ? HomeUi.elevatedBg(widget.isDark)
                        : Colors.transparent),
                shape: BoxShape.circle,
                border: widget.today && !widget.selected
                    ? Border.all(color: HomeUi.iconWellBorder)
                    : null,
              ),
              child: Text(
                '${widget.day}',
                style: HomeUi.tableCell(widget.isDark).copyWith(
                  fontWeight: widget.selected || widget.today
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: widget.selected
                      ? Colors.white
                      : widget.enabled
                          ? HomeUi.title(widget.isDark)
                          : HomeUi.muted(widget.isDark).withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DecorativeSparklinePainter extends CustomPainter {
  const _DecorativeSparklinePainter({
    required this.values,
    required this.lineColor,
    required this.fillColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;

    const double padX = 0;
    const double padY = 6;
    final double usableW = size.width;
    final double usableH = size.height - padY * 2;
    final int last = values.length - 1;

    Offset pointAt(int i) {
      final double t = i / last;
      final double v = values[i].clamp(0.0, 1.0);
      return Offset(
        padX + usableW * t,
        padY + usableH * (1 - v),
      );
    }

    final Path line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (int i = 1; i <= last; i++) {
      final Offset p = pointAt(i);
      line.lineTo(p.dx, p.dy);
    }

    final Path area = Path.from(line)
      ..lineTo(pointAt(last).dx, size.height)
      ..lineTo(pointAt(0).dx, size.height)
      ..close();

    canvas.drawPath(
      area,
      Paint()
        ..style = PaintingStyle.fill
        ..color = fillColor,
    );

    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = lineColor,
    );

    final Paint dotFill = Paint()
      ..style = PaintingStyle.fill
      ..color = lineColor;
    for (int i = 0; i <= last; i++) {
      canvas.drawCircle(pointAt(i), 1.6, dotFill);
    }
  }

  @override
  bool shouldRepaint(covariant _DecorativeSparklinePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.values != values;
  }
}
