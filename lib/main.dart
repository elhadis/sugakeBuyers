import 'package:flutter/material.dart';
import 'package:sugacke/authScreens/auth_screen.dart';
import 'package:sugacke/mainScreens/home_screen.dart';
import 'package:sugacke/splashScreen/my_splash_screen.dart';

void main() {
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
      home: MySplashScreen(),
    );
  }
}
