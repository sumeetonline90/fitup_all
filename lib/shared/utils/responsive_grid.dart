import 'package:flutter/material.dart';

/// Returns column count for a responsive tile grid based on viewport width.
///
/// Breakpoints aligned with ADR-030 (768 / 1024).
/// `mobile`, `tablet`, `desktop`, `wide` are the column counts for each band.
int responsiveColumns(
  BuildContext context, {
  int mobile = 2,
  int tablet = 3,
  int desktop = 4,
  int wide = 5,
}) {
  final double w = MediaQuery.sizeOf(context).width;
  if (w >= 1440) return wide;
  if (w >= 1024) return desktop;
  if (w >= 768) return tablet;
  return mobile;
}

/// Aspect ratio matched to typical tile content density.
/// Use larger value (wider) for denser, more columns to keep cards readable.
double responsiveAspect(
  BuildContext context, {
  double mobile = 1.15,
  double tablet = 1.10,
  double desktop = 1.05,
  double wide = 1.0,
}) {
  final double w = MediaQuery.sizeOf(context).width;
  if (w >= 1440) return wide;
  if (w >= 1024) return desktop;
  if (w >= 768) return tablet;
  return mobile;
}
