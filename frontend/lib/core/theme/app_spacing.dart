import 'package:flutter/material.dart';

/// Centralized Spacing Scale for AgriVerse AI.
/// Built on an 8-point spatial grid with 4-point micro-increments.
class AppSpacing {
  // Raw dimensional values
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 40.0;
  static const double giant = 48.0;

  // Reusable EdgeInsets Tokens
  static const EdgeInsets zero = EdgeInsets.zero;

  // All-sides padding
  static const EdgeInsets p4 = EdgeInsets.all(xxs);
  static const EdgeInsets p8 = EdgeInsets.all(xs);
  static const EdgeInsets p12 = EdgeInsets.all(sm);
  static const EdgeInsets p16 = EdgeInsets.all(md);
  static const EdgeInsets p20 = EdgeInsets.all(lg);
  static const EdgeInsets p24 = EdgeInsets.all(xl);
  static const EdgeInsets p32 = EdgeInsets.all(xxl);

  // Horizontal padding
  static const EdgeInsets h8 = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets h12 = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets h16 = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets h20 = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets h24 = EdgeInsets.symmetric(horizontal: xl);

  // Vertical padding
  static const EdgeInsets v4 = EdgeInsets.symmetric(vertical: xxs);
  static const EdgeInsets v8 = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets v12 = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets v16 = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets v20 = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets v24 = EdgeInsets.symmetric(vertical: xl);

  // Screen level standard padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(md);
  static const EdgeInsets modalPadding = EdgeInsets.fromLTRB(xl, xl, xl, xxl);
}
