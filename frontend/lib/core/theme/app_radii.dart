import 'package:flutter/material.dart';

/// Centralized Border Radius Tokens for AgriVerse AI.
class AppRadii {
  // Raw radius scalar values
  static const double xsValue = 6.0;
  static const double smValue = 10.0;
  static const double mdValue = 14.0;
  static const double lgValue = 18.0;
  static const double xlValue = 24.0;
  static const double xxlValue = 28.0;
  static const double headerCurveValue = 32.0;
  static const double pillValue = 999.0;

  // Reusable BorderRadius constants
  static const BorderRadius none = BorderRadius.zero;
  static const BorderRadius xs = BorderRadius.all(Radius.circular(xsValue));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(smValue));
  static const BorderRadius md = BorderRadius.all(Radius.circular(mdValue));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(lgValue));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(xlValue));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(xxlValue));
  static const BorderRadius headerCurve = BorderRadius.vertical(
    bottom: Radius.circular(headerCurveValue),
  );
  static const BorderRadius pill = BorderRadius.all(Radius.circular(pillValue));

  // Top-only sheet borders
  static const BorderRadius topSheet = BorderRadius.vertical(
    top: Radius.circular(xlValue),
  );
}
