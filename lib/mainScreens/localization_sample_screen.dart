import 'package:flutter/material.dart';
import 'package:sugacke/l10n/app_strings.dart';

class LocalizationSampleScreen extends StatelessWidget {
  const LocalizationSampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isArabic = strings.isArabic;

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('welcome'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.t('search')),
            const SizedBox(height: 12),
            Text(isArabic ? 'بحث' : 'Search'),
            const SizedBox(height: 12),
            Text(strings.t('home')),
          ],
        ),
      ),
    );
  }
}
