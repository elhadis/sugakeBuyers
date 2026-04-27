import 'package:flutter/material.dart';
import 'package:sugacke/itemsScreens/upload_items_screen.dart';
import 'package:sugacke/models/brans.dart';
import 'package:sugacke/widgets/text_delegat_header_widget.dart';

class ItemsScreen extends StatefulWidget {
  final Brands? model;

  const ItemsScreen({super.key, this.model}); // Added super.key for best practice

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                MaterialPageRoute(
                  builder: (c) => UploadItemsScreen(
                    // FIXED: Use widget.model and removed the semi-colon error
                    model: widget.model, 
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add_box_rounded, color: Colors.black, size: 40),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: TextDelegatHeaderWidget(
              // FIXED: Added null safety check for brandTitle
              title: "My ${widget.model?.brandTitle ?? 'Items'}",
            ),
          ),
        ],
      ),
    );
  }
}