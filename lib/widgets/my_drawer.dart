import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/authScreens/my_auth.dart';
import 'package:sugacke/global/global.dart';
import 'package:sugacke/mainScreens/my_hmoe_screen.dart';
import 'package:sugacke/services/user_session_service.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  String userName = "";
  String userPhotoUrl = "";

  @override
  void initState() {
    super.initState();
    userName = sharedPreferences?.getString("name") ?? "Guest";
    userPhotoUrl = sharedPreferences?.getString("photoUrl") ?? "";

    // Registration writes prefs; login + cold start only set Firebase session unless
    // we load `sellers` / `users` into SharedPreferences (see [UserSessionService]).
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      UserSessionService.loadSellerIntoSharedPreferences(user).then((_) {
        if (!mounted) return;
        setState(() {
          userName = sharedPreferences?.getString("name") ?? "Guest";
          userPhotoUrl = sharedPreferences?.getString("photoUrl") ?? "";
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.black45,
      child: ListView(
        children: [
          // header
          Container(
            padding: const EdgeInsets.only(top: 26, bottom: 12),
            child: Column(
              children: [
                SizedBox(
                  height: 130,
                  width: 130,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white,
                    backgroundImage: userPhotoUrl.isNotEmpty
                        ? NetworkImage(userPhotoUrl)
                        : null,
                    child: userPhotoUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 70,
                            color: Colors.orangeAccent,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          //body
          Container(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              children: [
                const Divider(height: 10, color: Colors.white, thickness: 2),
                ListTile(
                  leading: const Icon(Icons.home, color: Colors.white),
                  title: const Text(
                    "Home",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.reorder, color: Colors.white),
                  title: const Text(
                    "My Orders",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(
                    Icons.picture_in_picture_alt_rounded,
                    color: Colors.white,
                  ),
                  title: const Text(
                    "Not Yet received orders",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.white),
                  title: const Text(
                    "History",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    // MaterialPageRoute(builder: (c) => const MyHmoeScreen());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.backpack, color: Colors.white),
                  title: const Text(
                    "back to items Screen",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const MyHmoeScreen()),
    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    await UserSessionService.clearSellerSession();
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => const MyAuth()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
