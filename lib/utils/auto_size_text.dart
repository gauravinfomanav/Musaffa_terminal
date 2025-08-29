import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:musaffa_terminal/utils/constants.dart';



class MusaffaAutoSizeText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final AutoSizeGroup? group;
  final int? maxLines;
  final double minFontSize;
  final TextAlign? textAlign;
  final TextOverflow? overflow;

  const MusaffaAutoSizeText({
    Key? key,
    required this.text,
    required this.style,
    this.group,
    this.maxLines,
    this.minFontSize = 8,
    this.textAlign,
    this.overflow,
  }) : super(key: key);
  static final groups = MusaffaAutoSizeGroups();

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      style: style,
      group: group,
      maxLines: maxLines,
      minFontSize: minFontSize,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.ellipsis,
      softWrap: true,
    );
  }

  // factory constructors,

  factory MusaffaAutoSizeText.displayExtraLarge(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.displayExtraLarge.copyWith(
        color: color ?? AppTextStyles.displayExtraLarge.color,
        fontWeight: fontWeight ?? AppTextStyles.displayExtraLarge.fontWeight,
        decoration: decoration,
        decorationColor: color,
      ),
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
    );
  }

  factory MusaffaAutoSizeText.displayMedium(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.displayMedium.copyWith(
        color: color ?? AppTextStyles.displayMedium.color,
        fontWeight: fontWeight ?? AppTextStyles.displayMedium.fontWeight,
        decoration: decoration,
        decorationColor: color,
      ),
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
    );
  }

  factory MusaffaAutoSizeText.displaySmall(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    required AutoSizeGroup group,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.displaySmall.copyWith(
          color: color ?? AppTextStyles.displaySmall.color,
          fontWeight: fontWeight ?? AppTextStyles.displaySmall.fontWeight,
          decoration: decoration,
          decorationColor: color),
      group: group,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
    );
  }

  factory MusaffaAutoSizeText.headlineLarge(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    required AutoSizeGroup group,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.headlineLarge.copyWith(
        color: color ?? AppTextStyles.headlineLarge.color,
        fontWeight: fontWeight ?? AppTextStyles.headlineLarge.fontWeight,
        decoration: decoration,
        decorationColor: color,
      ),
      group: group,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
    );
  }

  factory MusaffaAutoSizeText.headlineMedium(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    double? minFontSize,
    AutoSizeGroup? group,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.headlineMedium.copyWith(
        color: color ?? AppTextStyles.headlineMedium.color,
        fontWeight: fontWeight ?? AppTextStyles.headlineMedium.fontWeight,
        decoration: decoration,
        decorationColor: color,
        fontFamily: Constants.FONT_DEFAULT_NEW,
      ),
      group: group,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      minFontSize: minFontSize ?? 12,
    );
  }

  factory MusaffaAutoSizeText.headlineSmall(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    AutoSizeGroup? group,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      group: group,
      style: AppTextStyles.headlineSmall.copyWith(
        color: color ?? AppTextStyles.headlineSmall.color,
        fontWeight: fontWeight ?? AppTextStyles.headlineSmall.fontWeight,
        decoration: decoration,
        decorationColor: color,
      ),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }

  factory MusaffaAutoSizeText.headlineExtraSmall(String text,
      {Color? color,
      FontWeight? fontWeight,
      TextDecoration? decoration,
      TextAlign? textAlign,
      TextOverflow? overflow,
      int? maxLines,
      AutoSizeGroup? group}) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.headlineExtraSmall.copyWith(
        color: color ?? AppTextStyles.headlineExtraSmall.color,
        fontWeight: fontWeight ?? AppTextStyles.headlineExtraSmall.fontWeight,
        decoration: decoration,
        decorationColor: color,
      ),
      group: group,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
    );
  }

  factory MusaffaAutoSizeText.bodyExtraLarge(String text,
      {Color? color,
      Color? decorationColor,
      TextDecoration? decoration,
      TextAlign? textAlign,
      TextOverflow? overflow,
      int? maxLines,
      FontWeight? fontWeight,
      double? height,
      AutoSizeGroup? group}) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.bodyExtraLarge.copyWith(
        color: color ?? AppTextStyles.bodyExtraLarge.color,
        decoration: decoration,
        fontWeight: fontWeight ?? AppTextStyles.bodyExtraLarge.fontWeight,
        decorationColor: color,
        height: height ?? AppTextStyles.bodyExtraLarge.height,
      ),
      group: group,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
    );
  }

  factory MusaffaAutoSizeText.bodySmall(String text,
      {Color? color,
      Color? decorationColor,
      TextDecoration? decoration,
      TextAlign? textAlign,
      TextOverflow? overflow,
      int? maxLines,
      FontWeight? fontWeight,
      AutoSizeGroup? group}) {
    return MusaffaAutoSizeText(
      minFontSize: 10,
      text: text,
      style: AppTextStyles.bodySmall.copyWith(
        color: color ?? AppTextStyles.bodySmall.color,
        decoration: decoration,
        fontWeight: fontWeight ?? AppTextStyles.bodySmall.fontWeight,
        decorationColor: color,
      ),
      group: group,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
    );
  }

  factory MusaffaAutoSizeText.bodyExtraSmall(
    String text, {
    Color? color,
    Color? decorationColor,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    FontWeight? fontWeight,
    AutoSizeGroup? group,
    double? fontSize,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.bodyExtraSmall.copyWith(
          color: color ?? AppTextStyles.bodyExtraSmall.color,
          decoration: decoration,
          fontWeight: fontWeight ?? AppTextStyles.bodyExtraSmall.fontWeight,
          decorationColor: color,
          fontSize: fontSize),
      textAlign: textAlign,
      group: group,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
    );
  }

  factory MusaffaAutoSizeText.bodyLarge(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    double? minFontSize,
    AutoSizeGroup? group,
    double? fontSize,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.bodyLarge.copyWith(
        color: color ?? AppTextStyles.bodyLarge.color,
        fontWeight: fontWeight ?? AppTextStyles.bodyLarge.fontWeight,
        decoration: decoration,
        decorationColor: color,
        fontSize: fontSize,
      ),
      group: group,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
      minFontSize: minFontSize ?? 8,
    );
  }

  factory MusaffaAutoSizeText.bodyMedium(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    double? minFontSize,
    double? height,
    AutoSizeGroup? group,
    double? decorationThickness,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.bodyMedium.copyWith(
        color: color ?? AppTextStyles.bodyMedium.color,
        fontWeight: fontWeight ?? AppTextStyles.bodyMedium.fontWeight,
        decoration: decoration,
        decorationColor: color,
        height: height ?? AppTextStyles.bodyMedium.height,
        decorationThickness:
            decorationThickness ?? AppTextStyles.bodyMedium.decorationThickness,
      ),
      group: group,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
      minFontSize: minFontSize ?? 8,
    );
  }

  factory MusaffaAutoSizeText.titleLarge(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    AutoSizeGroup? group,
    double? minfontSize,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.titleLarge.copyWith(
        color: color ?? AppTextStyles.titleLarge.color,
        fontWeight: fontWeight ?? AppTextStyles.titleLarge.fontWeight,
        decoration: decoration,
        decorationColor: color,
      ),
      group: group,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      minFontSize: minfontSize ?? 12,
    );
  }

  factory MusaffaAutoSizeText.titleSmall(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    double? minfontSize,
    AutoSizeGroup? group,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.titleSmall.copyWith(
        color: color ?? AppTextStyles.titleSmall.color,
        fontWeight: fontWeight ?? AppTextStyles.titleSmall.fontWeight,
        decoration: decoration,
        decorationColor: color,
      ),
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
      minFontSize: minfontSize ?? 8,
      group: group,
    );
  }

  factory MusaffaAutoSizeText.titleMedium(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    double? minfontSize,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.titleMedium.copyWith(
        color: color ?? AppTextStyles.titleMedium.color,
        fontWeight: fontWeight ?? AppTextStyles.titleMedium.fontWeight,
        decoration: decoration,
        decorationColor: color,
      ),
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
      minFontSize: minfontSize ?? 8,
    );
  }

  factory MusaffaAutoSizeText.titleMediumSmall(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    double? minfontSzie,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.titleMediumSmall.copyWith(
        color: color ?? AppTextStyles.titleMediumSmall.color,
        fontWeight: fontWeight ?? AppTextStyles.titleMediumSmall.fontWeight,
        decoration: decoration,
        decorationColor: color,
      ),
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
      minFontSize: minfontSzie ?? 10,
    );
  }

  factory MusaffaAutoSizeText.titleExtraSmall(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    double? fontSize,
    AutoSizeGroup? group,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.titleExtraSmall.copyWith(
        color: color ?? AppTextStyles.titleExtraSmall.color,
        fontWeight: fontWeight ?? AppTextStyles.titleExtraSmall.fontWeight,
        decoration: decoration,
        decorationColor: color,
      ),
      group: group,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
    );
  }

  factory MusaffaAutoSizeText.labelLarge(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    double? height,
    double? minfontSize,
    double? decorationThickness,
    AutoSizeGroup? group,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.labelLarge.copyWith(
        color: color ?? AppTextStyles.labelLarge.color,
        fontWeight: fontWeight ?? AppTextStyles.labelLarge.fontWeight,
        decoration: decoration,
        decorationColor: color,
        height: height ?? AppTextStyles.labelLarge.height,
        decorationThickness:
            decorationThickness ?? AppTextStyles.labelLarge.decorationThickness,
      ),
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
      minFontSize: minfontSize ?? 8,
      group: group,
    );
  }

  factory MusaffaAutoSizeText.labelMedium(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    double? minFontSize,
    AutoSizeGroup? group,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.labelMedium.copyWith(
        color: color ?? AppTextStyles.labelMedium.color,
        fontWeight: fontWeight ?? AppTextStyles.labelMedium.fontWeight,
        decoration: decoration,
        decorationColor: color,
      ),
      group: group,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
      minFontSize: minFontSize ?? 8,
    );
  }

  factory MusaffaAutoSizeText.labelSmall(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
    double? minFontSize,
    AutoSizeGroup? group,
  }) {
    return MusaffaAutoSizeText(
      text: text,
      style: AppTextStyles.labelSmall.copyWith(
        color: color ?? AppTextStyles.labelSmall.color,
        fontWeight: fontWeight ?? AppTextStyles.labelSmall.fontWeight,
        decoration: decoration,
        decorationColor: color,
      ),
      group: group,
      textAlign: textAlign,
      overflow: overflow ?? TextOverflow.visible,
      maxLines: maxLines,
      minFontSize: minFontSize ?? 8,
    );
  }
}



class MusaffaAutoSizeGroups {
  static final MusaffaAutoSizeGroups _instance =
      MusaffaAutoSizeGroups._internal();

  factory MusaffaAutoSizeGroups() {
    return _instance;
  }

  MusaffaAutoSizeGroups._internal();

  final displayEmphasisGroup = AutoSizeGroup();
  final displayExtraLargeGroup = AutoSizeGroup();
  final displayLargeGroup = AutoSizeGroup();
  final displayMediumGroup = AutoSizeGroup();
  final displaySmallGroup = AutoSizeGroup();

  final headlineLargeGroup = AutoSizeGroup();
  final headlineMediumGroup = AutoSizeGroup();
  final headlineSmallGroup = AutoSizeGroup();
  final headlineExtraSmallGroup = AutoSizeGroup();

  final titleLargeGroup = AutoSizeGroup();
  final titleMediumGroup = AutoSizeGroup();

  final titleMediumSmallGroup = AutoSizeGroup();
  final titleSmallGroup = AutoSizeGroup();
  final titleExtraSmallGroup = AutoSizeGroup();

  final bodyExtraLargeGroup = AutoSizeGroup();
  final bodyLargeGroup = AutoSizeGroup();
  final bodyMediumGroup = AutoSizeGroup();
  final bodySmallGroup = AutoSizeGroup();
  final bodyExtraSmallGroup = AutoSizeGroup();

  final labelLargeGroup = AutoSizeGroup();
  final labelMediumGroup = AutoSizeGroup();
  final labelSmallGroup = AutoSizeGroup();

  final title = AutoSizeGroup();
  final sectionTitle = AutoSizeGroup();
  final body = AutoSizeGroup();
  final overline = AutoSizeGroup();
  final cardSecondaryTitle = AutoSizeGroup();
  final cardPrimaryTitle = AutoSizeGroup();
  final featureText = AutoSizeGroup();

  final portfolioTabsContentTitleGroup = AutoSizeGroup();
}



class AppTextStyles {
  // Display styles
  static const TextStyle displayEmphasis = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );
  static const TextStyle displayExtraLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: Colors.black,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle displayLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  // Headline styles

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle headlineExtraSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle titleMediumSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle titleExtraSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  // Body styles
  static const TextStyle bodyExtraLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle bodyExtraSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle kSectionTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle kTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle kBody = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle kBodyDarkGrey = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: Color(0xff5B5B5B),
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle kOverline = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Color(0xff949292),
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle kCardPrimaryTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );

  static const TextStyle kCardSecondaryTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: Constants.FONT_DEFAULT_NEW,
  );
  
}
