import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sugacke/models/store.dart';
import 'package:sugacke/widgets/product_shimmer_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class FeaturedSliderWidget extends StatelessWidget {
  final List<StoreItem> featuredItems;
  final bool isLoading;
  final void Function(StoreItem item)? onTapItem;

  const FeaturedSliderWidget({
    super.key,
    required this.featuredItems,
    this.isLoading = false,
    this.onTapItem,
  });

  Future<void> _openWhatsApp(StoreItem item) async {
    final phone = item.sellerPhone.trim();
    if (phone.isEmpty) return;

    final normalizedPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final message = Uri.encodeComponent(
      "Hello, I'm interested in your product: ${item.name}",
    );
    final uri = Uri.parse('https://wa.me/$normalizedPhone?text=$message');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _formatPrice(StoreItem item) {
    final cleanedPrice = item.itemPrice.replaceAll(RegExp(r'[^0-9.\-]'), '');
    final parsed = double.tryParse(cleanedPrice);
    if (parsed == null) {
      return '${item.currency.isEmpty ? '₪' : item.currency} ${item.itemPrice.isEmpty ? '0' : item.itemPrice}';
    }
    final formatter = NumberFormat('#,##0.##');
    return '${item.currency.isEmpty ? '₪' : item.currency} ${formatter.format(parsed)}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SliderShimmerWidget();
    }

    if (featuredItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'منتجات متميزة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          CarouselSlider.builder(
            itemCount: featuredItems.length,
            options: CarouselOptions(
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 16 / 9,
              viewportFraction: 0.92,
            ),
            itemBuilder: (context, index, _) {
              final item = featuredItems[index];
              final heroTag = 'hero_featured_${item.itemId}';
              return GestureDetector(
                onTap: () => onTapItem?.call(item),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: heroTag,
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: Colors.grey.shade300),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade300,
                              alignment: Alignment.center,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Color(0xAA000000),
                                  Color(0xDD000000),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _openWhatsApp(item),
                                  icon: const Icon(
                                    Icons.chat,
                                    color: Color(0xFF25D366),
                                  ),
                                ),
                                Text(
                                  _formatPrice(item),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
