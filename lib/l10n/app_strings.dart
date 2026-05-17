import 'package:flutter/material.dart';
import 'package:sugacke/l10n/translations.dart';

class AppStrings {
  AppStrings(this.context);

  final BuildContext context;

  static AppStrings of(BuildContext context) => AppStrings(context);

  static const Locale english = AppTranslations.english;
  static const Locale arabic = AppTranslations.arabic;

  bool get isArabic => AppTranslations.isArabic(context);

  String t(String key) {
    if (key == 'appTitle') {
      return AppTranslations.text(context, 'app_name');
    }
    return AppTranslations.text(context, key);
  }
}
