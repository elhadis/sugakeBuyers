import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sugacke/global/app_ui_tokens.dart';
import 'package:sugacke/l10n/translations.dart';
import 'package:sugacke/models/store.dart';
import 'package:sugacke/services/whatsapp_tracking_service.dart';

class ItemDetailsScreen extends StatelessWidget {
  final StoreItem? item;
  final String? imageUrl;
  final String? title;
  final String? price;
  final String? notificationCurrency;
  final String? notificationBrandName;
  final String? notificationSellerPhone;

  const ItemDetailsScreen({super.key, required StoreItem this.item})
    : imageUrl = null,
      title = null,
      price = null,
      notificationCurrency = null,
      notificationBrandName = null,
      notificationSellerPhone = null;

  const ItemDetailsScreen.fromNotificationData({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required String currency,
    required String brandName,
    required String sellerPhone,
  }) : item = null,
       notificationCurrency = currency,
       notificationBrandName = brandName,
       notificationSellerPhone = sellerPhone;

  bool get _openedFromPushNotification =>
      item == null && (imageUrl ?? '').trim().isNotEmpty;

  Future<void> _openWhatsApp(BuildContext context) async {
    final phone = (item?.sellerPhone ?? notificationSellerPhone ?? '').trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppTranslations.text(context, 'seller_phone_unavailable'),
          ),
        ),
      );
      return;
    }

    await WhatsAppTrackingService.openTrackedChat(
      phoneNumber: phone,
      storeName: (item?.brandName ?? notificationBrandName ?? '').trim(),
      country: WhatsAppTrackingService.resolveCountry(null),
      itemTitle:
          item?.name ?? title ?? AppTranslations.text(context, 'unnamed_item'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 700;
    final contentWidth = isTablet
        ? AppUiTokens.maxCompactContentWidth
        : double.infinity;
    final horizontalPadding = isTablet ? 0.0 : size.width * 0.05;
    final effectiveImageUrl = (item?.imageUrl ?? imageUrl ?? '').trim();
    final itemName = (item?.name ?? this.title ?? '').trim();
    final currency = (item?.currency ?? notificationCurrency ?? '₪').trim();
    final effectivePrice = (item?.itemPrice ?? price ?? '').trim();
    final brand = (item?.brandName ?? notificationBrandName ?? '').trim();
    final title = itemName.isEmpty
        ? AppTranslations.text(context, 'item_details')
        : itemName;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentWidth),
          child: ListView(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              top: size.height * 0.02,
              bottom: size.height * 0.03,
            ),
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AspectRatio(
                    aspectRatio: 1.15,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        isTablet ? 20 : size.width * 0.04,
                      ),
                      child: effectiveImageUrl.isEmpty
                          ? Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            )
                          : Image.network(
                              effectiveImageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  if (_openedFromPushNotification &&
                      effectiveImageUrl.isNotEmpty)
                    Positioned(
                      right: isTablet ? 14 : size.width * 0.03,
                      bottom: isTablet ? 14 : size.height * 0.012,
                      child: FloatingActionButton.small(
                        heroTag: 'item_detail_whatsapp_fab',
                        backgroundColor: AppUiTokens.whatsapp,
                        foregroundColor: Colors.white,
                        onPressed: () => _openWhatsApp(context),
                        child: const FaIcon(
                          FontAwesomeIcons.whatsapp,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: size.height * 0.02),
              Text(
                itemName.isEmpty
                    ? AppTranslations.text(context, 'unnamed_item')
                    : itemName,
                style: TextStyle(
                  fontSize: size.width.clamp(320, 700) * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: size.height * 0.008),
              Text(
                '${currency.isEmpty ? '₪' : currency} ${effectivePrice.isEmpty ? '0' : effectivePrice}',
                style: TextStyle(
                  fontSize: size.width.clamp(320, 700) * 0.044,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: size.height * 0.012),
              Text(
                AppTranslations.textWithParams(context, 'brand_colon', {
                  'brand': brand.isEmpty
                      ? AppTranslations.text(context, 'na')
                      : brand,
                }),
                style: TextStyle(
                  fontSize: size.width.clamp(320, 700) * 0.034,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              SizedBox(height: size.height * 0.03),
              SizedBox(
                width: double.infinity,
                height: isTablet ? 54 : size.height * 0.07,
                child: ElevatedButton.icon(
                  onPressed: () => _openWhatsApp(context),
                  icon: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Colors.white,
                    size: 22,
                  ),
                  label: Text(
                    AppTranslations.text(context, 'contact_whatsapp'),
                    style: TextStyle(
                      fontSize: size.width.clamp(320, 700) * 0.037,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppUiTokens.whatsapp,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        isTablet ? 14 : size.width * 0.03,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
