import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/itemsScreens/items_details_screen.dart';
import 'package:sugacke/itemsScreens/items_screen.dart';
import 'package:sugacke/l10n/translations.dart';
import 'package:sugacke/models/items.dart';

class ItemsUiDesignWidget extends StatelessWidget {
  final Items? model;
  final BuildContext? context;
  final Future<void> Function()? onDeleteConfirmed;

  const ItemsUiDesignWidget({
    super.key,
    this.model,
    this.context,
    this.onDeleteConfirmed,
  });

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppTranslations.text(context, 'delete_brand')),
          content: Text(AppTranslations.text(context, 'delete_brand_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(AppTranslations.text(context, 'cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(AppTranslations.text(context, 'delete')),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true && onDeleteConfirmed != null) {
      await onDeleteConfirmed!.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = model?.thumbnailUrl?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => ItemsDetailsScreen(
            model:model
          )),

        );
      },
      child: Card(
        elevation: 10,
        shadowColor: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                model?.itemTitle?.toString() ??
                    AppTranslations.text(context, 'untitled_item'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 2),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (_, __, ___) => const ColoredBox(
                      color: Colors.black12,
                      child: Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                model?.itemDesc?.toString() ??
                    AppTranslations.text(context, 'untitled_item'),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [

              //     IconButton(
              //       onPressed: () => _showDeleteConfirmationDialog(context),
              //       icon: const Icon(
              //         Icons.delete_sweep,
              //         color: Colors.pinkAccent,
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
