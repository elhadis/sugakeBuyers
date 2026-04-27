import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/global/global.dart';
import 'package:sugacke/mainScreens/brans_ui_desing_widget.dart';
import 'package:sugacke/mainScreens/upload_brands_screen.dart';
import 'package:sugacke/models/brans.dart';
import 'package:sugacke/widgets/my_drawer.dart';
import 'package:sugacke/widgets/text_delegat_header_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
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
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const UploadBrandsScreen()),
              );
            },
            icon: const Icon(Icons.add, color: Colors.black, size: 40),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            delegate: TextDelegatHeaderWidget(title: "My Brands"),
            pinned: true,
          ),
          //write qerry
          //model
          //design
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection("sellers")
                .doc(sharedPreferences!.getString("uid"))
                .collection("brands").orderBy("publishedDate" , descending: true)
                
                .snapshots(),
            builder: (context,AsyncSnapshot dataSnapshot) {
              if (dataSnapshot.hasData) {
                // Handle data
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      var model = dataSnapshot.data!.docs[index].data();
                      return BransUiDesingWidget(model: Brands.fromJson(model), context: context,);
                    },
                    childCount: dataSnapshot.data!.docs.length,
                  ),
                );
              } else {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Text("No Brands has been published."),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
