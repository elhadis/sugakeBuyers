import 'package:flutter/material.dart';
import 'package:sugacke/widgets/my_drawer.dart';

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
          decoration:const BoxDecoration(
          gradient: LinearGradient(colors: [
            Colors.orangeAccent,
            Colors.orange
          ], begin: FractionalOffset(0.0,0.0)
          ,end: FractionalOffset(1.0,0.0),
          stops: [0.0,1.0],tileMode: TileMode.clamp))
          ),

        title: const Text('سوقك',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold        ),
        ),
        centerTitle: true,
      ),
    );
  }
}