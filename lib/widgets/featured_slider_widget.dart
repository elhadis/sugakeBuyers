import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sugacke/global/app_ui_tokens.dart';
import 'package:sugacke/models/store.dart';
import 'package:sugacke/services/whatsapp_tracking_service.dart';
import 'package:sugacke/widgets/product_shimmer_widget.dart';

class FeaturedSliderWidget extends StatelessWidget {
  final List<StoreItem> featuredItems;
  final bool isLoading;
  final void Function(StoreItem item)? onTapItem;
  final String currentCountry;
  final String title;
  final bool showTitle;
  final String Function(StoreItem item)? resolveWhatsAppPhone;
  final bool showPrice;
  final bool showStoreName;

  const FeaturedSliderWidget({
    super.key,
    required this.featuredItems,
    this.isLoading = false,
    this.onTapItem,
    required this.currentCountry,
    this.title = 'Featured',
    this.showTitle = true,
    this.resolveWhatsAppPhone,
    this.showPrice = true,
    this.showStoreName = true,
  });

  Future<void> _openWhatsApp(StoreItem item) async {
    final phone = (resolveWhatsAppPhone?.call(item) ?? item.sellerPhone).trim();
    if (phone.isEmpty) return;

    final normalizedPhone = phone.replaceAll(RegExp(r'\s+'), '');
    await WhatsAppTrackingService.openTrackedChat(
      phoneNumber: normalizedPhone,
      storeName: item.brandName,
      country: currentCountry,
      itemTitle: item.name,
    );
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
      padding: const EdgeInsets.fromLTRB(
        AppUiTokens.pageHorizontalPadding,
        4,
        AppUiTokens.pageHorizontalPadding,
        10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
          ],
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
                    borderRadius: BorderRadius.circular(AppUiTokens.cardRadius),
                    boxShadow: AppUiTokens.softCardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppUiTokens.cardRadius),
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (showStoreName) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.brandName.trim().isEmpty
                                              ? 'Store'
                                              : item.brandName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xFFE4E4E4),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _openWhatsApp(item),
                                  tooltip: 'WhatsApp',
                                  icon: const Icon(
                                    Icons.chat,
                                    color: AppUiTokens.whatsapp,
                                  ),
                                ),
                                if (showPrice)
                                  Flexible(
                                    child: Text(
                                      _formatPrice(item),
                                      maxLines: 1,
                                      textAlign: TextAlign.end,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
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
