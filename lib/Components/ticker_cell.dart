import 'package:flutter/material.dart';
import 'package:musaffa_terminal/models/ticker_cell_model.dart';
import 'package:musaffa_terminal/utils/constants.dart';
import 'package:musaffa_terminal/utils/socket_message.dart';
import 'package:musaffa_terminal/utils/utils.dart';

class MainTickerCell extends StatelessWidget {
  const MainTickerCell(
      {Key? key,
      required this.model,
      this.isSocketUsed = false,
      this.isComplianceLoading = false,
      this.priceFetched,
      this.occupySpaceWhenPriceHidden,
      this.shouldShowPriceSection,
      this.showAnalystRating = false,
      this.showBottomBorder = true,
      this.horizontalSpacing = 16,
      this.verticalSpacing = 12,
      this.backgroundColor = Colors.white})
      : super(key: key);

  final TickerCellModel model;
  final bool isComplianceLoading;
  final bool isSocketUsed;
  final Function(SocketMessage? message)? priceFetched;
  final bool? occupySpaceWhenPriceHidden;
  final bool? shouldShowPriceSection;
  final bool showAnalystRating;
  final bool showBottomBorder;
  final Color backgroundColor;
  final double horizontalSpacing;
  final double verticalSpacing;

  

  @override
  Widget build(BuildContext context) {
    return Container(
      // color: backgroundColor,
      // color: Colors.white,
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalSpacing, vertical: verticalSpacing),
            child: SizedBox(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Visibility(
                    // visible: model.forceShowLogoSection,
                    child: Row(
                      children: [
                        showLogo(model.tickerName, model.logoUrl ?? "",
                            sideWidth: 25,
                            circular: true,
                            name: model.companyName),
                        SizedBox(
                          width: 12,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DashboardTextStyles.stockName,
                        ),
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                // width: 45,
                                child: Text(
                                  model.tickerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: DashboardTextStyles.tickerSymbol,
                                ),
                              ),
                            ),
                           
                          ],
                        ),
                        
                      ],
                    ),
                  ),
                  Container(width: 8),
                  // Price and change are now shown in the dynamic columns only
                  SizedBox(width: 80),
                ],
              ),
            ),
          ),
          Visibility(
            visible: showBottomBorder,
            child: Container(
              height: 1,
              color: Theme.of(context).dividerColor,
            ),
          )
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    Key? key,
    required this.halalRate,
    required this.ranking,
    
    this.showLockOnStars,
    this.height,
    this.width,
  }) : super(key: key);

  final dynamic halalRate;
  final num? ranking;
  final double? height;
  final double? width;
  
  final bool? showLockOnStars;

  getHalalStatusKey() {
    return halalRate;
  }

  String getStatus() {
    if (getHalalStatusKey() == null)
      return 'Locked';

    final String key = getHalalStatusKey().toString().split('.').last;

    if (key == "COMPLIANT") {
      return "HALAL";
    }

    if (key == "NON_COMPLIANT") {
      return "NOT HALAL";
    }

    if (key == "QUESTIONABLE") {
      return "DOUBTFUL";
    }
    return "NOT COVERED";
  }

  Color getStatusColor() {
    final String key = (getHalalStatusKey()?.toString().split('.').last) ?? '';
    if (key == "COMPLIANT") {
      return CustomColorsV2.tickerHalalTextColor2;
    }

    if (key == "NON_COMPLIANT") {
      return CustomColorsV2.tickerNotHalalTextColor;
    }

    if (key == "QUESTIONABLE") {
      return CustomColors.DOUBTFUL_TEXT;
    }

    return Color(0xff8F8F8F);
  }

  getBgColor() {
    if (getHalalStatusKey() == null) return CustomColors.LOCKED_BG;

    final String key = (getHalalStatusKey()?.toString().split('.').last) ?? '';
    if (key == "COMPLIANT") {
      return CustomColors.HALAL_TAG_BG;
    }

    if (key == "NON_COMPLIANT") {
      return CustomColors.NOT_HALAL_TAG_BG;
    }

    if (key == "QUESTIONABLE") {
      return CustomColors.DOUBTFUL_TAG_BG;
    }

    return CustomColors.New_LOCKED_BG;
  }

  @override
  Widget build(BuildContext context) {
    String rankingStr = "";
    if (ranking != null) {
      var map = Constants.NEW_RANKING_MAPPING;
      if (map.containsKey(ranking))
        rankingStr = Constants.NEW_RANKING_MAPPING[ranking] ?? "";
    }

    return Container(
      width: width,
      height: height,
      child: (((getHalalStatusKey()?.toString().split('.').last) ?? '') == 'COMPLIANT')
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  getStatus(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: DashboardTextStyles.tickerSymbol.copyWith(
                      overflow: TextOverflow.ellipsis,
                      fontWeight: FontWeight.w500,
                      color: getStatusColor()),
                ),
                SizedBox(width: 4),
                Visibility(
                  visible: rankingStr.isNotEmpty == true,
                  child: Container(
                    height: 10,
                    width: 1,
                    color: Color(0xffE3E9FA),
                  ),
                ),
                SizedBox(width: 4),
                Stack(
                  children: [
                    // Removed complex lock/unlock logic, just show ranking
                    Visibility(
                      visible: rankingStr.isNotEmpty == true,
                      child: Text(rankingStr,
                          style: TextStyle(
                              color: CustomColorsV2.tickerHalalTextColor2,
                              letterSpacing: 0,
                              wordSpacing: 0,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 0)),
                    )
                  ],
                ),
              ],
            )
          : Center(
              child: getHalalStatusKey() != null
                  ? Text(
                      getStatus(),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 12,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w500,
                          color: getStatusColor()),
                    )
                  : Text(
                      "Locked",
                      style: TextStyle(
                        fontSize: 12,
                        color: CustomColorsV2.navbarSelectedGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
    );
  }
}

class PriceAndChangeWidget extends StatelessWidget {
  PriceAndChangeWidget(
      {required this.tickerName, this.priceFetched, required this.currency});

  final String tickerName;
  final String currency;
  final Function(SocketMessage? message)? priceFetched;

  @override
  Widget build(BuildContext context) {
    // Removed websocket StreamBuilder, just show static content
    return Visibility(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 4,
          ),
          Text(
              "Loading...",
              textAlign: TextAlign.end,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500)),
          Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("...",
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.black)),
              ]),
        ],
      ),
    );
  }
}