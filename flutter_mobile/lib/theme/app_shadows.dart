import 'package:flutter/material.dart';

class AppShadows {
  static const BoxShadow glowPrimary = BoxShadow(
    color: Color(0x592196F3), // rgba(33, 150, 243, 0.35)
    blurRadius: 20,
    offset: Offset(0, 4),
  );

  static const BoxShadow glowSupport = BoxShadow(
    color: Color(0x599C27B0), // rgba(156, 39, 176, 0.35)
    blurRadius: 12,
    offset: Offset(0, 0),
  );

  static const BoxShadow bottomNav = BoxShadow(
    color: Color(0x99000000), // rgba(0, 0, 0, 0.6)
    blurRadius: 24,
    offset: Offset(0, -4),
  );

  static const BoxShadow bottomSheet = BoxShadow(
    color: Color(0x99000000), // rgba(0, 0, 0, 0.6)
    blurRadius: 30,
    offset: Offset(0, -8),
  );

  static const BoxShadow tertiaryGlow = BoxShadow(
    color: Color(0xE678DC77), // rgba(120, 220, 119, 0.9)
    blurRadius: 8,
    offset: Offset(0, 0),
  );
}
