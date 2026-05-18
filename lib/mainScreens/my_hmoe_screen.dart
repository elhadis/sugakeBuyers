import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sugacke/authScreens/my_auth.dart';
import 'package:sugacke/global/app_ui_tokens.dart';
import 'package:sugacke/global/country_currency_config.dart';
import 'package:sugacke/global/global.dart';
import 'package:sugacke/l10n/translations.dart';
import 'package:sugacke/models/store.dart';
import 'package:sugacke/services/whatsapp_tracking_service.dart';
import 'package:sugacke/widgets/featured_slider_widget.dart';
import 'package:sugacke/widgets/product_shimmer_widget.dart';

class MyHmoeScreen extends StatefulWidget {
  const MyHmoeScreen({super.key});

  @override
  State<MyHmoeScreen> createState() => _MyHmoeScreenState();
}

class _MyHmoeScreenState extends State<MyHmoeScreen> {
  static const Map<String, String> _countryTranslationKeyByName = {
    'Saudi Arabia': 'country_saudi_arabia',
    'UAE': 'country_uae',
    'Qatar': 'country_qatar',
    'Kuwait': 'country_kuwait',
    'Turkey': 'country_turkey',
    'Egypt': 'country_egypt',
    'Sudan': 'country_sudan',
    'Morocco': 'country_morocco',
    'Kenya': 'country_kenya',
    'Uganda': 'country_uganda',
    'Ethiopia': 'country_ethiopia',
    'Rwanda': 'country_rwanda',
    'UK': 'country_uk',
    'France': 'country_france',
    'Germany': 'country_germany',
    'Netherlands': 'country_netherlands',
    'Italy': 'country_italy',
    'Spain': 'country_spain',
    'USA': 'country_usa',
    'Canada': 'country_canada',
    'India': 'country_india',
  };

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasSavedUser = false;
  int _middleSectionVisibleCount = 2;
  String? _selectedCategory;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  late final List<String> _countryNames;
  String? _selectedCountry;
  late String _selectedCurrency;

  final List<Map<String, dynamic>> _categories = const [
    {'id': 'category_mens_shoes', 'icon': Icons.directions_run},
    {'id': 'category_women_home_world', 'icon': Icons.woman},
    {'id': 'category_electronics', 'icon': Icons.smartphone},
    {'id': 'category_kids', 'icon': Icons.child_care},
    {'id': 'category_supermarket', 'icon': Icons.shopping_cart},
    {'id': 'category_services', 'icon': Icons.miscellaneous_services},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _countryNames = getCountryNamesSorted();
    final savedCountry = sharedPreferences?.getString('country');
    _selectedCountry = null;
    final fallbackCountry =
        (savedCountry != null && _countryNames.contains(savedCountry))
        ? savedCountry
        : (_countryNames.contains('Saudi Arabia')
              ? 'Saudi Arabia'
              : _countryNames.first);
    _selectedCurrency = currencyCodeForCountry(fallbackCountry);
    _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (!mounted) return;
    setState(() {
      _hasSavedUser = uid != null && uid.isNotEmpty;
    });
  }

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

  Stream<List<StoreItem>> _itemsStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'items',
    );

    if (_selectedCountry != null) {
      query = query.where('currency', isEqualTo: _selectedCurrency);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => StoreItem.fromJson(doc.data(), docId: doc.id))
          .toList(),
    );
  }

  Stream<List<StoreItem>> _featuredItemsStream() {
    return FirebaseFirestore.instance
        .collection('items')
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StoreItem.fromJson(doc.data(), docId: doc.id))
              .toList(),
        );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    bool alignRight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 1),
      child: Row(
        mainAxisAlignment: alignRight
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              borderRadius: BorderRadius.circular(AppUiTokens.cardRadius - 5),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            textAlign: alignRight ? TextAlign.right : TextAlign.left,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  bool get _shouldShowFeaturedSlider =>
      _selectedCategory == null || _selectedCategory == 'All';

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _speechToText.stop();
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      return;
    }

    final available = await _speechToText.initialize();
    if (!available) return;

    if (!mounted) return;
    setState(() {
      _isListening = true;
    });

    await _speechToText.listen(
      onResult: (result) {
        final recognized = result.recognizedWords.trim();
        if (!mounted) return;
        setState(() {
          _searchController.text = recognized;
          _searchController.selection = TextSelection.fromPosition(
            TextPosition(offset: _searchController.text.length),
          );
          _searchQuery = recognized.toLowerCase();
        });

        if (result.finalResult) {
          _speechToText.stop();
          if (!mounted) return;
          setState(() {
            _isListening = false;
          });
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.search,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppUiTokens.cardBackground,
        borderRadius: BorderRadius.circular(AppUiTokens.chipRadius + 4),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: AppTranslations.text(context, 'search_products'),
          prefixIcon: const Icon(Icons.search, color: Colors.black54),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _toggleVoiceSearch,
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none_rounded,
                  color: _isListening ? Colors.orange : Colors.black54,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.camera_alt_outlined, color: Colors.black54),
              const SizedBox(width: 8),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsApp({
    required String phone,
    required String itemTitle,
    required String storeName,
  }) async {
    if (phone.trim().isEmpty) return;
    await WhatsAppTrackingService.openTrackedChat(
      phoneNumber: phone,
      storeName: storeName,
      country: WhatsAppTrackingService.resolveCountry(_selectedCountry),
      itemTitle: itemTitle,
    );
  }

  void _showQuickView(StoreItem item, Store? store) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final heroTag = 'hero_product_${item.itemId}';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: Hero(
                      tag: heroTag,
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey.shade200),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.currency.isEmpty ? '₪' : item.currency} ${item.itemPrice.isEmpty ? '0' : item.itemPrice}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  store?.name.isNotEmpty == true ? store!.name : 'Store',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _openWhatsApp(
                      phone: item.sellerPhone.isEmpty
                          ? (store?.phone ?? '')
                          : item.sellerPhone,
                      itemTitle: item.name,
                      storeName: (store?.name ?? item.brandName).trim(),
                    ),
                    icon: const Icon(Icons.chat),
                    label: Text(
                      AppTranslations.text(context, 'order_via_whatsapp'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _mapSelectedCategoryToStoredValue(String? selected) {
    if (selected == null) return null;
    switch (selected) {
      case 'category_mens_shoes':
        return 'Men\'s Shoes';
      case 'category_women_home_world':
        return 'Women & Home World';
      case 'category_electronics':
        return 'Electronics & Mobiles';
      case 'category_kids':
        return 'Kids & Babies';
      case 'category_supermarket':
        return 'Supermarket';
      case 'category_services':
        return 'Services';
      default:
        return null;
    }
  }

  Widget _buildCategoriesSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final itemWidth = ((width - 40) / 4).clamp(78.0, 110.0);

        return SizedBox(
          height: 112,
          width: width <= 0 ? double.infinity : width,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final categoryId = category['id'] as String;
              final categoryName = AppTranslations.text(context, categoryId);
              final categoryIcon = category['icon'] as IconData;
              final isSelected = _selectedCategory == categoryId;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = isSelected ? null : categoryId;
                  });
                },
                child: SizedBox(
                  width: itemWidth,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: itemWidth < 90 ? 26 : 31,
                        backgroundColor: isSelected
                            ? Colors.orange.shade200
                            : Colors.white,
                        child: Icon(
                          categoryIcon,
                          color: Colors.orangeAccent,
                          size: itemWidth < 90 ? 24 : 30,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: itemWidth < 90 ? 10 : 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.orange : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildItemsGrid() {
    return StreamBuilder<List<Store>>(
      stream: _storesStream(),
      builder: (context, storesSnapshot) {
        final stores = storesSnapshot.data ?? [];
        final storesByUid = <String, Store>{for (final s in stores) s.uid: s};

        return StreamBuilder<List<StoreItem>>(
          stream: _itemsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 320, child: ProductShimmerWidget());
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 220,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Unable to load data right now. Please check internet connection and try again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ),
              );
            }

            final allItems = snapshot.data ?? [];
            final mappedCategory = _mapSelectedCategoryToStoredValue(
              _selectedCategory,
            );

            final bool servicesSelected = mappedCategory == 'Services';

            List<StoreItem> filteredItems = allItems.where((item) {
              final itemCategory = item.itemCategory.trim();

              if (itemCategory == 'Services' && !servicesSelected) {
                return false;
              }

              final matchesSearch =
                  _searchQuery.isEmpty ||
                  item.name.toLowerCase().contains(_searchQuery);

              final matchesCategory =
                  mappedCategory == null || itemCategory == mappedCategory;

              return matchesSearch && matchesCategory;
            }).toList();

            if (filteredItems.isEmpty) {
              final emptyMessage = servicesSelected
                  ? 'No services available right now.'
                  : AppTranslations.text(context, 'no_products_found');

              return SizedBox(
                height: 220,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(emptyMessage, textAlign: TextAlign.center),
                  ),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.60,
              ),
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final store = storesByUid[item.storeUid];
                return ProductCard(
                  item: item,
                  storeName: store?.name ?? item.brandName,
                  onTap: () => _showQuickView(item, store),
                  onWhatsAppTap: () => _openWhatsApp(
                    phone: item.sellerPhone.isEmpty
                        ? (store?.phone ?? '')
                        : item.sellerPhone,
                    itemTitle: item.name,
                    storeName: (store?.name ?? item.brandName).trim(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMiddleItemsSection() {
    return StreamBuilder<List<Store>>(
      stream: _storesStream(),
      builder: (context, storesSnapshot) {
        final stores = storesSnapshot.data ?? [];
        final storesByUid = <String, Store>{for (final s in stores) s.uid: s};

        return StreamBuilder<List<StoreItem>>(
          stream: _itemsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 220, child: ProductShimmerWidget());
            }

            final allItems = snapshot.data ?? [];
            final middleItems = allItems
                .where(
                  (item) =>
                      item.itemCategory.trim().toLowerCase() != 'services',
                )
                .toList();

            if (middleItems.isEmpty) {
              return const SizedBox.shrink();
            }

            final visibleCount = _middleSectionVisibleCount > middleItems.length
                ? middleItems.length
                : _middleSectionVisibleCount;
            final displayedItems = middleItems.take(visibleCount).toList();
            final hasMore = visibleCount < middleItems.length;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayedItems.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 6,
                          crossAxisSpacing: 6,
                          childAspectRatio: 0.78,
                        ),
                    itemBuilder: (context, index) {
                      final item = displayedItems[index];
                      final store = storesByUid[item.storeUid];
                      return ProductCard(
                        item: item,
                        storeName: store?.name ?? item.brandName,
                        compact: true,
                        onTap: () => _showQuickView(item, store),
                        onWhatsAppTap: () => _openWhatsApp(
                          phone: item.sellerPhone.isEmpty
                              ? (store?.phone ?? '')
                              : item.sellerPhone,
                          itemTitle: item.name,
                          storeName: (store?.name ?? item.brandName).trim(),
                        ),
                      );
                    },
                  ),
                  if (middleItems.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            if (hasMore) {
                              _middleSectionVisibleCount += 2;
                            } else {
                              _middleSectionVisibleCount = 2;
                            }
                          });
                        },
                        child: Text(
                          hasMore ? 'Show more' : 'Show less',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCountryFilterSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppUiTokens.pageHorizontalPadding - 2,
        8,
        AppUiTokens.pageHorizontalPadding - 2,
        6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedCountry,
            decoration: InputDecoration(
              labelText: AppTranslations.text(context, 'select_country'),
              hintText: AppTranslations.text(context, 'select_country'),
              prefixIcon: const Icon(Icons.public),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: _countryNames.map((country) {
              final translationKey = _countryTranslationKeyByName[country];
              final localizedCountry = translationKey == null
                  ? country
                  : AppTranslations.text(context, translationKey);

              return DropdownMenuItem<String>(
                value: country,
                child: Text(localizedCountry),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedCountry = value;
                _selectedCurrency = currencyCodeForCountry(value);
              });
              sharedPreferences?.setString('country', value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    return Column(
      children: [
        _buildCountryFilterSection(),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _buildCategoriesSection(),
              ),
              if (_shouldShowFeaturedSlider)
                StreamBuilder<List<StoreItem>>(
                  stream: _featuredItemsStream(),
                  builder: (context, snapshot) {
                    final featured = (snapshot.data ?? [])
                        .where((item) => item.itemCategory.trim() != 'Services')
                        .toList();
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const FeaturedSliderWidget(
                        featuredItems: [],
                        isLoading: true,
                        currentCountry: 'Global',
                      );
                    }

                    if (featured.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        _buildSectionHeader(
                          title: AppTranslations.text(context, 'featured'),
                          icon: Icons.local_fire_department_outlined,
                          color: Colors.deepOrange,
                        ),
                        StreamBuilder<List<Store>>(
                          stream: _storesStream(),
                          builder: (context, storesSnapshot) {
                            final storesByUid = {
                              for (final s in (storesSnapshot.data ?? []))
                                s.uid: s,
                            };
                            return FeaturedSliderWidget(
                              title: AppTranslations.text(context, 'featured'),
                              showTitle: false,
                              featuredItems: featured,
                              currentCountry:
                                  WhatsAppTrackingService.resolveCountry(
                                    _selectedCountry,
                                  ),
                              resolveWhatsAppPhone: (item) {
                                final store = storesByUid[item.storeUid];
                                return item.sellerPhone.isEmpty
                                    ? (store?.phone ?? '')
                                    : item.sellerPhone;
                              },
                              onTapItem: (item) {
                                final store = storesByUid[item.storeUid];
                                _showQuickView(item, store);
                              },
                            );
                          },
                        ),
                        _buildMiddleItemsSection(),
                      ],
                    );
                  },
                ),
              if (_shouldShowFeaturedSlider)
                StreamBuilder<List<StoreItem>>(
                  stream: _featuredItemsStream(),
                  builder: (context, snapshot) {
                    final servicesItems = (snapshot.data ?? [])
                        .where(
                          (item) =>
                              item.itemCategory.trim().toLowerCase() ==
                              'services',
                        )
                        .toList();

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    if (servicesItems.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      children: [
                        _buildSectionHeader(
                          title: AppTranslations.text(
                            context,
                            'category_services',
                          ),
                          icon: Icons.miscellaneous_services,
                          color: const Color(0xFF3D8CFF),
                          alignRight: true,
                        ),
                        StreamBuilder<List<Store>>(
                          stream: _storesStream(),
                          builder: (context, storesSnapshot) {
                            final storesByUid = {
                              for (final s in (storesSnapshot.data ?? []))
                                s.uid: s,
                            };
                            return FeaturedSliderWidget(
                              title: AppTranslations.text(
                                context,
                                'category_services',
                              ),
                              showTitle: false,
                              showPrice: false,
                              showStoreName: false,
                              featuredItems: servicesItems,
                              currentCountry:
                                  WhatsAppTrackingService.resolveCountry(
                                    _selectedCountry,
                                  ),
                              resolveWhatsAppPhone: (item) {
                                final store = storesByUid[item.storeUid];
                                return item.sellerPhone.isEmpty
                                    ? (store?.phone ?? '')
                                    : item.sellerPhone;
                              },
                              onTapItem: (item) {
                                final store = storesByUid[item.storeUid];
                                _showQuickView(item, store);
                              },
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              _buildItemsGrid(),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 14, bottom: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyAuth()),
                );
              },
              child: Text(
                AppTranslations.text(context, 'create_account_now'),
                style: TextStyle(
                  color: _hasSavedUser ? Colors.grey : Colors.blue,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppUiTokens.pageBackground,
      appBar: AppBar(
        backgroundColor: const Color(0xFFBEEAE7),
        elevation: 0,
        titleSpacing: 10,
        title: _buildSearchBar(),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final safeWidth = constraints.maxWidth > 0
              ? constraints.maxWidth
              : MediaQuery.of(context).size.width;

          return SizedBox(
            width: safeWidth <= 0 ? double.infinity : safeWidth,
            child: _buildBodyContent(),
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final StoreItem item;
  final String storeName;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback onWhatsAppTap;

  const ProductCard({
    super.key,
    required this.item,
    required this.storeName,
    this.compact = false,
    required this.onTap,
    required this.onWhatsAppTap,
  });

  Widget _buildRatingRow() {
    return Row(
      children: [
        ...List.generate(
          5,
          (index) => Icon(
            index < 4 ? Icons.star : Icons.star_border,
            color: Colors.amber.shade700,
            size: 14,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '(123)',
          style: TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = 'hero_product_${item.itemId}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(compact ? 7 : 8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 6 : 8,
            compact ? 6 : 8,
            compact ? 6 : 8,
            compact ? 8 : 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: compact ? 5 : 6,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(compact ? 6 : 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(compact ? 5 : 6),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Hero(
                      tag: heroTag,
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            Container(color: Colors.grey.shade300),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 6 : 8),
              Text(
                AppTranslations.textWithParams(context, 'from_store', {
                  'store': storeName.isEmpty
                      ? AppTranslations.text(context, 'store')
                      : storeName,
                }),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 9 : 10.5,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: compact ? 2 : 3),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: compact ? 3 : 4),
              _buildRatingRow(),
              SizedBox(height: compact ? 3 : 4),
              Text(
                '${item.currency.isEmpty ? '₪' : item.currency} ${item.itemPrice.isEmpty ? '0' : item.itemPrice}',
                style: TextStyle(
                  fontSize: compact ? 14.5 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: compact ? 1 : 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppTranslations.text(context, 'quality_high'),
                      style: TextStyle(
                        fontSize: compact ? 9 : 10.5,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onWhatsAppTap,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.chat,
                      color: Color(0xFF25D366),
                      size: compact ? 18 : 22,
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
