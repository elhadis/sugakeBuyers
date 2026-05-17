import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/l10n/translations.dart';
import 'package:sugacke/mainScreens/brand_items_screen.dart';
import 'package:sugacke/models/brans.dart';
import 'package:sugacke/models/store.dart';
import 'package:sugacke/widgets/brand_card_widget.dart';

class StoreBrandsScreen extends StatelessWidget {
  final Store store;

  const StoreBrandsScreen({super.key, required this.store});

  Stream<List<Brands>> _storeBrandsStream() {
    return FirebaseFirestore.instance
        .collection('sellers')
        .doc(store.uid)
        .collection('brands')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Brands.fromJson(doc.data())).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: Text('${store.name} ${AppTranslations.text(context, 'brands')}')),
      body: StreamBuilder<List<Brands>>(
        stream: _storeBrandsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final brands = snapshot.data ?? [];
          if (brands.isEmpty) {
            return Center(
              child: Text(AppTranslations.text(context, 'no_brands_for_store')),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.all(size.width * 0.03),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: size.width > 800 ? 4 : (size.width > 600 ? 3 : 2),
              mainAxisSpacing: size.width * 0.03,
              crossAxisSpacing: size.width * 0.03,
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
                      builder: (_) => BrandItemsScreen(
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
    );
  }
}
