import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/l10n/translations.dart';
import 'package:sugacke/models/store.dart';

class StoreDetailsScreen extends StatefulWidget {
  final Store store;

  const StoreDetailsScreen({super.key, required this.store});

  @override
  State<StoreDetailsScreen> createState() => _StoreDetailsScreenState();
}

class _StoreDetailsScreenState extends State<StoreDetailsScreen> {
  String? selectedBrandId;

  Stream<List<StoreBrand>> _brandsStream() {
    return FirebaseFirestore.instance
        .collection('sellers')
        .doc(widget.store.uid)
        .collection('brands')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StoreBrand.fromJson(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  Stream<List<StoreItem>> _itemsStream() {
    final brandsRef = FirebaseFirestore.instance
        .collection('sellers')
        .doc(widget.store.uid)
        .collection('brands');

    return brandsRef.snapshots().asyncMap((brandsSnapshot) async {
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> brandDocs =
          brandsSnapshot.docs;

      final Iterable<QueryDocumentSnapshot<Map<String, dynamic>>>
      filteredBrands = (selectedBrandId == null || selectedBrandId!.isEmpty)
          ? brandDocs
          : brandDocs.where((b) => b.id == selectedBrandId);

      final List<StoreItem> allItems = [];

      for (final brandDoc in filteredBrands) {
        final brandData = brandDoc.data();
        final String brandName =
            (brandData['brandTitle'] ?? brandData['name'] ?? '').toString();
        final String brandId =
            (brandData['brandId'] ?? brandData['brandID'] ?? brandDoc.id)
                .toString();

        final itemsSnapshot = await brandDoc.reference
            .collection('items')
            .get();

        for (final itemDoc in itemsSnapshot.docs) {
          final item = StoreItem.fromJson(itemDoc.data(), docId: itemDoc.id);
          allItems.add(
            StoreItem(
              itemId: item.itemId,
              brandId: item.brandId.isEmpty ? brandId : item.brandId,
              storeUid: item.storeUid.isEmpty
                  ? widget.store.uid
                  : item.storeUid,
              name: item.name,
              price: item.price,
              itemPrice: item.itemPrice,
              imageUrl: item.imageUrl,
              brandName: item.brandName.isEmpty ? brandName : item.brandName,
              itemCategory: item.itemCategory,
              currency: item.currency,
              sellerPhone: item.sellerPhone.isEmpty
                  ? widget.store.phone
                  : item.sellerPhone,
            ),
          );
        }
      }

      return allItems;
    });
  }

  Widget _brandChip(StoreBrand brand) {
    final bool selected = selectedBrandId == brand.brandId;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedBrandId = selected ? null : brand.brandId;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.orange : Colors.white,
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: brand.imageUrl,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const Icon(Icons.store, size: 18),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              brand.name,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(StoreItem item) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const ColoredBox(
                    color: Colors.black12,
                    child: Center(child: Icon(Icons.image_not_supported)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${item.currency.isEmpty ? '₪' : item.currency} ${item.itemPrice}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.brandName.isEmpty
                    ? AppTranslations.text(context, 'brands')
                    : item.brandName,
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.store.name),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 80,
            child: StreamBuilder<List<StoreBrand>>(
              stream: _brandsStream(),
              builder: (context, snapshot) {
                final brands = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (brands.isEmpty) {
                  return Center(
                    child: Text(
                      AppTranslations.text(context, 'no_brands_for_store'),
                    ),
                  );
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: brands.length,
                  itemBuilder: (context, index) => _brandChip(brands[index]),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<StoreItem>>(
              stream: _itemsStream(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (items.isEmpty) {
                  return Center(
                    child: Text(AppTranslations.text(context, 'no_items_found')),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => _itemCard(items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
