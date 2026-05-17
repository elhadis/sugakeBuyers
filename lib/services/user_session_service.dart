import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sugacke/global/global.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Loads seller/user profile from Firestore into [sharedPreferences] and
/// clears all session keys on logout.
class UserSessionService {
  UserSessionService._();

  /// Every key the app uses for signed-in user / profile state.
  static const List<String> _sessionKeys = [
    'uid',
    'name',
    'email',
    'phone',
    'photoUrl',
    'storeCategory',
    'addressCurrency',
    'country',
  ];

  static Future<void> loadSellerIntoSharedPreferences(User user) async {
    final prefs = await SharedPreferences.getInstance();
    sharedPreferences = prefs;

    DocumentSnapshot<Map<String, dynamic>>? resolved;
    final sellerSnap = await FirebaseFirestore.instance
        .collection('sellers')
        .doc(user.uid)
        .get();
    if (sellerSnap.exists && sellerSnap.data() != null) {
      resolved = sellerSnap;
    } else {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userSnap.exists && userSnap.data() != null) {
        resolved = userSnap;
      }
    }

    if (resolved == null || resolved.data() == null) {
      await prefs.setString('uid', user.uid);
      await prefs.setString('email', user.email ?? '');
      await prefs.setString('name', user.displayName ?? '');
      await prefs.setString(
        'photoUrl',
        user.photoURL ?? '',
      );
      await prefs.setString('phone', '');
      await prefs.setString('storeCategory', 'Others');
      await prefs.setString('addressCurrency', 'SDG');
      await prefs.remove('country');
      return;
    }

    final data = resolved.data()!;
    final name = (data['name'] ?? '').toString();
    final email = (data['email'] ?? user.email ?? '').toString();
    final phone = (data['phone'] ?? '').toString();
    final photoUrl = (data['photoUrl'] ?? '').toString();
    final storeCategory = (data['storeCategory'] ?? 'Others').toString();
    final currency = (data['currency'] ?? data['addressCurrency'] ?? 'SDG')
        .toString();
    final country = (data['country'] ?? '').toString();

    await prefs.setString('uid', user.uid);
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('phone', phone);
    await prefs.setString('photoUrl', photoUrl);
    await prefs.setString('storeCategory', storeCategory);
    await prefs.setString('addressCurrency', currency);
    if (country.isNotEmpty) {
      await prefs.setString('country', country);
    }
  }

  /// Removes all persisted session fields so the next launch has no user cache.
  static Future<void> clearSellerSession() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _sessionKeys) {
      await prefs.remove(key);
    }
    sharedPreferences = prefs;
  }
}
