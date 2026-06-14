import 'package:flutter/material.dart';

enum DeviceType { phone, tablet, desktop }

class ResponsiveHelper {
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return DeviceType.phone;
    if (width < 1200) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isPhone(BuildContext context) =>
      getDeviceType(context) == DeviceType.phone;

  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  static int getCrossAxisCount(BuildContext context, {int phoneCols = 2, int tabletCols = 3, int desktopCols = 4}) {
    switch (getDeviceType(context)) {
      case DeviceType.phone:
        return phoneCols;
      case DeviceType.tablet:
        return tabletCols;
      case DeviceType.desktop:
        return desktopCols;
    }
  }

  static double getFontScale(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.phone:
        return 0.85;
      case DeviceType.tablet:
        return 1.0;
      case DeviceType.desktop:
        return 1.1;
    }
  }

  static EdgeInsets getScreenPadding(BuildContext context) {
    switch (getDeviceType(context)) {
      case DeviceType.phone:
        return const EdgeInsets.all(12);
      case DeviceType.tablet:
        return const EdgeInsets.all(20);
      case DeviceType.desktop:
        return const EdgeInsets.all(32);
    }
  }
}
