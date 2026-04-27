import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/models/brans.dart';

class BrandCardWidget extends StatelessWidget {
  final Brands brand;
  final VoidCallback onTap;

  const BrandCardWidget({super.key, required this.brand, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size.width * 0.04),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size.width * 0.04),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Hero(
                tag: 'brand_${brand.brandId ?? ''}',
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(size.width * 0.04),
                    topRight: Radius.circular(size.width * 0.04),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: brand.thumbnailUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: Colors.grey.shade300),
                      errorWidget: (_, __, ___) =>
                          const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(size.width * 0.025),
              child: Text(
                brand.brandTitle ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: size.width * 0.036,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
