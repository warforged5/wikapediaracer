import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Utility class for responsive text sizing and spacing
class ResponsiveText {
  /// Get a responsive font size based on screen dimensions
  static double getResponsiveFontSize({
    required BuildContext context,
    required double baseFontSize,
    double? minFontSize,
    double? maxFontSize,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    
    // Calculate scale factor based on screen size
    double scaleFactor = _getScaleFactor(shortestSide);
    
    // Apply screen density adjustment
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    if (devicePixelRatio > 2.0) {
      // High DPI screens can handle slightly larger text
      scaleFactor *= 1.02;
    } else if (devicePixelRatio < 1.5) {
      // Low DPI screens need slightly smaller text for clarity
      scaleFactor *= 0.98;
    }
    
    double responsiveFontSize = baseFontSize * scaleFactor;
    
    // Apply bounds if provided
    if (minFontSize != null) {
      responsiveFontSize = math.max(responsiveFontSize, minFontSize);
    }
    if (maxFontSize != null) {
      responsiveFontSize = math.min(responsiveFontSize, maxFontSize);
    }
    
    return responsiveFontSize;
  }
  
  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding({
    required BuildContext context,
    required double basePadding,
    double? minPadding,
    double? maxPadding,
  }) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    double scaleFactor = _getScaleFactor(shortestSide);
    
    double responsivePadding = basePadding * scaleFactor;
    
    if (minPadding != null) {
      responsivePadding = math.max(responsivePadding, minPadding);
    }
    if (maxPadding != null) {
      responsivePadding = math.min(responsivePadding, maxPadding);
    }
    
    return EdgeInsets.all(responsivePadding);
  }
  
  /// Get responsive margins based on screen size
  static EdgeInsets getResponsiveMargin({
    required BuildContext context,
    required double baseMargin,
    double? minMargin,
    double? maxMargin,
  }) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    double scaleFactor = _getScaleFactor(shortestSide);
    
    double responsiveMargin = baseMargin * scaleFactor;
    
    if (minMargin != null) {
      responsiveMargin = math.max(responsiveMargin, minMargin);
    }
    if (maxMargin != null) {
      responsiveMargin = math.min(responsiveMargin, maxMargin);
    }
    
    return EdgeInsets.all(responsiveMargin);
  }
  
  /// Get a responsive icon size
  static double getResponsiveIconSize({
    required BuildContext context,
    required double baseIconSize,
    double? minIconSize,
    double? maxIconSize,
  }) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    double scaleFactor = _getScaleFactor(shortestSide);
    
    double responsiveIconSize = baseIconSize * scaleFactor;
    
    if (minIconSize != null) {
      responsiveIconSize = math.max(responsiveIconSize, minIconSize);
    }
    if (maxIconSize != null) {
      responsiveIconSize = math.min(responsiveIconSize, maxIconSize);
    }
    
    return responsiveIconSize;
  }
  
  /// Get responsive border radius
  static double getResponsiveBorderRadius({
    required BuildContext context,
    required double baseRadius,
    double? minRadius,
    double? maxRadius,
  }) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    double scaleFactor = _getScaleFactor(shortestSide);
    
    double responsiveRadius = baseRadius * scaleFactor;
    
    if (minRadius != null) {
      responsiveRadius = math.max(responsiveRadius, minRadius);
    }
    if (maxRadius != null) {
      responsiveRadius = math.min(responsiveRadius, maxRadius);
    }
    
    return responsiveRadius;
  }
  
  /// Check if the current device is compact (small screen)
  static bool isCompactDevice(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 600;
  }
  
  /// Check if the current device is very compact (very small screen)
  static bool isVeryCompactDevice(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide < 375;
  }
  
  /// Check if the screen height is constrained
  static bool isHeightConstrained(BuildContext context) {
    return MediaQuery.of(context).size.height < 600;
  }
  
  /// Check if the screen height is very constrained
  static bool isVeryHeightConstrained(BuildContext context) {
    return MediaQuery.of(context).size.height < 500;
  }
  
  /// Get device category for responsive design decisions
  static DeviceCategory getDeviceCategory(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    
    if (shortestSide < 320) return DeviceCategory.verySmall;
    if (shortestSide < 375) return DeviceCategory.small;
    if (shortestSide < 414) return DeviceCategory.medium;
    if (shortestSide < 500) return DeviceCategory.large;
    if (shortestSide < 768) return DeviceCategory.tablet;
    return DeviceCategory.desktop;
  }
  
  /// Private method to calculate scale factor based on shortest side
  static double _getScaleFactor(double shortestSide) {
    if (shortestSide < 320) {
      return 0.75; // Very small devices
    } else if (shortestSide < 375) {
      return 0.85; // Small devices
    } else if (shortestSide < 414) {
      return 1.0; // Standard devices (base scale)
    } else if (shortestSide < 500) {
      return 1.05; // Large phones
    } else if (shortestSide < 768) {
      return 1.15; // Small tablets
    } else if (shortestSide < 1024) {
      return 1.25; // Large tablets
    } else {
      return 1.35; // Desktop
    }
  }
}

/// Device categories for responsive design
enum DeviceCategory {
  verySmall,  // < 320dp (very old phones)
  small,      // 320-374dp (iPhone SE, small Android phones)
  medium,     // 375-413dp (iPhone 12/13/14, most Android phones)
  large,      // 414-499dp (iPhone Pro Max, large Android phones)
  tablet,     // 500-767dp (small tablets)
  desktop,    // >= 768dp (large tablets, desktops)
}

/// Extension on TextStyle for easy responsive font sizing
extension ResponsiveTextStyle on TextStyle {
  TextStyle responsive(BuildContext context, {
    double? minFontSize,
    double? maxFontSize,
  }) {
    if (fontSize == null) return this;
    
    final responsiveFontSize = ResponsiveText.getResponsiveFontSize(
      context: context,
      baseFontSize: fontSize!,
      minFontSize: minFontSize,
      maxFontSize: maxFontSize,
    );
    
    return copyWith(fontSize: responsiveFontSize);
  }
}