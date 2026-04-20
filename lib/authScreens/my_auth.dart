import 'package:flutter/material.dart';
import 'package:sugacke/authScreens/login_tab_page.dart';
import 'package:sugacke/authScreens/registration_tab_page.dart';

class MyAuth extends StatefulWidget {
  const MyAuth({super.key});

  @override
  State<MyAuth> createState() => _MyAuthState();
}

class _MyAuthState extends State<MyAuth> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orangeAccent, Colors.orange],
                begin: FractionalOffset(0.0, 0.0),
                end: FractionalOffset(1.0, 0.0),
                stops: [0.0, 1.0],
                tileMode: TileMode.clamp,
              ),
            ),
          ),
          title: const Text(
            'سوقك',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.lock_open_outlined,color: Colors.white,), text: 'تسجيل الدخول'),
              Tab(
                icon: Icon(Icons.app_registration_outlined,color: Colors.white,),
                text: 'إنشاء حساب',
              ),
            ],
          ),
          
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orangeAccent, Colors.orange],
              begin: FractionalOffset(0.0, 0.0),
              end: FractionalOffset(1.0, 0.0),
              stops: [0.0, 1.0],
              tileMode: TileMode.clamp,
            ),
        ),
          child: TabBarView(
            children: [
             LoginTabPage(),
             RegistrationTabPage(),
            ],
      ),
        ),
      ),
    );
  }
}
