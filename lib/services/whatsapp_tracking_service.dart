import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sugacke/global/country_currency_config.dart';
import 'package:sugacke/global/global.dart';

class WhatsAppTrackingService {
  static Future<void> openTrackedChat({
    required String phoneNumber,
    required String storeName,
    required String country,
    String? itemTitle,
    String? customMessage,
  }) async {
    final sanitizedPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '').trim();
    if (sanitizedPhone.isEmpty) return;

    await FirebaseAnalytics.instance.logEvent(
      name: 'whatsapp_lead',
      parameters: {
        'store_name': storeName.trim().isEmpty
            ? 'unknown_store'
            : storeName.trim(),
        'phone_number': sanitizedPhone,
        'country': resolveCountry(country),
      },
    );

    final message = Uri.encodeComponent(
      customMessage != null && customMessage.trim().isNotEmpty
          ? customMessage.trim()
          : itemTitle == null || itemTitle.trim().isEmpty
          ? 'Hello, I am interested in your item.'
          : "Hello, I'm interested in your product: ${itemTitle.trim()}",
    );
    final uri = Uri.parse('https://wa.me/$sanitizedPhone?text=$message');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static String resolveCountry(String? selectedCountry) {
    final countryNames = getCountryNamesSorted();
    if (selectedCountry != null && countryNames.contains(selectedCountry)) {
      return selectedCountry;
    }

    final savedCountry = sharedPreferences?.getString('country');
    if (savedCountry != null && countryNames.contains(savedCountry)) {
      return savedCountry;
    }

    if (countryNames.contains('Saudi Arabia')) return 'Saudi Arabia';
    return countryNames.first;
  }
}
