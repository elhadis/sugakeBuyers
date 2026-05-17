import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:sugacke/global/app_ui_tokens.dart';
import 'package:sugacke/l10n/translations.dart';
import 'package:sugacke/mainScreens/brands_screen.dart';
import 'package:sugacke/mainScreens/featured_screen.dart';
import 'package:sugacke/mainScreens/my_hmoe_screen.dart';
import 'package:sugacke/mainScreens/store_brands_screen.dart';
import 'package:sugacke/models/store.dart';
import 'package:sugacke/widgets/store_card_widget.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _selectedIndex = 0;

  Stream<List<Store>> _storesStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Store.fromJson(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  Widget _buildStoresTab(String noStoresText) {
    final size = MediaQuery.of(context).size;

    return StreamBuilder<List<Store>>(
      stream: _storesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stores = snapshot.data ?? [];
        if (stores.isEmpty) {
          return Center(child: Text(noStoresText));
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.02,
            vertical: size.height * 0.01,
          ),
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final store = stores[index];
            return StoreCardWidget(
              store: store,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoreBrandsScreen(store: store),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildResponsivePage(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width <= AppUiTokens.maxContentWidth) return child;
        return Center(
          child: SizedBox(width: AppUiTokens.maxContentWidth, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final homeText = AppTranslations.text(context, 'home');
    final brandsText = AppTranslations.text(context, 'categories');
    final storesText = AppTranslations.text(context, 'stores');
    final featuredText = AppTranslations.text(context, 'featured');
    final noProductsFoundText = AppTranslations.text(
      context,
      'no_products_found',
    );

    final tabTitles = [homeText, brandsText, storesText, featuredText];

    final pages = [
      const MyHmoeScreen(),
      const BrandsScreen(),
      _buildStoresTab(noProductsFoundText),
      const FeaturedScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(tabTitles[_selectedIndex]), centerTitle: true),
      body: SafeArea(child: _buildResponsivePage(pages[_selectedIndex])),
      bottomNavigationBar: Container(
        color: AppUiTokens.cardBackground,
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.03,
          vertical: size.height * 0.01,
        ),
        child: GNav(
          selectedIndex: _selectedIndex,
          onTabChange: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          tabBackgroundColor: Colors.orange.shade100,
          color: Colors.grey.shade700,
          activeColor: Colors.orange.shade800,
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.04,
            vertical: size.height * 0.012,
          ),
          gap: size.width * 0.015,
          tabs: [
            GButton(icon: Icons.home_outlined, text: homeText),
            GButton(icon: Icons.category_outlined, text: brandsText),
            GButton(icon: Icons.store_outlined, text: storesText),
            GButton(
              icon: Icons.local_fire_department_outlined,
              text: featuredText,
            ),
          ],
        ),
      ),
    );
  }
}
