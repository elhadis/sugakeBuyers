import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/global/global.dart';
import 'package:sugacke/itemsScreens/items_screen.dart';
import 'package:sugacke/l10n/translations.dart';
import 'package:sugacke/models/brans.dart';

class BransUiDesingWidget extends StatelessWidget {
  final Brands? model;
  final BuildContext? context;
  final Future<void> Function()? onDeleteConfirmed;

  const BransUiDesingWidget({
    super.key,
    this.model,
    this.context,
    this.onDeleteConfirmed,
  });

  Future<void> deleteBrand() async {
    final String? uid = sharedPreferences?.getString("uid");
    final String? brandId = model?.brandId?.toString();
    final String? imageUrl = model?.thumbnailUrl?.toString();

    if (uid == null || uid.isEmpty || brandId == null || brandId.isEmpty) {
      throw Exception("Missing uid or brandId. Cannot delete brand.");
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      } catch (_) {
        // Ignore storage delete failure so Firestore delete still proceeds.
      }
    }

    await FirebaseFirestore.instance
        .collection("sellers")
        .doc(uid)
        .collection("brands")
        .doc(brandId)
        .delete();
  }

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

    if (shouldDelete == true) {
      try {
        await deleteBrand();
        if (onDeleteConfirmed != null) {
          await onDeleteConfirmed!.call();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(
              content: Text(
                AppTranslations.textWithParams(
                  context,
                  'failed_delete_brand',
                  {'error': e.toString()},
                ),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = model?.thumbnailUrl?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => ItemsScreen(model: model)),
        );
      },
      child: Card(
        elevation: 10,
        shadowColor: Colors.black,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      model?.brandTitle?.toString() ??
                          AppTranslations.text(context, 'untitled_brand'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showDeleteConfirmationDialog(context),
                    icon: const Icon(
                      Icons.delete_sweep,
                      color: Colors.pinkAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
