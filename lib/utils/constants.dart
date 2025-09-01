import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Constants {
  static const String FONT_DEFAULT_NEW = 'Poppins';

  static const NEW_RANKING_MAPPING = {
    9: 'A+',
    8: 'A',
    7: 'A-',
    6: 'B+',
    5: 'B',
    4: 'B-',
    3: 'C+',
    2: 'C',
    1: 'C-',
  };
  

  
}
class WebResponse<T, P> {
  T? payload;
  P? errorMessage;
  String? exceptionMessage;

  WebResponse({this.payload, this.errorMessage, this.exceptionMessage});
}

class FirestoreConstants{
  static const COMPANY_PROFILE_COLLECTION = "company_profile_collection_new";
  static const ETF_PROFILE_COLLECTION = "etf_profile_collection_4";
  static const ETF_COUNTRY_EXPOSURE_COLLECTION = "etf_country_exposure_collection";
  static const ETF_SECTOR_EXPOSURE_COLLECTION = "etf_sector_exposure_collection";
  static const ETF_HOLDINGS_COLLECTION = "etf_holdings_collection_2";

}

// Dashboard Text Styles - Consistent across all components
class DashboardTextStyles {
  // Primary Colors - Matching the working market summary table
  static const Color primaryTextColor = Color(0xFF374151); // Colors.grey.shade800
  static const Color secondaryTextColor = Color(0xFF6B7280); // Colors.grey.shade700
  static const Color accentColor = Color(0xFF81AACE);
  
  // Title Styles - For section headers like "Top Movers Today"
  static TextStyle get titleSmall => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
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
}