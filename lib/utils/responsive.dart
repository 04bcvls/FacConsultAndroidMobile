import 'package:flutter/material.dart';

/// Responsive sizing utility for handling different screen sizes
class ResponsiveSize {
  static late MediaQueryData _mediaQuery;

  static void init(BuildContext context) {
    _mediaQuery = MediaQuery.of(context);
  }

  /// Screen width
  static double get screenWidth => _mediaQuery.size.width;

  /// Screen height
  static double get screenHeight => _mediaQuery.size.height;

  /// Device padding (notch, safe area)
  static EdgeInsets get devicePadding => _mediaQuery.padding;

  /// Check if device is in landscape
  static bool get isLandscape => _mediaQuery.orientation == Orientation.landscape;

  /// Check if device is portrait
  static bool get isPortrait => _mediaQuery.orientation == Orientation.portrait;

  /// Check if screen is small (< 600px width)
  static bool get isSmall => screenWidth < 600;

  /// Check if screen is medium (600-900px width)
  static bool get isMedium => screenWidth >= 600 && screenWidth < 900;

  /// Check if screen is large (>= 900px width)
  static bool get isLarge => screenWidth >= 900;

  /// Check if it's a tall phone (aspect ratio > 2)
  static bool get isTallPhone => screenHeight / screenWidth > 2;

  /// Responsive padding - scales based on screen width
  static double paddingXSmall() => screenWidth * 0.02;
  static double paddingSmall() => screenWidth * 0.04;
  static double paddingMedium() => screenWidth * 0.06;
  static double paddingLarge() => screenWidth * 0.08;
  static double paddingXLarge() => screenWidth * 0.10;

  /// Responsive font sizes
  static double fontXSmall() => _scale(10);
  static double fontSmall() => _scale(12);
  static double fontBody() => _scale(14);
  static double fontSubtitle() => _scale(16);
  static double fontTitle() => _scale(18);
  static double fontHeading() => _scale(24);
  static double fontLargeHeading() => _scale(28);
  static double fontXLargeHeading() => _scale(32);

  /// Responsive heights for common components
  static double buttonHeight() => _scale(48);
  static double cardPadding() => paddingMedium();
  static double profileImageHeight() => screenWidth * 0.35;
  static double facutyCardHeight() => screenWidth * 0.25;
  static double scheduleCardHeight() => screenWidth * 0.3;

  /// Responsive icon sizes
  static double iconSmall() => _scale(16);
  static double iconMedium() => _scale(24);
  static double iconLarge() => _scale(32);
  static double iconXLarge() => _scale(48);

  /// Responsive spacing
  static double spacing2() => _scale(2);
  static double spacing4() => _scale(4);
  static double spacing6() => _scale(6);
  static double spacing8() => _scale(8);
  static double spacing12() => _scale(12);
  static double spacing16() => _scale(16);
  static double spacing24() => _scale(24);
  static double spacing32() => _scale(32);
  static double spacing40() => _scale(40);
  static double spacing48() => _scale(48);

  /// Internal scaling function based on base width of 390
  static double _scale(double value) {
    const double baseWidth = 390; // Standard mobile width
    return (screenWidth / baseWidth) * value;
  }

  /// Get responsive EdgeInsets for padding
  static EdgeInsets paddingAll(double value) =>
      EdgeInsets.all(paddingMedium() * value);

  static EdgeInsets paddingSymmetric({double horizontal = 1.0, double vertical = 1.0}) =>
      EdgeInsets.symmetric(
        horizontal: paddingMedium() * horizontal,
        vertical: paddingMedium() * vertical,
      );

  static EdgeInsets paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(
        left: paddingMedium() * left,
        top: paddingMedium() * top,
        right: paddingMedium() * right,
        bottom: paddingMedium() * bottom,
      );
}

/// Widget extension for responsive context initialization
extension ResponsiveContextExtension on BuildContext {
  void initResponsive() {
    ResponsiveSize.init(this);
  }
}
