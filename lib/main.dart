import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sugacke/authScreens/my_auth.dart';
import 'package:sugacke/firebase_options.dart';
import 'package:sugacke/global/global.dart';
import 'package:sugacke/mainScreens/main_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPreferences = await SharedPreferences.getInstance();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const appColor = Color(0xFFFF6F00);

    return MaterialApp(
      title: 'Sugacke',
      theme: ThemeData(primarySwatch: Colors.orange),
      debugShowCheckedModeBanner: false,
      home: const MainWrapper(),
    );
  }
}
