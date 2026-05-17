import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/global/app_ui_tokens.dart';
import 'package:sugacke/l10n/translations.dart';
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
            child: StreamBuilder<List<StoreItem>>(
              stream: _featuredItemsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ProductShimmerWidget();
                }

                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      AppTranslations.text(context, 'no_featured_items_found'),
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
                          borderRadius: BorderRadius.circular(
                            AppUiTokens.cardRadius,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Hero(
                                tag: heroTag,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(
                                      AppUiTokens.cardRadius,
                                    ),
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
        );
      },
    );
  }
}
