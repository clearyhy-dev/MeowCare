import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static List<BoxShadow> get soft => const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get subtle => const [
        BoxShadow(
          color: Color(0x10000000),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ];

  /// Feed / settings grouped surfaces — prefer over [soft] for less float.
  static List<BoxShadow> get card => subtle;
}
