import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/global/global.dart';
import 'package:sugacke/itemsScreens/items_ui_design_widget.dart';
import 'package:sugacke/itemsScreens/upload_items_screen.dart';
import 'package:sugacke/l10n/translations.dart';
import 'package:sugacke/models/brans.dart';
import 'package:sugacke/models/items.dart';
import 'package:sugacke/widgets/text_delegat_header_widget.dart';

class ItemsScreen extends StatefulWidget {
  final Brands? model;

  const ItemsScreen({
    super.key,
    this.model,
  }); // Added super.key for best practice

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
        title: Text(
          AppTranslations.text(context, 'app_title'),
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
            icon: const Icon(
              Icons.add_box_rounded,
              color: Colors.black,
              size: 40,
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: TextDelegatHeaderWidget(
              // FIXED: Added null safety check for brandTitle
              title:
                  "${AppTranslations.text(context, 'my_items')} ${widget.model?.brandTitle ?? AppTranslations.text(context, 'brand_items')}",
            ),
          ),

          Builder(
            builder: (context) {
              final String? uid = sharedPreferences?.getString("uid");
              final String? brandId = widget.model?.brandId;

              if (uid == null ||
                  uid.isEmpty ||
                  brandId == null ||
                  brandId.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        AppTranslations.text(context, 'missing_seller_or_brand'),
                      ),
                    ),
                  ),
                );
              }

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection("sellers")
                    .doc(uid)
                    .collection("brands")
                    .doc(brandId)
                    .collection("items")
                    .orderBy("publishedDate", descending: true)
                    .snapshots(),
                builder: (context, dataSnapshot) {
                  if (dataSnapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            AppTranslations.text(context, 'failed_load_items'),
                          ),
                        ),
                      ),
                    );
                  }

                  if (!dataSnapshot.hasData) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final docs = dataSnapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            AppTranslations.text(context, 'no_items_published'),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final model = docs[index].data();
                      return ItemsUiDesignWidget(
                        model: Items.fromJson(model),
                        context: context,
                      );
                    }, childCount: docs.length),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
