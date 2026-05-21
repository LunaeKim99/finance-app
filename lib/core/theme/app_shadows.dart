import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  // Level 0: no shadow (background)

  // Level 1: Cards — very soft, diffused shadow
  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color(0x26000000),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  // Level 2: Modals/Popovers — stronger shadow with subtle inner stroke
  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  // Bottom nav shadow
  static const List<BoxShadow> nav = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 10,
      offset: Offset(0, -1),
    ),
  ];
}
