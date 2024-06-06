import 'package:flutter/widgets.dart';

class Utils {
  static bool isLargeScreen(context) {
    double mediaWidth = MediaQuery.of(context).size.width;

    if (mediaWidth < 600) {
      return false;
    }

    return true;
  }
}
