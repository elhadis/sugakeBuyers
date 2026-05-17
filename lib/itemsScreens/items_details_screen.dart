import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sugacke/global/global.dart';
import 'package:sugacke/l10n/translations.dart';
import 'package:sugacke/mainScreens/home_screen.dart';
import 'package:sugacke/models/items.dart';

class ItemsDetailsScreen extends StatefulWidget {
  final Items? model;
  const ItemsDetailsScreen({super.key, this.model});

  @override
  State<ItemsDetailsScreen> createState() => _ItemsDetailsScreenState();
}

class _ItemsDetailsScreenState extends State<ItemsDetailsScreen> {
  deleteItem() {
    FirebaseFirestore.instance
        .collection("sellers")
        .doc(sharedPreferences!.getString("uid"))
        .collection("brands")
        .doc(widget.model!.brandId)
        .collection("items")
        .doc(widget.model!.itemId)
        .delete()
        .then((value) {
          FirebaseFirestore.instance
              .collection("items")
              .doc(widget.model!.itemId)
              .delete();

          Fluttertoast.showToast(
            msg: AppTranslations.text(context, 'item_deleted'),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => HomeScreen()),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 700;
    final contentWidth = isTablet ? 620.0 : double.infinity;

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
        title: Text(widget.model!.itemTitle.toString()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          deleteItem();
        },
        label: Text(AppTranslations.text(context, 'delete_this_item')),
        icon: Icon(Icons.delete_sweep_outlined),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentWidth),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 0 : 12,
              vertical: 10,
            ),
            children: [
              AspectRatio(
                aspectRatio: 1.15,
                child: Hero(
                  tag: 'hero_product_${widget.model!.itemId.toString()}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isTablet ? 18 : 12),
                    child: CachedNetworkImage(
                      imageUrl: widget.model!.thumbnailUrl.toString(),
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade200),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "${widget.model!.itemTitle}:",
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                  fontSize: size.width.clamp(320, 700) * 0.05,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.model!.itemDesc.toString(),
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: size.width.clamp(320, 700) * 0.032,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "${widget.model!.itemPrice}${widget.model!.currency}",
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                  fontSize: size.width.clamp(320, 700) * 0.047,
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, thickness: 2, color: Colors.pinkAccent),
            ],
          ),
        ),
      ),
    );
  }
}
