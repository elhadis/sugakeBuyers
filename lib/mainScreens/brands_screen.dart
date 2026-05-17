import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/global/app_ui_tokens.dart';
import 'package:sugacke/l10n/translations.dart';
import 'package:sugacke/mainScreens/item_details_screen.dart';
import 'package:sugacke/models/brans.dart';
import 'package:sugacke/models/store.dart';
import 'package:sugacke/widgets/brand_card_widget.dart';
import 'package:sugacke/widgets/product_shimmer_widget.dart';

class BrandsScreen extends StatefulWidget {
  const BrandsScreen({super.key});

  @override
  State<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends State<BrandsScreen> {
  Future<List<Brands>> _loadAllBrands() async {
    final sellersSnapshot = await FirebaseFirestore.instance
        .collection('sellers')
        .get();

    final List<Brands> brands = [];
    for (final seller in sellersSnapshot.docs) {
      final brandsSnapshot = await seller.reference.collection('brands').get();
      for (final doc in brandsSnapshot.docs) {
        brands.add(Brands.fromJson(doc.data()));
      }
    }
    return brands;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final contentWidth = width > AppUiTokens.maxContentWidth
            ? AppUiTokens.maxContentWidth
            : width;
        final crossAxisCount = contentWidth > 660 ? 3 : 2;
        final spacing = contentWidth < 380 ? 8.0 : 12.0;

        return Center(
          child: SizedBox(
            width: contentWidth,
            child: FutureBuilder<List<Brands>>(
              future: _loadAllBrands(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ProductShimmerWidget();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      AppTranslations.textWithParams(
                        context,
                        'failed_load_brands',
                        {'error': snapshot.error.toString()},
                      ),
                    ),
                  );
                }

                final brands = snapshot.data ?? [];
                if (brands.isEmpty) {
                  return Center(
                    child: Text(AppTranslations.text(context, 'no_brands_found')),
                  );
                }

                return GridView.builder(
                  padding: EdgeInsets.all(spacing),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    final brand = brands[index];
                    return BrandCardWidget(
                      brand: brand,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BrandItemsByBrandScreen(
                              brandId: brand.brandId ?? '',
                              brandTitle: brand.brandTitle ??
                                  AppTranslations.text(context, 'brand_items'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class BrandItemsByBrandScreen extends StatelessWidget {
  final String brandId;
  final String brandTitle;

  const BrandItemsByBrandScreen({
    super.key,
    required this.brandId,
    required this.brandTitle,
  });

  Stream<List<StoreItem>> _itemsByBrandStream() {
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final contentWidth = size.width > AppUiTokens.maxContentWidth
        ? AppUiTokens.maxContentWidth
        : size.width;
    final crossAxisCount = contentWidth > 660 ? 3 : 2;
    final spacing = contentWidth < 380 ? 8.0 : 12.0;

    return Scaffold(
      appBar: AppBar(title: Text(brandTitle)),
      body: Center(
        child: SizedBox(
          width: contentWidth,
          child: StreamBuilder<List<StoreItem>>(
            stream: _itemsByBrandStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const ProductShimmerWidget();
              }

              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    AppTranslations.text(context, 'no_items_for_brand_dot'),
                  ),
                );
              }

              return GridView.builder(
                padding: EdgeInsets.all(spacing),
                itemCount: items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: 0.68,
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
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Hero(
                              tag: heroTag,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(14),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: item.imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: Colors.grey.shade300),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                      ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: contentWidth < 380 ? 12.5 : 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                            child: Text(
                              '${item.currency.isEmpty ? '₪' : item.currency} ${item.itemPrice}',
                              style: TextStyle(
                                fontSize: contentWidth < 380 ? 12 : 13,
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
        ),
      ),
    );
  }
}
