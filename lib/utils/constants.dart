import 'package:flutter/material.dart';

class Constants {
  static const String FONT_DEFAULT_NEW = 'Poppins';

  static String getShortenedMarketCapV2(num? value) {
    if (value == null) return "-";

    if (value >= 1e12) {
      return "\$${(value / 1e12).toStringAsFixed(2)}T";
    } else if (value >= 1e9) {
      return "\$${(value / 1e9).toStringAsFixed(2)}B";
    } else if (value >= 1e6) {
      return "\$${(value / 1e6).toStringAsFixed(2)}M";
    } else if (value >= 1e3) {
      return "\$${(value / 1e3).toStringAsFixed(2)}K";
    } else {
      return "\$${value.toStringAsFixed(2)}";
    }
  }
}

class WebResponse<T, P> {
  T? payload;
  P? errorMessage;
  String? exceptionMessage;

  WebResponse({this.payload, this.errorMessage, this.exceptionMessage});
}

class FirestoreConstants {
  static const COMPANY_PROFILE_COLLECTION = "company_profile_collection_new";
  static const ETF_PROFILE_COLLECTION = "etf_profile_collection_4";
  static const ETF_COUNTRY_EXPOSURE_COLLECTION =
      "etf_country_exposure_collection";
  static const ETF_SECTOR_EXPOSURE_COLLECTION =
      "etf_sector_exposure_collection";
  static const ETF_HOLDINGS_COLLECTION = "etf_holdings_collection_2";
}

// Layout Constants - Consistent spacing and padding across all screens
class LayoutConstants {
  static const double SCREEN_PADDING = 18.0;
  static EdgeInsets get screenPadding => 
      const EdgeInsets.all(SCREEN_PADDING);
  static const double SCREEN_COMPONENTS_PADDING = 12.0;
  static EdgeInsets get screenComponentsPadding =>
      const EdgeInsets.all(SCREEN_COMPONENTS_PADDING);
}

class DashboardTextStyles {
  static const Color primaryTextColor =
      Color(0xFF0A0A0A); // Colors.grey.shade800
  static const Color secondaryTextColor =
      Color(0xFF0A0A0A); // Colors.grey.shade700
  static const Color accentColor = Color(0xFF81AACE);
  static const Color newtextcolor = Color(0xFF0A0A0A);

  static TextStyle get titleSmall => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFamily: Constants.FONT_DEFAULT_NEW,
        color: primaryTextColor,
      );

  // Column Header Styles - For table column headers
  static TextStyle get columnHeader => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: Constants.FONT_DEFAULT_NEW,
        color: secondaryTextColor,
      );

  // Stock Name Styles - For company names and ticker symbols
  static TextStyle get stockName => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontFamily: Constants.FONT_DEFAULT_NEW,
        color: primaryTextColor,
      );

  // Ticker Symbol Styles - For ticker symbols
  static TextStyle get tickerSymbol => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontFamily: Constants.FONT_DEFAULT_NEW,
        color: secondaryTextColor,
      );

  // Data Cell Styles - For numerical data in tables
  static TextStyle get dataCell => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontFamily: Constants.FONT_DEFAULT_NEW,
        color: primaryTextColor,
        height: 1,
      );

  // Button Text Styles - For toggle buttons
  static TextStyle get buttonText => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontFamily: Constants.FONT_DEFAULT_NEW,
        color: primaryTextColor,
      );

  // Error Message Styles
  static TextStyle get errorMessage => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontFamily: Constants.FONT_DEFAULT_NEW,
        color: Colors.red.shade400,
      );

  // No Data Styles
  static TextStyle get noData => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontFamily: Constants.FONT_DEFAULT_NEW,
        color: secondaryTextColor,
      );

  // Header Styles - For stock detail page header
  static TextStyle get headerTitle => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: Constants.FONT_DEFAULT_NEW,
        color: primaryTextColor,
      );

  static TextStyle get headerTicker => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: Constants.FONT_DEFAULT_NEW,
        color: secondaryTextColor,
      );

  static TextStyle get headerPrice => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: Constants.FONT_DEFAULT_NEW,
        color: primaryTextColor,
      );

  static TextStyle get headerChange => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: Constants.FONT_DEFAULT_NEW,
        color: secondaryTextColor,
      );

  static TextStyle get headerMetric => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        fontFamily: Constants.FONT_DEFAULT_NEW,
        color: secondaryTextColor,
      );
}
