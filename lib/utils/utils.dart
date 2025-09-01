
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:musaffa_terminal/Components/dynamic_table_reusable.dart';
import 'package:musaffa_terminal/Components/shimmer.dart';
import 'package:musaffa_terminal/models/company_profile.dart';
import 'package:musaffa_terminal/models/etfs.dart';

import 'package:musaffa_terminal/utils/constants.dart';

class CommonStockEtfDataModel {
  String? id;

  SYMBOLS_TYPE? type;
  CompanyProfile? companyProfile;
  EtfModel? etfProfile;
  List<StockEtfField> customDataFields;
  bool isOtherCommodity;
  

  CommonStockEtfDataModel({
    this.id,
    this.type,
    this.companyProfile,
    this.etfProfile,
    this.isOtherCommodity = false,
    required this.customDataFields,
    
  });
}

class StockEtfField {
  
  dynamic value;
  bool isCustomField;
  String? suffix;
  AmountWidgetObj? amountWidgetObj;

  StockEtfField(
      {
      this.value,
      this.isCustomField = false,
      this.suffix,
      this.amountWidgetObj});
}


class AmountWidget extends StatelessWidget {
  const AmountWidget(
      {Key? key,
      this.amount,
      this.textStyle,
      this.currency,
      this.isGradient = false,
      this.gradientStyle})
      : super(key: key);
  final num? amount;
  final String? currency;
  final TextStyle? textStyle;
  final bool? isGradient;
  final Gradient? gradientStyle;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    
    
    var isVerySmallAmount = false;
    var style = TextStyle(
      color: primaryColor,
      fontSize: 10,
      fontWeight: FontWeight.w700,
    );
    if (textStyle != null) style = textStyle!;
    var underlinedStyle = style.copyWith(
        decoration: TextDecoration.underline, decorationColor: style.color);
    if (amount == null) return SizedBox();
    // if (amount! != 0 && amount! < 0.01) isVerySmallAmount = true;
    if ((amount! != 0 && amount! < 0.01) || (amount! < 0 && amount! < -0.01))
      isVerySmallAmount = true;
    if (isVerySmallAmount) {
      return Tooltip(
        triggerMode: TooltipTriggerMode.tap,
        message:
            "${valueWithCurrency(price: amount!, currency: currency, showCurrencySymbol: true, showFullAmount: true)}",
        child: isGradient == false
            ? Text(
                "< ${valueWithCurrency(
                  price: 0.01,
                  currency: currency,
                  showCurrencySymbol: true,
                )}",
                style: underlinedStyle,
              )
            : Text(
                "${valueWithCurrency(
                  price: amount ?? 0.0,
                  currency: currency,
                  showCurrencySymbol: true,
                )}",
                style: style,
              ),
      );
    } else {
      return isGradient == false
          ? Text(
              "${valueWithCurrency(
                price: amount ?? 0.0,
                currency: currency,
                showCurrencySymbol: true,
              )}",
              style: style,
            )
          : Text(
              "${valueWithCurrency(
                price: amount ?? 0.0,
                currency: currency,
                showCurrencySymbol: true,
              )}",
              style: style,
            );
    }
  }
}
String valueWithCurrency({
  num? price,
  String? currency,
  bool shorten = false,
  bool showFullAmount = false,
  int fractions = 10,
  bool? showCurrencySymbol,
  bool? showTextualCurrencyOnRight = true,
  bool? showTextualCurrencyOnLeft = false,
  bool? showDecimals = true,
}) {
  if (price == null) return "";

  String sign = "";
  if (price < 0) {
    price = price.abs();
    sign = "-";
  }

  var p = "";
  if (shorten == true) {
    p = getShortenedT(price);
  } else if (showFullAmount) {
    p = modifyLeadingFractionDigits(
        value: price,
        fractionalDigits: fractions,
        addAppendingZeroTillFractions: false);
  } else {
    if (showDecimals == false) {
      p = price.toInt().toString();
    } else {
      if (price.toStringAsFixed(2).length >= 9) {
        var formatter = NumberFormat('##,###,000.00');
        String price1 = formatter.format(price);

        p = price1;
      } else if (price.toStringAsFixed(2).length >= 7) {
        var formatter1 = NumberFormat('##,000.00');
        String price1 = formatter1.format(price);
        p = price1;
      } else {
        p = price.toStringAsFixed(2);
      }
    }
  }
  bool addCurrencySymbol = false;
  var currencySymbol = "";
  if (currency != null && currency.isNotEmpty) {
    if (showCurrencySymbol == true) {
      currencySymbol = 
          "\$";
      if (currencySymbol.isEmpty)
        addCurrencySymbol = false;
      else
        addCurrencySymbol = true;
    } else {
      addCurrencySymbol = false;
    }
    if (addCurrencySymbol)
      return "$sign$currencySymbol$p";
    else {
      if (showTextualCurrencyOnRight == true)
        return "$sign$p $currency";
      else if (showTextualCurrencyOnLeft == true)
        return "$sign$currency $p";
      else
        return "$sign$currency $p";
    }
  } else
    return p;
}

String modifyLeadingFractionDigits(
    {required num value,
    required int fractionalDigits,
    bool addAppendingZeroTillFractions = true}) {
  var finalVal = (value * pow(10, fractionalDigits)).truncate() /
      pow(10, fractionalDigits);

  var startingPartStr = finalVal.truncate().toString();
  var fractionalPartStr = "";
  List<String> decimalBreakArr = value.toString().split('.');
  if (decimalBreakArr.length > 1) {
    fractionalPartStr = decimalBreakArr[1];
  }

  var trailingDecimal = "";
  if (fractionalPartStr.length >= fractionalDigits) {
    trailingDecimal = fractionalPartStr.substring(0, fractionalDigits);
  } else {
    var remainingDigits = fractionalDigits - fractionalPartStr.length;
    trailingDecimal = fractionalPartStr;
    if (addAppendingZeroTillFractions)
      for (var i = 0; i < remainingDigits; i++) {
        trailingDecimal += "0";
      }
  }
  if (trailingDecimal.isNotEmpty)
    return "$startingPartStr.$trailingDecimal";
  else
    return startingPartStr;
}
String getShortenedT(num? value) {
  if (value == null) {
    return "--";
  }
  num absValue = value.abs();
  if (absValue < 1000) {
    return value.toStringAsFixed(2);
  }
  if (absValue >= 1000 && absValue < 999999) {
    return (value / 1000).toStringAsFixed(2) + 'K';
  }

  if (absValue >= 1000000 && absValue < 999999999) {
    return (value / 1000000).toStringAsFixed(2) + 'M';
  }

  if (absValue >= 1000000000 && absValue < 999999999999) {
    return (value / 1000000000).toStringAsFixed(2) + 'B';
  } else
    return (value / 1000000000000).toStringAsFixed(2) + 'T';
}

String getPriceWithCurrency(String? currency, num? price) {
  if (price == null)
    return "$currency --";
  else {
    if (currency == null) currency = "";
    return "$currency ${price.toStringAsFixed(2)}";
  }
}

enum ShariahCompliantStatus {
  NOT_UNDER_COVERAGE,
  NON_COMPLIANT,
  QUESTIONABLE,
  COMPLIANT,
  DEFAULT,
}
final shariahCompliantStatusValues = EnumValues({
  "NOT_UNDER_COVERAGE": ShariahCompliantStatus.NOT_UNDER_COVERAGE,
  "COMPLIANT": ShariahCompliantStatus.COMPLIANT,
  "QUESTIONABLE": ShariahCompliantStatus.QUESTIONABLE,
  "NON_COMPLIANT": ShariahCompliantStatus.NON_COMPLIANT,
  "DEFAULT": ShariahCompliantStatus.DEFAULT,
});


class EnumValues<T> {
  Map<String, T> map;
  Map<T, String>? reverseMap;

  EnumValues(this.map);

  Map<T, String>? get reverse {
    if (reverseMap == null) {
      reverseMap = map.map((k, v) => new MapEntry(v, k));
    }
    return reverseMap;
  }
}

Widget showLogo(
  String symbol,
  String url, {
  double? sideWidth = 25,
  bool circular = true, // Changed default to true for circular logos
  double? fontsize,
  String name = "",
  Color borderColor = const Color(0xFFE7ECFB),
}) {
  // Create circular placeholder with first letter of ticker symbol
  Widget placeholder = Container(
    width: sideWidth,
    height: sideWidth,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: borderColor, width: 2),
    ),
    child: Center(
      child: FittedBox(
        fit: BoxFit.contain,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : symbol.isNotEmpty ? symbol[0].toUpperCase() : "?",
          style: TextStyle(
            fontSize: fontsize ?? (sideWidth! * 0.4), // Dynamic font size based on container size
            fontWeight: FontWeight.w600,
            fontFamily: Constants.FONT_DEFAULT_NEW,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    ),
  );

  // If no URL provided, return placeholder immediately
  if (url.isEmpty) {
    return circular ? placeholder : ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: placeholder,
    );
  }

  Widget childWidget;
  
  // Check if URL is valid
  bool isSvg = false;
  try {
    isSvg = url.toLowerCase().contains(".svg");
  } catch (e) {
    isSvg = false;
  }
  
  if (isSvg) {
    childWidget = SvgPicture.network(
      url,
      width: sideWidth,
      height: sideWidth,
      fit: BoxFit.contain,
      placeholderBuilder: (BuildContext context) {
        return _buildShimmerPlaceholder(sideWidth!);
      },
      errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
        return placeholder;
      },
    );
  } else {
    childWidget = Image.network(
      url,
      width: sideWidth,
      height: sideWidth,
      fit: BoxFit.contain,
      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildShimmerPlaceholder(sideWidth!);
      },
      errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
        return placeholder;
      },
    );
  }
  
  // Apply circular clipping if requested
  if (circular) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(sideWidth! / 2),
      child: childWidget,
    );
  } else {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: childWidget,
    );
  }
}

Widget _buildShimmerPlaceholder(double size) {
  return ShimmerWidgets.box(
    width: size,
    height: size,
    borderRadius: BorderRadius.circular(size / 2),
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade50,
  );
}

num? parseVariableAsNum(dynamic data) {
  if (data == null) return null;
  if (data is num) {
    return data;
  } else if (data is String)
    return num.tryParse(data) ?? null;
  else
    return null;
}
String getFormattedPrice(num? price, String? currency) {
  if (price == null) return "";
  var currencySymbol = "\$";
  //log(formatterSymbol);
  var priceStr = "";
  if (price.toStringAsFixed(2).length >= 9) {
    var formatter = NumberFormat('##,###,000.00');
    String price1 = formatter.format(price);

    priceStr = price1;
  } else if (price.toStringAsFixed(2).length >= 7) {
    var formatter1 = NumberFormat('##,000.00');
    String price1 = formatter1.format(price);
    priceStr = price1;
  } else {
    priceStr = price.toStringAsFixed(2);
  }
  return "$currencySymbol$priceStr";
}


class CustomColorsV2 {
  static const Color whiteColor = const Color(0xffffffff);
  static const Color navbarSelectedGreen = const Color(0xff0DB47D);
  static const Color navbarUnselectedblack = const Color(0xff0A192F);
  static const Color watchlistSearchbargrey = const Color(0xffB1BBD2);

  static const Color lightdescGreyColor = const Color(0xff283A56);
  static const Color darkDescColor = const Color(0xff81AACE);

  static const Color subscriptionContainerBorder = const Color(0xffDBB658);

  // static const Color watchlistTextBlack = const Color(0xff040E26);

  static const Color createWatchlistBtnColor = const Color(0xff1FB16E);

  static const Color newWatchlistComponentBorder = const Color(0xffDFE6F9);
  static const Color watchlistComponentTitle = const Color(0xff1B294B);
  static const Color watchlistComponentActionButton = const Color(0xff1B284A);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color watchlistTextBlack = Color(0xFF1A1A1A);
  static const Color watchlistComponentBorder = Color(0xFFE0E0E0);
  static const shimmerBase = Color(0xFFE0E0E0);
  static const shimmerHighlight = Color(0xFFF5F5F5);

  //main ticker cell
  static const Color tickerHalalDivider = Color(0xFFE3E9FA);
  static const Color tickerHalalTextColor = const Color(0xff00C853);
  static const Color tickerHalalTextColor2 = const Color(0xff0DB47D);

  static const Color tickerNotHalalTextColor = const Color(0xffFF0000);
  static const Color tickerDoubtfulTextColor = const Color(0xffFF6A00);
  static const Color tickerNameColor = const Color(0xff989898);
  static const Color tickerDividerColor = Color(0xFFE7ECFB);

  static const Color symbolsTextColor = Color(0xFF999999);
  static const Color addSymbolbackground = Color(0xFFF9FAFC);
  static const Color addSymbolborder = Color(0xFFE3E9FA);
  static const Color addSymbolText = Color(0xFF0DB47D);

  //portfolio colors
  static const Color portfolioDropdowBorder = Color(0xFFB9D2E8);
  static const Color dropdownTextColor = Color(0xFF102048);

  //donut chart colors
  static const Color donutChartHalalColor = Color(0xFF6CE79F);

  static const Color donutChartNotHalalColor = Color(0xFF79CDCA);
  static const Color donutChartdoubtfulColor = Color(0xFFA7EACD);
  static const Color chipsUnselectedbg = Color(0xFFF9FAFC);
  static const Color defaultBgColor = Color(0xFFF9FAFC);

  static const Color darktBgColor = Color(0xFFF0F172A);

  static const Color darktSystemoverlaycolor = Color(0xff0B111F);
  static const Color chipsUnselectedText = Color(0xFF0F172A);
  static const Color halalStockCollectionBorder = Color(0xFFECF2F9);
  static const Color starColor = Color(0xFFF3D589);

  static const Color ldGrey = Color(0xFF8798C0);
  static const Color coverageTableBlue = Color(0xFF81AACE);

  static const Color bannerTimerColor = Color(0xffE7790A);
  static const Color donutchartLegendGrey = Color(0xFF758b82);
  static const Color dcHalalText = Color(0xFF6ce795);
  static const Color dcDoubtfulText = Color(0xFFe9b847);
  static const Color dcNotHalalText = Color(0xFFe72d2d);

  static const Color emptyBtnBorderColor = Color(0xFF8B8B8B);
  static const Color appBarIconBlack = const Color(0xff040E26);

  static const Color prorfileChipsBackgroundColor = const Color(0xffF0F3FC);

  static const Color profileDividerColor = const Color(0xffF1F4FC);

  static const Color buttonNavigationContainerltb = const Color(0xffE7EDFC);
  static const Color buttonNavigationContainerdtb = const Color(0xff1A243D);

  static const Color lightThemeDescGrey = const Color(0xff656F86);
  static const Color darkThemeDescGrey = const Color(0xff8596BD);
  static const Color adfHintextColor = const Color(0xffA0AEC0);
  static const Color adlabelextColor = const Color(0xff4A5568);
  static const Color adfChipBgColor = const Color(0xffEDF2F7);
  static const Color adfChipTextColor = const Color(0xff2B6CB0);
  static const Color adfRemoveIconColor = const Color(0xffE53E3E);
  static const Color investmentContainerBg = const Color(0xffE8EBF3);

  static const Color spednContainerPointsLc = const Color(0xff6E809A);
  // dark colors

  static const Color darkWatchlistComponentBorder = const Color(0xff26354B);
  static const Color darkPrimaryColor = const Color(0xffFFFFFF);
  static const Color darkProrfileChipsBackgroundColor = const Color(0xff18233D);

  static const Color darkDividerColor = const Color(0xff212E4D);
  static const Color darkProfileDividerColor = const Color(0xff18233D);

  static const Color darkSecondaryColor = const Color(0xff2A3E5A);

  static const Color darkSecondaryBorder = const Color(0xff2A3E5A);

  static const Color darkBrokerageLoader = const Color(0xFF063970);

  static const darkDescGrey = const Color(0xFF7B89AB);

  static const Color adfDarkHintextColor = const Color(0xff718096);
  static const Color adfDarklabelextColor = const Color(0xffE2E8F0);
  static const Color adfDarkChipBgColor = const Color(0xff2D3748);
  static const Color adfDarkChipTextColor = const Color(0xff90CDF4);
  static const Color adfDarkRemoveIconColor = const Color(0xffFC8181);
  static const Color umrahRwarContainerdBg = Color(0xff1F2D4F);

  static const Color spednContainerPointsDc = const Color(0xffAAB4CC);
  static const Color leaderboardPointsColorlg = const Color(0xff7290BB);
  static const Color InviteButtonBorderColor = const Color(0xff50669A);
}

getPercentageChange(num? percentageChange) {
  if (percentageChange != null) {
    String withoutNegative =
        percentageChange.toStringAsFixed(2).replaceAll(RegExp('-'), '');
    return "$withoutNegative%";
  } else
    return "";
}


class CustomColors {
  // crowdfundinhg  banner

  static const Color CFDARKBLUE = const Color(0xff192748);
  static const Color CFLIGHTGREEN = const Color(0xff1FB16E);

  static const Color CFTIMERCONTAINERBACKGROUND = const Color(0xff1A2849);

  static const Color CFTIMERTEXTCOLOR = const Color(0xffE2E9FA);

  static const Color CFDIVIDERCOLOR = const Color(0xffB9D2E8);

  //a
  static const Color GREEN = const Color(0xff0DB47D);
  static const Color SECONDARY1 = const Color(0xff0DB47D);
  static const Color ProfileDataColor = const Color.fromRGBO(1, 154, 72, 1);
  static const Color HALAL = const Color(0xff009000);
  static const Color NOT_HALAL = const Color(0xffEA3B3B);
  static const Color DOUBTFUL = const Color(0xffFF6701);
  static const Color LOCKED = const Color(0xff7E8D9F);
  static const Color NOT_COVERED = const Color(0xff7E8D9F);
  static const Color HALAL_BACKGROUND = const Color(0xffE8F7ED);
  static Color HALAL_CHIP_BG = const Color(0xffCFE9BA).withAlpha(71);

  //new colors
  static Color HALAL_TAG_BG = const Color(0xffE1F7E9);
  static Color DOUBTFUL_TEXT = const Color(0xffFF6701);
  static Color DOUBTFUL_TAG_BG = const Color(0xffFFF1DF);
  static Color NOT_HALAL_TEXT = const Color(0xffE82127);
  static Color NOT_HALAL_TAG_BG = const Color(0xffFDE6E6);
  static Color New_LOCKED_BG = const Color(0xfff2f5fe);
  static Color LOCKED_TEXT = const Color(0xff0a2540);
  static Color NOT_COVERED_TEXT = const Color(0xff466b91);

  static Color NEW_GREEN = const Color(0xff009000);
  static Color LOADER_BG = const Color(0xffDDDBDD);

  // --new colors
  static const Color NOT_HALAL_BG = const Color(0xffFFF5F5);
  static const Color DOUBTFUL_BG = const Color(0xffFFF7ED);
  static const Color LOCKED_BG = const Color(0xffEFEFF3);
  static const Color NOT_COVERED_BG = const Color(0xFFDCDDDF);
  static const Color DISABLED_BTN_COLOR = const Color(0xFFA1A3AA);
  static const Color UNSELECTED_TAB = const Color(0xffA3A3A3);
  static const Color SELECTED_TAB = Colors.white;

  static const Color BORDER_COLOR = Color(0xffE3E3E3);
  static const Color APPBAR_BG_COLOR = Color.fromARGB(255, 255, 255, 255);
  static const Color darkBackgroundColor = Color(0xff0C0C0C);
  static const Color STOCK_COLLECTION_BG = Color(0xffE1F7E9);
  static const Color dataColor = Color.fromRGBO(68, 68, 68, 0.8);

  static const Color NewDarkGreyColor = Color(0xff575757);
  static const Color BlackColorWithGreyOpacity = Color(0xff454545);
  static const Color NewGreenColor = Color(0xff198754);
  static const Color NewBorderColor = Color(0xffE4E4E4);
  static const Color NewRedColor = Color(0xffDB161B);
  static const Color CTAVariant = Color(0xff2D9393);

  //purification colors

  static const Color headlineGrey = Color(0xff7D7C7C);
  static const Color titleGrey = Color(0xff585858);
  static const Color labelGrey = Color(0xff858585);
  static const Color errorColor = Colors.red;
  static const Color dividerColor = Color(0xffdee2e6);
  static const Color holidingGreyColor = Color(0xff8B8B8B);
  static const Color blueGreybackgroundColor = Color(0xffF8FBFF);

  static const Color labelGreen = Color(0xff54ac52);

  static const Color labelGreenBackground = Color(0xffe9fde9);

  static const Color labelRedBackground = Color(0xfffff0f0);

  static const Color labelRed = Color(0xffdb4441);

  static const Color bodyGrey = Color(0xffdb414141);

  //paywallacolors

  static const Color selectedSubscriptionContainer = Color(0xffFDFAF3);

  // new select brokerage screen color 03.-12 -2024

  static const Color sbBGGrey = Color(0xffF4F4F4);
  static const Color sbDesGrey = Color(0xff7F807F);
  static const Color sbChipsTextGrey = Color(0xff454545);

  //plaid color #

  static const Color plaidDesxTextGrey = Color(0xff696969);
  static const Color blackOp60 = Color(0xff666666);
  static const Color softWhite = Color.fromRGBO(255, 255, 255, 0.6);
  static const Color containerBg = Color(0xFF3A3A3A);
  static final Color whiteWithOpacity80 = Color.fromRGBO(255, 255, 255, 0.8);
}
