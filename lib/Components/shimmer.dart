import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';



class ShimmerWidgets {
  static Widget box({
    required double width,
    required double height,
    BorderRadius? borderRadius,
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[100]!,
      highlightColor: highlightColor ?? Colors.grey[50]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(10),
        ),
      ),
    );
  }



  static Widget buildNewsShimmer(
      BuildContext context, Color baseshimmer, Color highlightShimer) {
    return Shimmer.fromColors(
      baseColor: baseshimmer,
      highlightColor: highlightShimer,
      period: const Duration(milliseconds: 1500),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            box(width: double.infinity, height: 180),
            SizedBox(height: 20),
            box(width: double.infinity, height: 15),
            SizedBox(height: 10),
            box(width: double.infinity, height: 12),
            SizedBox(height: 30),
            ListView.builder(
              shrinkWrap: true,
              itemCount: 1,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 0.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            box(
                                width: double.infinity,
                                height: 14,
                                borderRadius: BorderRadius.circular(4.0)),
                            const SizedBox(height: 8.0),
                            box(
                              width: MediaQuery.of(context).size.width * 0.6,
                              height: 12,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            const SizedBox(height: 12.0),
                            Row(
                              children: [
                                box(
                                    width: 80,
                                    height: 10,
                                    borderRadius: BorderRadius.circular(4.0)),
                                const SizedBox(width: 8),
                                box(
                                    width: 30,
                                    height: 10,
                                    borderRadius: BorderRadius.circular(4.0)),
                                // box(
                                //     width: 60,
                                //     height: 12,
                                //     borderRadius: BorderRadius.circular(4.0)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      box(
                        width: 120,
                        height: 60,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget brokerageContainerShimmer({
    required double width,
    required double height,
    BorderRadius? borderRadius,
    Color? baseColor,
    Color? highlightColor,
    required Color borderColor,
    required Color containerColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor,
          ),
          color: containerColor,
          borderRadius: borderRadius ?? BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 0.1),
            ),
          ],
        ),
        child: Shimmer.fromColors(
          baseColor: baseColor ?? Colors.grey[100]!,
          highlightColor: highlightColor ?? Colors.grey[50]!,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 30,
                  width: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: containerColor,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: containerColor,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  height: 25,
                  width: 160,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 40,
                  width: 300,
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget paywallBox({
    required double width,
    required double height,
    BorderRadius? borderRadius,
    Color? baseColor,
    Color? highlightColor,
    Color containerColor = Colors.white,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: borderRadius ?? BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 0.1),
          )
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: baseColor ?? Colors.grey[100]!,
        highlightColor: highlightColor ?? Colors.grey[50]!,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 15,
                width: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 15,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget listItem({
    required int index,
    double? avatarSize,
    double? titleWidth,
    double? titleHeight,
    double? subtitleWidth,
    double? subtitleHeight,
    double? trailingWidth,
    double? trailingHeight,
    double? columnDateWidth,
    double? columnDateHeight,
    double? thirdTileWidth,
    double? thirdTileHeight,
    double? fourthTileWidth,
    double? fourthTileHeight,
    EdgeInsetsGeometry? padding,
    Color? baseColor,
    Color? highlightColor,
    bool showDate = true,
    bool? showTrailingButton = true,
    bool? showColumnDate = false,
    bool? showThirdTile = false,
    bool? showFourthTile = false,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: Container(
        padding: padding ?? EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color.fromRGBO(0, 0, 0, 0.1),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: avatarSize ?? 25,
              width: avatarSize ?? 25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: titleWidth ?? 120,
                        height: titleHeight ?? 14,
                        color: Colors.white,
                      ),
                      if (showTrailingButton == true)
                        Container(
                          height: trailingHeight ?? 18,
                          width: trailingWidth ?? 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: subtitleWidth ?? 80,
                        height: subtitleHeight ?? 10,
                        color: Colors.white,
                      ),
                      if (showDate)
                        Container(
                          width: 60,
                          height: 10,
                          color: Colors.white,
                        ),
                    ],
                  ),
                  if (showColumnDate == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        height: columnDateHeight ?? 18,
                        width: columnDateWidth ?? 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(0),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (showThirdTile == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        height: thirdTileHeight ?? 18,
                        width: thirdTileWidth ?? 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(0),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  if (showFourthTile == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                        height: fourthTileHeight ?? 18,
                        width: fourthTileWidth ?? 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(0),
                          color: Colors.white,
                        ),
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

  static Widget shimmerToggleButton({
    required double width,
    required double height,
    BorderRadius? borderRadius,
    Color? baseColor,
    Color? highlightColor,
    Color conrainerColo = Colors.white,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: conrainerColo,
        borderRadius: borderRadius ?? BorderRadius.circular(50),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 60,
              height: 20,
              decoration: BoxDecoration(
                color: conrainerColo,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: Shimmer.fromColors(
                baseColor: baseColor ?? Colors.grey[100]!,
                highlightColor: highlightColor ?? Colors.grey[50]!,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 80,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget NewlistItem({
    required int index,
    double? avatarSize,
    double? titleWidth,
    double? titleHeight,
    double? subtitleWidth,
    double? subtitleHeight,
    double? columnDateWidth,
    double? columnDateHeight,
    double? thirdTileWidth,
    double? thirdTileHeight,
    double? fourthTileWidth,
    double? fourthTileHeight,
    double? trailingWidth,
    double? trailingHeight,
    double? trailingRadius,
    EdgeInsetsGeometry? padding,
    Color? baseColor,
    Color? highlightColor,
    bool showDate = true,
    bool showTrailingButton = true,
    bool showColumnDate = false,
    bool showThirdTile = false,
    bool showFourthTile = false,
    bool showStatusBadge = false,
    double? statusBagdgeHeight,
    double? statusBagdgeWidth,
    double? statusBadgeRadius,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: Container(
        padding: padding ?? EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color.fromRGBO(0, 0, 0, 0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: avatarSize ?? 25,
                    width: avatarSize ?? 25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: titleWidth ?? 120,
                          height: titleHeight ?? 14,
                          color: Colors.white,
                        ),
                        SizedBox(height: 4),
                        Container(
                          width: subtitleWidth ?? 80,
                          height: subtitleHeight ?? 10,
                          color: Colors.white,
                        ),
                        if (showColumnDate) SizedBox(height: 4),
                        if (showColumnDate)
                          Container(
                            width: columnDateWidth ?? 38,
                            height: columnDateHeight ?? 18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(0),
                              color: Colors.white,
                            ),
                          ),
                        if (showThirdTile) SizedBox(height: 4),
                        if (showThirdTile)
                          Container(
                            width: thirdTileWidth ?? 38,
                            height: thirdTileHeight ?? 18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(0),
                              color: Colors.white,
                            ),
                          ),
                        if (showFourthTile) SizedBox(height: 4),
                        if (showFourthTile)
                          Container(
                            width: fourthTileWidth ?? 38,
                            height: fourthTileHeight ?? 18,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(0),
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showStatusBadge) Expanded(child: SizedBox(width: 4)),
            if (showStatusBadge)
              Container(
                width: statusBagdgeWidth ?? 60,
                height: statusBagdgeHeight ?? 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(statusBadgeRadius ?? 8),
                  color: Colors.white,
                ),
              ),
            if (showStatusBadge) Expanded(child: SizedBox(width: 4)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showTrailingButton)
                  Container(
                    height: trailingHeight ?? 18,
                    width: trailingWidth ?? 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(trailingRadius ?? 50),
                      color: Colors.white,
                    ),
                  ),
                if (showDate) SizedBox(height: 4),
                if (showDate)
                  Container(
                    width: 60,
                    height: 10,
                    color: Colors.white,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget perShareTableShimmer({
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        child: Column(
          children: [
            // Table Header
            Row(
              children: [
                // Metric column - responsive width
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Year columns - responsive width
                ...List.generate(6, (index) => [
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ]).expand((x) => x),
              ],
            ),
            const SizedBox(height: 8),
            
            // Table Rows
            ...List.generate(8, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  // Metric name - responsive width
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Year data - responsive width
                  ...List.generate(6, (yearIndex) => [
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ]).expand((x) => x),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  static Widget chartShimmer({
    Color? baseColor,
    Color? highlightColor,
    double? width,
    double? height,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static Widget activeRewardContainer({
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: EdgeInsets.only(top: 18, bottom: 26),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              width: 1,
              color: Color(0xffE3E3E3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 34,
                width: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: 120,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 40,
                            width: 150,
                            color: Colors.white,
                          ),
                          Container(
                            height: 40,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class ExposureShimmers {
  static Widget sectorExposureShimmer(Color baseColor, Color hightlightColor) {
    return _buildShimmerScreen(
      baseColor: baseColor,
      hightlightCOlor: hightlightColor,
      chart: _buildDonutChartShimmer(),
    );
  }

  static Widget countryExposureShimmerr(
      Color baseColor, Color hightlightColor) {
    return _buildShimmerScreen(
      baseColor: baseColor,
      hightlightCOlor: hightlightColor,
      chart: _buildMapShimmer(),
    );
  }

  static Widget marketExposureShimmerr(Color baseColor, Color hightlightColor) {
    return _buildShimmerScreen(
      baseColor: baseColor,
      hightlightCOlor: hightlightColor,
      chart: _buildDonutChartShimmer(),
    );
  }

  static Widget tableShimmer() {
    return ShimmerWidgets.box(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      width: double.infinity,
      height: 200,
    );
  }

  static Widget _buildShimmerScreen(
      {required Widget chart,
      required Color baseColor,
      required Color hightlightCOlor}) {
    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: hightlightCOlor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 14),
            // Header
            Container(
              height: 24,
              width: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),

            // Chart/Map Area
            SizedBox(height: 220, child: chart),
            const SizedBox(height: 24),

            // Legends
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                2,
                (index) => _buildLegendShimmer(),
              ),
            ),
            const SizedBox(height: 32),

            // Table
            _buildTableShimmer(),
          ],
        ),
      ),
    );
  }

  static Widget _buildDonutChartShimmer() {
    return Center(
      child: Container(
        // width: 200,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  static Widget _buildMapShimmer() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  static Widget _buildLegendShimmer() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          color: Colors.white,
        ),
        const SizedBox(width: 8),
        Container(
          width: 60,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  static Widget _buildTableShimmer() {
    return Column(
      children: [
        // Table Header
        Row(
          children: [
            _buildTableCell(120),
            _buildTableCell(80),
            _buildTableCell(80),
          ],
        ),
        const SizedBox(height: 12),

        // Table Rows
        ...List.generate(
            1,
            (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      _buildTableCell(100),
                      _buildTableCell(70),
                      _buildTableCell(70),
                    ],
                  ),
                )),
      ],
    );
  }

  static Widget _buildTableCell(double width) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Container(
        width: width,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  static Widget financialStatementsShimmer({
    Color? baseColor,
    Color? highlightColor,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
        child: Column(
          children: [
            // Table Header
            Row(
              children: [
                // Metric column
                Container(
                  width: 200,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                // Year/Quarter columns
                ...List.generate(5, (index) => [
                  Container(
                    width: 80,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                ]).expand((x) => x),
              ],
            ),
            const SizedBox(height: 8),
            
            // Table Rows
            ...List.generate(8, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  // Metric name
                  Container(
                    width: 200,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Year/Quarter values
                  ...List.generate(5, (index) => [
                    Container(
                      width: 80,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ]).expand((x) => x),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  static Widget miniWidgetsRowShimmer({
    Color? baseColor,
    Color? highlightColor,
    double? height,
  }) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: Container(
        height: height ?? 180,
        child: Row(
          children: List.generate(4, (index) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Symbol and icon
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 50,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Price
                    Container(
                      width: 80,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Change
                    Container(
                      width: 60,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Mini chart area
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ),
      ),
    );
  }
}

