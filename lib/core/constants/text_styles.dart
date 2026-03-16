import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  // Display Styles - Cormorant Garamond (fallback to serif)
  static TextStyle displayLarge = const TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: -1,
    fontFamily: 'serif',
  );
  
  static TextStyle displayMedium = const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: -0.5,
    fontFamily: 'serif',
  );
  
  static TextStyle displaySmall = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    fontFamily: 'serif',
  );
  
  // Body Styles - DM Sans (fallback to sans-serif)
  static TextStyle bodyLarge = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    fontFamily: 'sans-serif',
  );
  
  static TextStyle bodyMedium = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    fontFamily: 'sans-serif',
  );
  
  static TextStyle bodySmall = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    fontFamily: 'sans-serif',
  );
  
  // Caption Styles
  static TextStyle caption = const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.sub,
    letterSpacing: 0.5,
    fontFamily: 'sans-serif',
  );
  
  static TextStyle tagline = const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.sub,
    letterSpacing: 0.5,
    height: 1.7,
    fontFamily: 'sans-serif',
  );
  
  // Button Styles
  static TextStyle buttonLarge = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
    fontFamily: 'sans-serif',
  );
  
  static TextStyle buttonSmall = const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.4,
    fontFamily: 'sans-serif',
  );
  
  // Label Styles
  static TextStyle label = const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.muted,
    letterSpacing: 0.8,
    fontFamily: 'sans-serif',
  );
}
