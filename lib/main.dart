import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sugacke/firebase_options.dart';
import 'package:sugacke/global/global.dart';
import 'package:sugacke/l10n/translations.dart';
import 'package:sugacke/mainScreens/item_details_screen.dart';
import 'package:sugacke/mainScreens/main_wrapper.dart';
import 'package:sugacke/services/whatsapp_tracking_service.dart';

/// Global navigator key to navigate from notification callbacks.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Android channel used for high-importance notifications with sound.
const AndroidNotificationChannel highImportanceChannel =
    AndroidNotificationChannel(
      'new_item_high_importance_channel',
      'New Item Notifications',
      description: 'Used for important new item alerts.',
      importance: Importance.max,
      playSound: true,
    );

/// Local notifications plugin instance.
final FlutterLocalNotificationsPlugin localNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Handles background FCM messages.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Reusable WhatsApp launcher helper.
/// Accepts a phone number and optional prefilled message.
Future<void> openWhatsAppChat({
  required String ownerPhone,
  String storeName = 'unknown_store',
  String? country,
  String message = 'Hello, I am interested in your item.',
}) async {
  await WhatsAppTrackingService.openTrackedChat(
    phoneNumber: ownerPhone,
    storeName: storeName,
    country: WhatsAppTrackingService.resolveCountry(country),
    customMessage: message,
  );
}

/// Model for notification payload.
class NewItemNotificationData {
  final String itemId;
  final String itemTitle;
  final String thumbnailUrl;
  final String itemPrice;
  final String currency;
  final String storeName;
  final String brandName;
  final String ownerPhone;

  const NewItemNotificationData({
    required this.itemId,
    required this.itemTitle,
    required this.thumbnailUrl,
    required this.itemPrice,
    required this.currency,
    required this.storeName,
    required this.brandName,
    required this.ownerPhone,
  });

  factory NewItemNotificationData.fromMap(Map<String, dynamic> map) {
    return NewItemNotificationData(
      itemId: (map['itemId'] ?? '').toString(),
      itemTitle: (map['itemTitle'] ?? map['title'] ?? 'New Item').toString(),
      thumbnailUrl:
          (map['thumbnailUrl'] ??
                  map['itemImage'] ??
                  map['thumbanilurl'] ??
                  map['imageUrl'] ??
                  '')
              .toString(),
      itemPrice: (map['itemPrice'] ?? map['price'] ?? '').toString(),
      currency: (map['currency'] ?? '₪').toString(),
      storeName:
          (map['storeName'] ?? map['sellerName'] ?? map['brandName'] ?? '')
              .toString(),
      brandName:
          (map['brandName'] ?? map['storeName'] ?? map['sellerName'] ?? '')
              .toString(),
      ownerPhone:
          (map['ownerPhone'] ?? map['sellerPhone'] ?? map['phone'] ?? '')
              .toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'itemTitle': itemTitle,
    'thumbnailUrl': thumbnailUrl,
    'itemImage': thumbnailUrl,
    'itemPrice': itemPrice,
    'currency': currency,
    'storeName': storeName,
    'brandName': brandName,
    'ownerPhone': ownerPhone,
  };
}

/// Notification service for Firebase Messaging and local notifications.
class PushNotificationService {
  static Future<void> initialize() async {
    // Everything below depends on Google Play Services / FCM, which may be
    // missing on bare AOSP emulators. Failures here MUST NOT prevent the app
    // from starting.
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Local notifications (after push permission so iOS shows one dialog when needed).
      try {
        await _initializeLocalNotifications();
      } catch (e, st) {
        debugPrint('⚠️ Local notifications init failed: $e\n$st');
      }

      // Subscribe in the background; never block app startup on this.
      unawaited(_subscribeToNewItemsTopic(messaging));

      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        await _showForegroundNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleRemoteMessageNavigation(message);
      });

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleRemoteMessageNavigation(initialMessage);
      }
    } catch (e, st) {
      debugPrint('⚠️ Firebase Messaging init failed (likely no Play Services): $e\n$st');
    }
  }

  static Future<void> _subscribeToNewItemsTopic(FirebaseMessaging messaging) async {
    try {
      await messaging.subscribeToTopic('new_items');
      if (kDebugMode) {
        debugPrint('✅ FCM: subscribed to topic new_items');
        final String? token = await messaging.getToken();
        if (token != null && token.length > 24) {
          debugPrint('✅ FCM token (truncated): ${token.substring(0, 24)}…');
        } else {
          debugPrint('✅ FCM token: $token');
        }
      }
    } catch (e, st) {
      debugPrint('⚠️ subscribeToTopic(new_items) failed: $e\n$st');
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    // Avoid duplicate permission prompts on iOS; FCM requestPermission runs first.
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload == null || response.payload!.isEmpty) return;
        final payloadMap =
            jsonDecode(response.payload!) as Map<String, dynamic>;
        _navigateToNotificationDetails(
          NewItemNotificationData.fromMap(payloadMap),
        );
      },
    );

    // Create high-importance Android channel (ensures sound + heads-up).
    await localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(highImportanceChannel);

    // Android 13+: runtime POST_NOTIFICATIONS prompt (no-op on older API levels).
    await localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final iosImplementation = localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final data = message.data;
    final parsedData = NewItemNotificationData.fromMap(data);

    final notification = message.notification;
    final title = notification?.title ?? 'New Item Added';
    final body =
        notification?.body ??
        '${parsedData.storeName} added a new product at ${parsedData.itemPrice}';

    final String? imagePath = await _downloadAndSaveFile(
      parsedData.thumbnailUrl,
      'notif_big_picture_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final BigPictureStyleInformation? bigPictureStyle = imagePath == null
        ? null
        : BigPictureStyleInformation(
            FilePathAndroidBitmap(imagePath),
            contentTitle: title,
            summaryText: body,
            largeIcon: FilePathAndroidBitmap(imagePath),
          );

    final androidDetails = AndroidNotificationDetails(
      highImportanceChannel.id,
      highImportanceChannel.name,
      channelDescription: highImportanceChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      // Omit `sound` so the channel uses the system default tone (`res/raw` not required).
      styleInformation: bigPictureStyle,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
      presentBadge: true,
    );

    await localNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode(parsedData.toMap()),
    );
  }

  static void _handleRemoteMessageNavigation(RemoteMessage message) {
    final parsedData = NewItemNotificationData.fromMap(message.data);

    final thumbnailUrl = (message.data['thumbnailUrl'] ?? '').toString().trim();
    final imageUrl = thumbnailUrl.isNotEmpty
        ? thumbnailUrl
        : parsedData.thumbnailUrl;

    debugPrint('🔔 onMessageOpenedApp data: ${message.data}');
    debugPrint('🔔 extracted thumbnailUrl: $thumbnailUrl');
    debugPrint('🔔 final navigation imageUrl: $imageUrl');

    if (imageUrl.isEmpty) {
      debugPrint(
        '❌ Navigation blocked: imageUrl is empty. Check payload key `thumbnailUrl`.',
      );
      return;
    }

    appNavigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ItemDetailsScreen.fromNotificationData(
          imageUrl: imageUrl,
          title: parsedData.itemTitle,
          price: parsedData.itemPrice,
          currency: parsedData.currency,
          brandName: parsedData.brandName,
          sellerPhone: parsedData.ownerPhone,
        ),
      ),
    );
  }

  static Future<String?> _downloadAndSaveFile(
    String url,
    String fileName,
  ) async {
    try {
      if (url.trim().isEmpty) return null;
      final Uri uri = Uri.parse(url);
      final HttpClientResponse response = await HttpClient()
          .getUrl(uri)
          .then((HttpClientRequest request) => request.close());

      if (response.statusCode != 200) return null;

      final bytes = await consolidateHttpClientResponseBytes(response);
      final Directory directory = await getTemporaryDirectory();
      final File file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static void _navigateToNotificationDetails(NewItemNotificationData data) {
    final context = appNavigatorKey.currentState?.context;
    if (context == null) return;

    final imageUrl = data.thumbnailUrl.trim();
    debugPrint('🔔 local notification payload: ${data.toMap()}');
    debugPrint('🔔 local notification imageUrl: $imageUrl');

    if (imageUrl.isEmpty) {
      debugPrint(
        '❌ Local notification navigation blocked: imageUrl empty from payload.',
      );
      return;
    }

    appNavigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ItemDetailsScreen.fromNotificationData(
          imageUrl: imageUrl,
          title: data.itemTitle,
          price: data.itemPrice,
          currency: data.currency,
          brandName: data.brandName,
          sellerPhone: data.ownerPhone,
        ),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch anything that escapes from the framework so a single async failure
  // (e.g., FCM on a no-Play-Services emulator) does not blank the app.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('⚠️ FlutterError: ${details.exceptionAsString()}');
  };

  try {
    sharedPreferences = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('⚠️ SharedPreferences init failed: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Must be registered before runApp (firebase_messaging requirement).
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️ Firebase.initializeApp failed: $e');
  }

  // Render the UI immediately. Notifications init runs in the background so
  // the emulator never gets stuck on a blank screen if Play Services is missing.
  runApp(const MyApp());

  unawaited(
    PushNotificationService.initialize().catchError((Object e) {
      debugPrint('⚠️ PushNotificationService.initialize failed: $e');
    }),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Locale _englishLocale = Locale('en');
  static const Locale _arabicLocale = Locale('ar');

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Sugake',
      onGenerateTitle: (context) => AppTranslations.text(context, 'app_title'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange),
      supportedLocales: const [_englishLocale, _arabicLocale],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale == null) return _englishLocale;

        if (deviceLocale.languageCode == 'ar') return _arabicLocale;
        if (deviceLocale.languageCode == 'en') return _englishLocale;

        return _englishLocale;
      },
      home: const MainWrapper(),
    );
  }
}
