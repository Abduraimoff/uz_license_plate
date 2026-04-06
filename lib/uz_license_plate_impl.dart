part of 'uz_license_plate.dart';

// --- Public enums & sizing -------------------------------------------------

/// High-level plate category used for analytics / theming; detection maps each
/// regex hit to one of these values.
enum UzPlateCategory {
  diplomatic,
  government,
  police,
  standard,
  truckBus,
  taxi,
  electric,
  unknown,
}

enum UzPlateSize {
  /// Compact (Figma small: ~26px tall frame).
  small,

  /// Between small and large for lists / chips.
  medium,

  /// Primary (Figma large: ~56px tall frame).
  large,
}

/// Typographic slot: region code (smaller) vs main plate glyphs (larger).
enum PlateTextScale { region, main }

/// Extra leading inset inside the expanded main text region ([UzPlateSize]-aware).
enum PlateMainFlexLeadingStyle {
  none,

  /// e.g. `50O545DB` main block: large 14 / medium 8 / small 4.
  letterDigitBlock,

  /// Taxi/truck `01H000069` style: large 21 / else 8.
  truckTaxi,
}

double _mainFlexLeadingPixels(
  PlateMainFlexLeadingStyle style,
  UzPlateSize size,
) {
  switch (style) {
    case PlateMainFlexLeadingStyle.none:
      return 0;
    case PlateMainFlexLeadingStyle.letterDigitBlock:
      switch (size) {
        case UzPlateSize.small:
          return 4;
        case UzPlateSize.medium:
          return 8;
        case UzPlateSize.large:
          return 14;
      }
    case PlateMainFlexLeadingStyle.truckTaxi:
      return size == UzPlateSize.large ? 21 : 8;
  }
}

// --- Format model (design tokens + behavior flags) -------------------------

/// Describes colors, optional region tint, and which chrome to draw.
///
/// Layout *structure* comes from [UzPlateResolved.layout]; [PlateFormat] only
/// carries visual flags so we avoid duplicating UI logic in large switches.
@immutable
class PlateFormat {
  const PlateFormat({
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    this.regionBackgroundColor,
    this.showFlag = false,
    this.flagOnLeft = false,
    this.useVerticalDivider = true,
    this.diplomaticSingleField = false,
    this.electricGreenRegion = false,

    /// When non-null, draws a 1px outer ring (Figma outer frame) before the inner stroke.
    this.outerRingColor,
    this.mainFlexLeadingStyle = PlateMainFlexLeadingStyle.none,
  });

  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;

  /// When non-null, only the left "region" cell uses this background (electric).
  final Color? regionBackgroundColor;

  /// Whether the plate includes flag + "UZ" (still subject to [UzLicensePlate.showFlag]).
  final bool showFlag;

  /// Police (PAA) uses flag on the left; civilian standard uses flag on the right.
  final bool flagOnLeft;

  /// Some formats (UN/CMD/T+6) use a single text field without a divider.
  final bool diplomaticSingleField;

  /// Electric "hudud" styling: green region band.
  final bool electricGreenRegion;

  final bool useVerticalDivider;

  /// Outer frame color (e.g. diplomatic green ring). Null = no extra ring.
  final Color? outerRingColor;

  final PlateMainFlexLeadingStyle mainFlexLeadingStyle;

  PlateFormat copyWith({
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
    Color? regionBackgroundColor,
    bool? showFlag,
    bool? flagOnLeft,
    bool? useVerticalDivider,
    bool? diplomaticSingleField,
    bool? electricGreenRegion,
    Color? outerRingColor,
    PlateMainFlexLeadingStyle? mainFlexLeadingStyle,
  }) {
    return PlateFormat(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      borderColor: borderColor ?? this.borderColor,
      regionBackgroundColor:
          regionBackgroundColor ?? this.regionBackgroundColor,
      showFlag: showFlag ?? this.showFlag,
      flagOnLeft: flagOnLeft ?? this.flagOnLeft,
      useVerticalDivider: useVerticalDivider ?? this.useVerticalDivider,
      diplomaticSingleField:
          diplomaticSingleField ?? this.diplomaticSingleField,
      electricGreenRegion: electricGreenRegion ?? this.electricGreenRegion,
      outerRingColor: outerRingColor ?? this.outerRingColor,
      mainFlexLeadingStyle: mainFlexLeadingStyle ?? this.mainFlexLeadingStyle,
    );
  }
}

// --- Internal layout DSL (data only) ---------------------------------------

enum PlatePartKind { regionText, divider, mainGroup, flag }

@immutable
class PlateLayoutPart {
  const PlateLayoutPart({
    required this.kind,
    this.text,
    this.scale = PlateTextScale.main,

    /// When non-null, [mainGroup] expands in the row ([Expanded]).
    this.flex,
  });

  final PlatePartKind kind;
  final String? text;
  final PlateTextScale scale;
  final int? flex;
}

@immutable
class UzPlateResolved {
  const UzPlateResolved({
    required this.normalized,
    required this.category,
    required this.format,
    required this.layout,
  });

  final String normalized;
  final UzPlateCategory category;
  final PlateFormat format;
  final List<PlateLayoutPart> layout;
}

// --- Palette (aligned with Figma dev exports + existing app usage) ----------

class _UzPlateColors {
  /// Same as `AppColors.white` (host app palette).
  static const Color white = Color(0xFFFFFFFF);

  /// Same as `AppColors.jungleGreen` (host app palette).
  static const Color jungleGreen = Color(0xFF27AE60);

  static const Color diplomaticGreen = Color(0xFF34C759);
  static const Color taxiYellow = Color(0xFFFFD000);
  static const Color border = Color(0xFF282828);
  static const Color diplomaticBlue = Color(0xFF1E88E5);
}

// --- Parser (registry — no UI switches) ------------------------------------

typedef _ResolveFn = UzPlateResolved? Function(String n);

/// Same detection order as [CarNumber.getNumberType].
final List<(RegExp, _ResolveFn)> _plateRegistry = [
  (RegExp(r'^UN[0-9]{4}$'), _resolveUn),
  (RegExp(r'^CMD[0-9]{4}$'), _resolveCmd),
  (RegExp(r'^[A-Z][0-9]{6}$'), _resolveGovernmentT),
  (RegExp(r'^PAA[0-9]{3}$'), _resolvePolicePaa),
  (RegExp(r'^[A-Z][0-9]{8}$'), _resolveStandardLong),
  (RegExp(r'^[0-9]{2}M[0-9]{6}$'), _resolveTruck),
  (RegExp(r'^[0-9]{2}H[0-9]{6}$'), _resolveTaxi),
  (RegExp(r'^[0-9]{5}[A-Z]{2}EEEE$'), _resolveElectricYur),
  (RegExp(r'^[0-9]{2}[A-Z][0-9]{3}[A-Z]EEEEE$'), _resolveElectricFiz),
  (RegExp(r'^[0-9]{2}[A-Z][0-9]{3}[A-Z]{2}$'), _resolveStandard01G604CC),
  (RegExp(r'^[0-9]{5}[A-Z]{3}$'), _resolveFiveThree),
  (RegExp(r'^[0-9]{5}[A-Z]{2}$'), _resolveFiveTwo),
];

UzPlateResolved? parseUzPlate(String raw) {
  final String n = raw.replaceAll(' ', '').toUpperCase();
  if (n.isEmpty) return null;
  for (final (re, fn) in _plateRegistry) {
    if (re.hasMatch(n)) {
      return fn(n);
    }
  }
  return _resolveFallback(n);
}

// -- Resolvers: return [PlateFormat] + ordered [PlateLayoutPart] list ------------

UzPlateResolved _resolveUn(String n) {
  const format = PlateFormat(
    backgroundColor: _UzPlateColors.diplomaticBlue,
    textColor: _UzPlateColors.white,
    borderColor: _UzPlateColors.border,
    useVerticalDivider: false,
    diplomaticSingleField: true,
    showFlag: false,
    outerRingColor: _UzPlateColors.diplomaticBlue,
  );
  return UzPlateResolved(
    normalized: n,
    category: UzPlateCategory.diplomatic,
    format: format,
    layout: [
      PlateLayoutPart(
        kind: PlatePartKind.mainGroup,
        text: '${n.substring(0, 2)} ${n.substring(2)}',
        scale: PlateTextScale.main,
        flex: 1,
      ),
    ],
  );
}

UzPlateResolved _resolveCmd(String n) {
  const format = PlateFormat(
    backgroundColor: _UzPlateColors.diplomaticGreen,
    textColor: _UzPlateColors.white,
    borderColor: _UzPlateColors.border,
    useVerticalDivider: false,
    diplomaticSingleField: true,
    showFlag: false,
    outerRingColor: _UzPlateColors.diplomaticGreen,
  );
  return UzPlateResolved(
    normalized: n,
    category: UzPlateCategory.diplomatic,
    format: format,
    layout: [
      PlateLayoutPart(
        kind: PlatePartKind.mainGroup,
        text: '${n.substring(0, 3)} ${n.substring(3)}',
        scale: PlateTextScale.main,
        flex: 1,
      ),
    ],
  );
}

UzPlateResolved _resolveGovernmentT(String n) {
  const format = PlateFormat(
    backgroundColor: Colors.green,
    textColor: _UzPlateColors.white,
    borderColor: _UzPlateColors.border,
    useVerticalDivider: false,
    diplomaticSingleField: true,
    showFlag: false,
    outerRingColor: Colors.green,
  );
  return UzPlateResolved(
    normalized: n,
    category: UzPlateCategory.government,
    format: format,
    layout: [
      PlateLayoutPart(
        kind: PlatePartKind.mainGroup,
        text: '${n[0]} ${n.substring(1)}',
        scale: PlateTextScale.main,
        flex: 1,
      ),
    ],
  );
}

UzPlateResolved _resolvePolicePaa(String n) {
  const format = PlateFormat(
    backgroundColor: _UzPlateColors.white,
    textColor: _UzPlateColors.border,
    borderColor: _UzPlateColors.border,
    showFlag: true,
    flagOnLeft: true,
    useVerticalDivider: false,
    diplomaticSingleField: true,
  );
  return UzPlateResolved(
    normalized: n,
    category: UzPlateCategory.police,
    format: format,
    layout: [
      const PlateLayoutPart(kind: PlatePartKind.flag),
      PlateLayoutPart(
        kind: PlatePartKind.mainGroup,
        text: ' ${n.substring(0, 3)} ${n.substring(3)} ',
        scale: PlateTextScale.main,
        flex: 1,
      ),
    ],
  );
}

UzPlateResolved _resolveStandardLong(String n) {
  const format = PlateFormat(
    backgroundColor: _UzPlateColors.white,
    textColor: _UzPlateColors.border,
    borderColor: _UzPlateColors.border,
    showFlag: false,
    useVerticalDivider: true,
  );
  return UzPlateResolved(
    normalized: n,
    category: UzPlateCategory.standard,
    format: format,
    layout: [
      PlateLayoutPart(
        kind: PlatePartKind.mainGroup,
        text: ' ${n[0]} ${n.substring(1, 7)} ',
        scale: PlateTextScale.main,
        flex: 1,
      ),
      const PlateLayoutPart(kind: PlatePartKind.divider),
      PlateLayoutPart(
        kind: PlatePartKind.mainGroup,
        text: ' ${n.substring(7)}',
        scale: PlateTextScale.main,
      ),
    ],
  );
}

UzPlateResolved _resolveTruck(String n) {
  const format = PlateFormat(
    backgroundColor: Colors.green,
    textColor: _UzPlateColors.white,
    borderColor: _UzPlateColors.border,
    showFlag: false,
    outerRingColor: Colors.green,
    mainFlexLeadingStyle: PlateMainFlexLeadingStyle.truckTaxi,
  );
  return UzPlateResolved(
    normalized: n,
    category: UzPlateCategory.truckBus,
    format: format,
    layout: _layoutRegionLetterRest(n),
  );
}

UzPlateResolved _resolveTaxi(String n) {
  const format = PlateFormat(
    backgroundColor: _UzPlateColors.taxiYellow,
    textColor: _UzPlateColors.border,
    borderColor: _UzPlateColors.border,
    showFlag: false,
    outerRingColor: _UzPlateColors.taxiYellow,
    mainFlexLeadingStyle: PlateMainFlexLeadingStyle.truckTaxi,
  );
  return UzPlateResolved(
    normalized: n,
    category: UzPlateCategory.taxi,
    format: format,
    layout: _layoutRegionLetterRest(n),
  );
}

List<PlateLayoutPart> _layoutRegionLetterRest(String n) {
  return [
    PlateLayoutPart(
      kind: PlatePartKind.regionText,
      text: n.substring(0, 2),
      scale: PlateTextScale.region,
    ),
    const PlateLayoutPart(kind: PlatePartKind.divider),
    PlateLayoutPart(
      kind: PlatePartKind.mainGroup,
      text: '${n[2]} ${n.substring(3)}',
      scale: PlateTextScale.main,
      flex: 1,
    ),
  ];
}

UzPlateResolved _resolveElectricYur(String n) {
  const format = PlateFormat(
    backgroundColor: _UzPlateColors.white,
    textColor: _UzPlateColors.border,
    borderColor: _UzPlateColors.border,
    regionBackgroundColor: _UzPlateColors.jungleGreen,
    showFlag: true,
    electricGreenRegion: true,
  );
  return UzPlateResolved(
    normalized: n,
    category: UzPlateCategory.electric,
    format: format,
    layout: _layoutStandardRightFlag(n, mainText: n.substring(5)),
  );
}

UzPlateResolved _resolveElectricFiz(String n) {
  const format = PlateFormat(
    backgroundColor: _UzPlateColors.white,
    textColor: _UzPlateColors.border,
    borderColor: _UzPlateColors.border,
    regionBackgroundColor: _UzPlateColors.jungleGreen,
    showFlag: true,
    electricGreenRegion: true,
    mainFlexLeadingStyle: PlateMainFlexLeadingStyle.letterDigitBlock,
  );
  return UzPlateResolved(
    normalized: n,
    category: UzPlateCategory.electric,
    format: format,
    layout: _layoutStandardRightFlag(
      n,
      mainText: '${n[2]} ${n.substring(3, 6)} ${n.substring(6)}',
    ),
  );
}

UzPlateResolved _resolveStandard01G604CC(String n) {
  const format = PlateFormat(
    backgroundColor: _UzPlateColors.white,
    textColor: _UzPlateColors.border,
    borderColor: _UzPlateColors.border,
    showFlag: true,
    mainFlexLeadingStyle: PlateMainFlexLeadingStyle.letterDigitBlock,
  );
  return UzPlateResolved(
    normalized: n,
    category: UzPlateCategory.standard,
    format: format,
    layout: _layoutStandardRightFlag(
      n,
      mainText: '${n[2]} ${n.substring(3, 6)} ${n.substring(6)}',
    ),
  );
}

UzPlateResolved _resolveFiveThree(String n) {
  const format = PlateFormat(
    backgroundColor: _UzPlateColors.white,
    textColor: _UzPlateColors.border,
    borderColor: _UzPlateColors.border,
    showFlag: true,
    mainFlexLeadingStyle: PlateMainFlexLeadingStyle.letterDigitBlock,
  );
  return UzPlateResolved(
    normalized: n,
    category: UzPlateCategory.standard,
    format: format,
    layout: _layoutStandardRightFlag(
      n,
      mainText: '${n.substring(2, 5)} ${n.substring(5)}',
    ),
  );
}

UzPlateResolved _resolveFiveTwo(String n) {
  const format = PlateFormat(
    backgroundColor: _UzPlateColors.white,
    textColor: _UzPlateColors.border,
    borderColor: _UzPlateColors.border,
    showFlag: true,
    mainFlexLeadingStyle: PlateMainFlexLeadingStyle.letterDigitBlock,
  );
  return UzPlateResolved(
    normalized: n,
    category: UzPlateCategory.standard,
    format: format,
    layout: _layoutStandardRightFlag(
      n,
      mainText: '${n.substring(2, 5)} ${n.substring(5)}',
    ),
  );
}

/// Region = first two digits, divider, then [mainText] (already includes spaces), flag.
List<PlateLayoutPart> _layoutStandardRightFlag(
  String n, {
  required String mainText,
}) {
  return [
    PlateLayoutPart(
      kind: PlatePartKind.regionText,
      text: n.substring(0, 2),
      scale: PlateTextScale.region,
    ),
    const PlateLayoutPart(kind: PlatePartKind.divider),
    PlateLayoutPart(
      kind: PlatePartKind.mainGroup,
      text: mainText,
      scale: PlateTextScale.main,
      flex: 1,
    ),
    const PlateLayoutPart(kind: PlatePartKind.flag),
  ];
}

UzPlateResolved _resolveFallback(String n) {
  const format = PlateFormat(
    backgroundColor: _UzPlateColors.white,
    textColor: _UzPlateColors.border,
    borderColor: _UzPlateColors.border,
    showFlag: false,
    useVerticalDivider: false,
    diplomaticSingleField: true,
  );
  return UzPlateResolved(
    normalized: n,
    category: UzPlateCategory.unknown,
    format: format,
    layout: [
      PlateLayoutPart(
        kind: PlatePartKind.mainGroup,
        text: n,
        scale: PlateTextScale.main,
        flex: 1,
      ),
    ],
  );
}

// --- Reusable pieces ---------------------------------------------------------

/// Flag + **UZ** mark from Figma node `18041:9732` (children `9733` flag, `9734` uz).
///
/// SVGs: `plate_uz_flag_figma.svg` (18×13.5 ref), `plate_uz_text_figma.svg` (18×11.25 ref).
/// Outer size follows plate main font: **8×14** at 16px, **18×31** at 36px (see [_PlateMetrics]).
@immutable
class PlateFlag extends StatelessWidget {
  const PlateFlag({
    super.key,
    required this.width,
    required this.stackHeight,
    this.graphicLeadingInset = 0,
    this.uzLabelColor,
  });

  /// Width of the flag+UZ artwork (SVG column).
  final double width;

  /// Total height of the flag+UZ stack (matches small 14 / large 31).
  final double stackHeight;

  /// Empty space inside the flag slot to the left of the SVGs (small/medium; avoids
  /// `allowDrawingOutsideViewBox` bleed eating row padding).
  final double graphicLeadingInset;

  /// Optional tint for the **UZ** vector paths (Figma default `#2196F3`).
  final Color? uzLabelColor;

  static const String _assetFlag = 'assets/images/plate_uz_flag_figma.svg';
  static const String _assetUz = 'assets/images/plate_uz_text_figma.svg';
  static const String _assetPackage = 'uz_license_plate';

  /// Reference artboard width for proportioning inner SVGs (Figma 18px main column).
  static const double _refFlagW = 18;
  static const double _refFlagH = 13.5;
  static const double _refUzH = 11.25;
  static const double _refUzTopOffset = 10.38;

  @override
  Widget build(BuildContext context) {
    final double inset = graphicLeadingInset;
    final double layoutScale = width / _refFlagW;
    final double w = width;
    final double flagH = _refFlagH * layoutScale;
    final double uzH = _refUzH * layoutScale;
    final double stackH = stackHeight;
    final double slotW = w + inset;
    double uzTop = stackH / 2 + _refUzTopOffset * layoutScale - uzH / 2;
    uzTop = uzTop.clamp(0.0, math.max(0.0, stackH - uzH));

    Widget flagSvg = SvgPicture.asset(
      _assetFlag,
      package: _assetPackage,
      width: w,
      height: flagH,
      fit: BoxFit.fill,
      allowDrawingOutsideViewBox: false,
      placeholderBuilder: (_) => SizedBox(width: w, height: flagH),
    );

    Widget uzSvg = SvgPicture.asset(
      _assetUz,
      package: _assetPackage,
      width: w,
      height: uzH,
      fit: BoxFit.fill,
      allowDrawingOutsideViewBox: false,
      placeholderBuilder: (_) => SizedBox(width: w, height: uzH),
    );

    if (uzLabelColor != null) {
      uzSvg = ColorFiltered(
        colorFilter: ColorFilter.mode(uzLabelColor!, BlendMode.srcIn),
        child: uzSvg,
      );
    }

    return Align(
      alignment: Alignment.center,
      child: ClipRect(
        child: SizedBox(
          width: slotW,
          height: stackH,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: inset,
                top: 0,
                width: w,
                height: flagH,
                child: flagSvg,
              ),
              Positioned(
                left: inset,
                top: uzTop,
                width: w,
                height: uzH,
                child: uzSvg,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Plate typography wrapper — [AutoSizeText] inside a bounded box for scaling.
@immutable
class PlateText extends StatelessWidget {
  const PlateText({
    super.key,
    required this.text,
    required this.style,
    this.maxLines = 1,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final TextStyle style;
  final int maxLines;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      maxLines: maxLines,
      textAlign: textAlign,
      minFontSize: 4,
      style: style,
      overflow: TextOverflow.visible,
      softWrap: false,
    );
  }
}

// --- Metrics derived from [UzPlateSize] --------------------------------------

@immutable
class _PlateMetrics {
  const _PlateMetrics({
    required this.scale,
    required this.mainFontSize,
    required this.regionFontSize,
    required this.outerBorderRadius,
    required this.innerBorderRadius,
    required this.frameInset,
    required this.innerStrokeWidth,
    required this.dividerLineWidth,
    required this.contentPaddingH,
    required this.contentPaddingV,
    required this.plateMinHeight,
    required this.flagWidth,
    required this.flagStackHeight,
    required this.flagPaddingLeft,
    required this.flagGraphicLeadingInset,
  });

  /// Figma vertical divider: left edge ≈ 19.39% of inner row width (large standard).
  static const double regionWidthFraction = 0.1939;

  /// Flag+UZ column: 8×14 at main 16px, 18×31 at main 36px (linear between).
  static (double width, double stackHeight) _flagSizeForMainFont(double main) {
    const double m0 = 16;
    const double m1 = 36;
    const double w0 = 8;
    const double w1 = 18;
    const double h0 = 14;
    const double h1 = 31;
    final double t = ((main - m0) / (m1 - m0)).clamp(0.0, 1.0);
    return (w0 + t * (w1 - w0), h0 + t * (h1 - h0));
  }

  final double scale;
  final double mainFontSize;
  final double regionFontSize;
  final double outerBorderRadius;
  final double innerBorderRadius;

  /// Gap between outer ring and inner plate (Figma ~1px large, ~1px small).
  final double frameInset;
  final double innerStrokeWidth;
  final double dividerLineWidth;
  final double contentPaddingH;
  final double contentPaddingV;
  final double plateMinHeight;

  /// Outer [PlateFlag] width / height (8×14 small … 18×31 large).
  final double flagWidth;
  final double flagStackHeight;

  /// Space before the flag column: 4 / 6 / 15 px by [UzPlateSize].
  final double flagPaddingLeft;

  /// Inset inside the flag slot so SVGs do not sit flush left (small/medium).
  final double flagGraphicLeadingInset;

  double regionColumnWidth(double innerRowWidth) {
    final double w = innerRowWidth * regionWidthFraction;
    return math.max(w, 22 * scale);
  }

  static _PlateMetrics fromSize(UzPlateSize size, double? customMainFont) {
    late double refHeight;
    late double refMain;
    late double outerR;
    late double innerR;
    late double innerStroke;
    late double divW;
    late double flagPadLeft;
    late double flagGraphicInset;
    switch (size) {
      case UzPlateSize.small:
        refHeight = 26;
        refMain = 16;
        outerR = 3;
        innerR = 2;
        innerStroke = 1;
        divW = 1;
        flagPadLeft = 4;
        flagGraphicInset = 2;
        break;
      case UzPlateSize.medium:
        refHeight = 40;
        refMain = 26;
        outerR = 4;
        innerR = 3;
        innerStroke = 1.5;
        divW = 1.5;
        flagPadLeft = 6;
        flagGraphicInset = 2;
        break;
      case UzPlateSize.large:
        refHeight = 56;
        refMain = 36;
        outerR = 5;
        innerR = 4;
        innerStroke = 2;
        divW = 2;
        flagPadLeft = 15;
        flagGraphicInset = 0;
        break;
    }
    final double main = (customMainFont != null && customMainFont > 0)
        ? customMainFont
        : refMain;
    final double ratio = main / refMain;
    final double region = main * (22 / 36);
    final double scale = main / 36.0;
    final (double fw, double fh) = _flagSizeForMainFont(main);
    return _PlateMetrics(
      scale: scale,
      mainFontSize: main,
      regionFontSize: region,
      outerBorderRadius: outerR * ratio,
      innerBorderRadius: innerR * ratio,
      frameInset: math.max(1, ratio),
      innerStrokeWidth: innerStroke,
      dividerLineWidth: divW,
      contentPaddingH: 6 * scale,
      contentPaddingV: 4 * scale,
      plateMinHeight: refHeight * ratio,
      flagWidth: fw,
      flagStackHeight: fh,
      flagPaddingLeft: flagPadLeft,
      flagGraphicLeadingInset: flagGraphicInset,
    );
  }
}

// --- Main widget -------------------------------------------------------------

/// Uzbekistan license plate — parses [plateNumber], picks [PlateFormat], builds
/// layout from a flat part list (no nested UI switches).
///
/// Matches Figma (18533:89042): no side dots, #282828 stroke, vertical rule full
/// row height, region column ~19.4% of inner width, outer radii 5/3 (large/small).
@immutable
class UzLicensePlate extends StatelessWidget {
  const UzLicensePlate({
    super.key,
    required this.plateNumber,
    this.size = UzPlateSize.medium,
    this.showFlag = true,
    this.fontSize,
    this.width,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.debugLayout = false,
    this.resolved,
  });

  final String plateNumber;

  /// When set, skips parsing (useful for tests or forced layout).
  final UzPlateResolved? resolved;

  final UzPlateSize size;
  final bool showFlag;

  /// Overrides the size-derived main font size (region scales proportionally).
  final double? fontSize;
  final double? width;

  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;

  /// Draws translucent tints over logical regions for alignment debugging.
  final bool debugLayout;

  static const String _fontFamily = 'FE Schrift';

  TextStyle _textStyle(
    PlateFormat format,
    _PlateMetrics m,
    PlateTextScale scaleKind,
  ) {
    final double fs = scaleKind == PlateTextScale.region
        ? m.regionFontSize
        : m.mainFontSize;
    final Color fg = textColor ?? format.textColor;
    return TextStyle(
      package: 'uz_license_plate',
      fontFamily: _fontFamily,
      fontSize: fs,
      fontWeight: FontWeight.w500,
      color: fg,
      letterSpacing: -0.27 * (fs / 14),
      height: Platform.isAndroid ? -0.5 : 1.2,
    );
  }

  double _contentRowHeight(PlateFormat format, _PlateMetrics m) {
    double h = m.plateMinHeight;
    if (format.outerRingColor != null) {
      h -= 2 * m.frameInset;
    }
    h -= 2 * m.innerStrokeWidth;
    h -= 2 * m.contentPaddingV;
    return math.max(h, m.mainFontSize * 1.2);
  }

  @override
  Widget build(BuildContext context) {
    final UzPlateResolved data =
        resolved ?? parseUzPlate(plateNumber) ?? _resolveFallback(plateNumber);
    final PlateFormat baseFormat = data.format;
    final PlateFormat format = baseFormat.copyWith(
      backgroundColor: backgroundColor ?? baseFormat.backgroundColor,
      textColor: textColor ?? baseFormat.textColor,
      borderColor: borderColor ?? baseFormat.borderColor,
    );

    final _PlateMetrics m = _PlateMetrics.fromSize(size, fontSize);
    final Color strokeColor = format.borderColor;
    final double rowH = _contentRowHeight(format, m);
    final double innerContentH = rowH + 2 * m.contentPaddingV;

    final bool needsRowWidth = data.layout.any(
      (p) => p.kind == PlatePartKind.mainGroup && p.flex != null,
    );
    final double defaultPlateWidth = 263 * m.scale;
    final double? effectiveWidth =
        width ?? (needsRowWidth ? defaultPlateWidth : null);

    List<Widget> buildRowChildren(double innerMaxWidth) {
      final double layoutW = innerMaxWidth.isFinite && innerMaxWidth > 0
          ? innerMaxWidth
          : (effectiveWidth ?? defaultPlateWidth).clamp(88.0, 420.0);
      final double regionW = m.regionColumnWidth(layoutW);

      final List<Widget> children = [];
      for (final PlateLayoutPart part in data.layout) {
        switch (part.kind) {
          case PlatePartKind.divider:
            if (!format.useVerticalDivider) break;
            final div = Container(
              width: m.dividerLineWidth,
              color: _UzPlateColors.border,
            );
            children.add(
              _wrapDebug(
                debugLayout,
                Colors.orange.withValues(alpha: 0.25),
                div,
              ),
            );
            break;
          case PlatePartKind.regionText:
            final Color? regionBg = format.regionBackgroundColor;
            final text = PlateText(
              text: part.text ?? '',
              style: _textStyle(format, m, PlateTextScale.region),
              textAlign: TextAlign.center,
            );
            final padded = Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 3 * m.scale,
                vertical: m.contentPaddingV,
              ),
              child: Center(child: text),
            );
            Widget cell = padded;
            if (regionBg != null) {
              cell = DecoratedBox(
                decoration: BoxDecoration(
                  color: regionBg,
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(m.innerBorderRadius * 0.5),
                  ),
                ),
                child: padded,
              );
            }
            children.add(
              _wrapDebug(
                debugLayout,
                Colors.blue.withValues(alpha: 0.12),
                SizedBox(width: regionW, child: cell),
              ),
            );
            break;
          case PlatePartKind.mainGroup:
            final style = _textStyle(
              format,
              m,
              part.scale,
            ).copyWith(color: textColor ?? format.textColor);
            final widget = PlateText(
              text: part.text ?? '',
              style: style,
              textAlign: TextAlign.center,
            );
            final bool truckTaxiMain =
                data.category == UzPlateCategory.taxi ||
                data.category == UzPlateCategory.truckBus;
            final double truckTaxiRight = truckTaxiMain && part.flex != null
                ? (size == UzPlateSize.large ? 26.0 : 12.0)
                : 0.0;
            final double mainFlexLeft = part.flex != null
                ? _mainFlexLeadingPixels(format.mainFlexLeadingStyle, size)
                : 0.0;
            final wrapped = Padding(
              padding: EdgeInsets.only(
                top: m.contentPaddingV,
                bottom: m.contentPaddingV,
                left: mainFlexLeft,
                right: truckTaxiRight,
              ),
              child: Center(child: widget),
            );
            if (part.flex != null) {
              children.add(
                _wrapDebug(
                  debugLayout,
                  Colors.green.withValues(alpha: 0.12),
                  Expanded(flex: part.flex!, child: wrapped),
                ),
              );
            } else {
              children.add(
                _wrapDebug(
                  debugLayout,
                  Colors.green.withValues(alpha: 0.12),
                  wrapped,
                ),
              );
            }
            break;
          case PlatePartKind.flag:
            if (!showFlag || !format.showFlag) break;
            final flag = PlateFlag(
              width: m.flagWidth,
              stackHeight: m.flagStackHeight,
              graphicLeadingInset: m.flagGraphicLeadingInset,
            );
            final EdgeInsets flagPad = format.flagOnLeft
                ? EdgeInsets.only(
                    left: m.flagPaddingLeft,
                    right: 6 * m.scale,
                    top: m.contentPaddingV,
                    bottom: m.contentPaddingV,
                  )
                : EdgeInsets.only(
                    left: m.flagPaddingLeft,
                    right: 4 * m.scale,
                    top: m.contentPaddingV,
                    bottom: m.contentPaddingV,
                  );
            children.add(
              Padding(
                padding: flagPad,
                child: _wrapDebug(
                  debugLayout,
                  Colors.red.withValues(alpha: 0.12),
                  flag,
                ),
              ),
            );
            break;
        }
      }
      return children;
    }

    final inner = LayoutBuilder(
      builder: (context, c) {
        return SizedBox(
          height: innerContentH,
          child: Row(
            mainAxisSize: effectiveWidth != null
                ? MainAxisSize.max
                : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: buildRowChildren(c.maxWidth),
          ),
        );
      },
    );

    final strokedPlate = Container(
      decoration: BoxDecoration(
        color: format.backgroundColor,
        borderRadius: BorderRadius.circular(
          format.outerRingColor != null
              ? m.innerBorderRadius
              : m.outerBorderRadius,
        ),
        border: Border.all(color: strokeColor, width: m.innerStrokeWidth),
      ),
      padding: EdgeInsets.symmetric(horizontal: m.contentPaddingH),
      child: inner,
    );

    final Color? outerRing = format.outerRingColor;
    if (outerRing != null) {
      return SizedBox(
        width: effectiveWidth,
        child: _plateOuterBorder(
          m,
          borderColor: outerRing,
          child: Container(
            constraints: BoxConstraints(minHeight: m.plateMinHeight),
            decoration: BoxDecoration(
              color: outerRing,
              borderRadius: BorderRadius.circular(m.outerBorderRadius),
            ),
            padding: EdgeInsets.all(m.frameInset),
            child: strokedPlate,
          ),
        ),
      );
    }

    return SizedBox(
      width: effectiveWidth,
      child: _plateOuterBorder(
        m,
        borderColor: format.backgroundColor,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(m.outerBorderRadius),
          child: Container(
            constraints: BoxConstraints(minHeight: m.plateMinHeight),
            decoration: BoxDecoration(
              color: format.backgroundColor,
              borderRadius: BorderRadius.circular(m.outerBorderRadius),
            ),
            alignment: Alignment.center,
            child: strokedPlate,
          ),
        ),
      ),
    );
  }

  /// 1px ring outside the plate; [borderColor] matches face / outer shell (from
  /// [format.backgroundColor] or [PlateFormat.outerRingColor], including
  /// [UzLicensePlate.backgroundColor] override).
  Widget _plateOuterBorder(
    _PlateMetrics m, {
    required Color borderColor,
    required Widget child,
  }) {
    final double r = m.outerBorderRadius;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(r), child: child),
    );
  }

  Widget _wrapDebug(bool debug, Color color, Widget child) {
    if (!debug) return child;
    return ColoredBox(color: color, child: child);
  }
}
