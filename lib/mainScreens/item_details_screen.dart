import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/models/store.dart';
import 'package:url_launcher/url_launcher.dart';

class ItemDetailsScreen extends StatelessWidget {
  final StoreItem item;

  const ItemDetailsScreen({super.key, required this.item});

  Future<void> _openWhatsApp(BuildContext context) async {
    final phone = item.sellerPhone.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller phone is not available.')),
      );
      return;
    }

    final normalizedPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final message = Uri.encodeComponent(
      'Hello, I am interested in your product: ${item.name}',
    );
    final uri = Uri.parse('https://wa.me/$normalizedPhone?text=$message');

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.05;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          item.name.isEmpty ? 'Item Details' : item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: horizontalPadding,
          right: horizontalPadding,
          top: size.height * 0.02,
          bottom: size.height * 0.03,
        ),
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: Hero(
              tag: 'hero_product_${item.itemId}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(size.width * 0.04),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
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
          SizedBox(height: size.height * 0.02),
          Text(
            item.name,
            style: TextStyle(
              fontSize: size.width * 0.055,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: size.height * 0.008),
          Text(
            '${item.currency.isEmpty ? '₪' : item.currency} ${item.itemPrice.isEmpty ? '0' : item.itemPrice}',
            style: TextStyle(
              fontSize: size.width * 0.05,
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: size.height * 0.012),
          Text(
            'Brand: ${item.brandName.isEmpty ? 'N/A' : item.brandName}',
            style: TextStyle(
              fontSize: size.width * 0.038,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          SizedBox(height: size.height * 0.03),
          SizedBox(
            width: double.infinity,
            height: size.height * 0.07,
            child: ElevatedButton.icon(
              onPressed: () => _openWhatsApp(context),
              icon: const Icon(Icons.chat),
              label: Text(
                'Contact on WhatsApp',
                style: TextStyle(
                  fontSize: size.width * 0.042,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(size.width * 0.03),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
