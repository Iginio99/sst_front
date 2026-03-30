import 'package:flutter/widgets.dart';

class ResponsiveBreakpoints {
  static const double mobile = 900;
  static const double desktop = 1200;

  static double widthOf(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static bool isMobile(BuildContext context) => widthOf(context) < mobile;

  static bool isTablet(BuildContext context) {
    final width = widthOf(context);
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) => widthOf(context) >= desktop;
}
