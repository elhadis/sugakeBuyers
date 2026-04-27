import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/mainScreens/item_details_screen.dart';
import 'package:sugacke/models/store.dart';

class BrandItemsScreen extends StatelessWidget {
  final String brandId;
  final String brandTitle;

  const BrandItemsScreen({
    super.key,
    required this.brandId,
    required this.brandTitle,
  });

  Stream<List<StoreItem>> _brandItemsStream() {
    return FirebaseFirestore.instance
        .collection('items')
        .where('brandId', isEqualTo: brandId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StoreItem.fromJson(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  Future<StoreItem> _resolveSellerPhone(StoreItem item) async {
    if (item.sellerPhone.trim().isNotEmpty || item.storeUid.trim().isEmpty) {
      return item;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(item.storeUid)
          .get();

      final data = userDoc.data();
      final fallbackPhone = (data?['phone'] ?? '').toString().trim();
      if (fallbackPhone.isEmpty) {
        return item;
      }

      return StoreItem(
        itemId: item.itemId,
        brandId: item.brandId,
        storeUid: item.storeUid,
        name: item.name,
        price: item.price,
        itemPrice: item.itemPrice,
        imageUrl: item.imageUrl,
        brandName: item.brandName,
        itemCategory: item.itemCategory,
        currency: item.currency,
        sellerPhone: fallbackPhone,
      );
    } catch (_) {
      return item;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: Text(brandTitle)),
      body: StreamBuilder<List<StoreItem>>(
        stream: _brandItemsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No items found for this brand'));
          }

          return GridView.builder(
            padding: EdgeInsets.all(size.width * 0.03),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: size.width > 800 ? 4 : (size.width > 600 ? 3 : 2),
              mainAxisSpacing: size.width * 0.03,
              crossAxisSpacing: size.width * 0.03,
              childAspectRatio: 0.66,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final heroTag = 'hero_product_${item.itemId}';

              return GestureDetector(
                onTap: () async {
                  final resolvedItem = await _resolveSellerPhone(item);
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemDetailsScreen(item: resolvedItem),
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
                            child: Image.network(
                              item.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
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
      ),
    );
  }
}
