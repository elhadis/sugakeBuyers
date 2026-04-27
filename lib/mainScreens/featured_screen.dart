import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/mainScreens/item_details_screen.dart';
import 'package:sugacke/models/store.dart';
import 'package:sugacke/widgets/product_shimmer_widget.dart';

class FeaturedScreen extends StatelessWidget {
  const FeaturedScreen({super.key});

  Stream<List<StoreItem>> _featuredItemsStream() {
    return FirebaseFirestore.instance
        .collection('items')
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StoreItem.fromJson(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return StreamBuilder<List<StoreItem>>(
      stream: _featuredItemsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ProductShimmerWidget();
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(child: Text('No featured items found'));
        }

        return GridView.builder(
          padding: EdgeInsets.all(size.width * 0.03),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: size.width > 800 ? 4 : (size.width > 600 ? 3 : 2),
            mainAxisSpacing: size.width * 0.03,
            crossAxisSpacing: size.width * 0.03,
            childAspectRatio: 0.66,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final heroTag = 'hero_product_${item.itemId}';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailsScreen(item: item),
                  ),
                );
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(size.width * 0.03),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Hero(
                        tag: heroTag,
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(size.width * 0.03),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: Colors.grey.shade300),
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(size.width * 0.02),
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: size.width * 0.034,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        size.width * 0.02,
                        0,
                        size.width * 0.02,
                        size.width * 0.02,
                      ),
                      child: Text(
                        '${item.currency.isEmpty ? '₪' : item.currency} ${item.itemPrice}',
                        style: TextStyle(
                          fontSize: size.width * 0.032,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
