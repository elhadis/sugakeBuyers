import 'package:flutter/material.dart';

class AppUiTokens {
  static const double maxContentWidth = 980;
  static const double maxCompactContentWidth = 620;
  static const double pageHorizontalPadding = 10;
  static const double cardRadius = 14;
  static const double chipRadius = 20;

  static const Color pageBackground = Color(0xFFF8F9FB);
  static const Color cardBackground = Colors.white;
  static const Color whatsapp = Color(0xFF25D366);

  static const List<BoxShadow> softCardShadow = [
    BoxShadow(
      color: Color(0x22000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
}
