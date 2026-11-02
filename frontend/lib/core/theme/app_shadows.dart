import 'package:flutter/material.dart';

/// Centralized Elevation & Box Shadow Tokens for AgriVerse AI.
class AppShadows {
  // Ambient soft shadows for light theme
  static const List<BoxShadow> subtle = [
    BoxShadow(color: Color(0x080F3826), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0D0F3826), blurRadius: 14, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(color: Color(0x140F3826), blurRadius: 20, offset: Offset(0, 6)),
  ];

  static const List<BoxShadow> modal = [
    BoxShadow(color: Color(0x240F3826), blurRadius: 28, offset: Offset(0, 10)),
  ];

  static const List<BoxShadow> bottomBar = [
    BoxShadow(color: Color(0x0C000000), blurRadius: 16, offset: Offset(0, -4)),
  ];

  // Dark theme shadow equivalents
  static const List<BoxShadow> darkCard = [
    BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> darkElevated = [
    BoxShadow(color: Color(0x60000000), blurRadius: 20, offset: Offset(0, 8)),
  ];
}
