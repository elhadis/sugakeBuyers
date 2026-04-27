import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/models/store.dart';

class StoreCardWidget extends StatelessWidget {
  final Store store;
  final VoidCallback onTap;

  const StoreCardWidget({super.key, required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardHeight = size.height * 0.13;
    final imageSize = size.width * 0.16;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size.width * 0.04),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: size.width * 0.03,
          vertical: size.height * 0.007,
        ),
        padding: EdgeInsets.all(size.width * 0.03),
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
        constraints: BoxConstraints(minHeight: cardHeight),
        child: Row(
          children: [
            Hero(
              tag: 'store_${store.uid}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(size.width * 0.03),
                child: SizedBox(
                  width: imageSize,
                  height: imageSize,
                  child: CachedNetworkImage(
                    imageUrl: store.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Container(color: Colors.grey.shade300),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.storefront, color: Colors.grey),
                  ),
                ),
              ),
            ),
            SizedBox(width: size.width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: size.width * 0.042,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: size.height * 0.006),
                  Text(
                    store.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: size.width * 0.033,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: size.width * 0.07),
          ],
        ),
      ),
    );
  }
}
