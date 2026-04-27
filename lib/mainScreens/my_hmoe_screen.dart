import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sugacke/authScreens/my_auth.dart';
import 'package:sugacke/models/store.dart';
import 'package:sugacke/widgets/featured_slider_widget.dart';
import 'package:sugacke/widgets/product_shimmer_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHmoeScreen extends StatefulWidget {
  const MyHmoeScreen({super.key});

  @override
  State<MyHmoeScreen> createState() => _MyHmoeScreenState();
}

class _MyHmoeScreenState extends State<MyHmoeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasSavedUser = false;
  String? _selectedCategory;
  String? _selectedQuickFilter;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'Men\'s Shoes', 'icon': Icons.directions_run},
    {'name': 'Women & Home World', 'icon': Icons.woman},
    {'name': 'Electronics', 'icon': Icons.smartphone},
    {'name': 'Kids', 'icon': Icons.child_care},
    {'name': 'Supermarket', 'icon': Icons.shopping_cart},
  ];

  final List<String> _quickFilters = const ['New', 'Top Rated'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
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
    return FirebaseFirestore.instance
        .collection('items')
        .snapshots()
        .map(
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
      listenMode: stt.ListenMode.search,
      cancelOnError: true,
      partialResults: true,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search Any products',
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

  Widget _buildQuickFilters() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: _quickFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _quickFilters[index];
          final selected = _selectedQuickFilter == filter;
          return ChoiceChip(
            label: Text(filter),
            selected: selected,
            onSelected: (_) {
              setState(() {
                _selectedQuickFilter = selected ? null : filter;
              });
            },
            selectedColor: Colors.orange.shade200,
            labelStyle: TextStyle(
              color: selected ? Colors.orange.shade900 : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }

  Future<void> _openWhatsApp({
    required String phone,
    required String itemTitle,
  }) async {
    if (phone.trim().isEmpty) return;
    final normalizedPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final message = Uri.encodeComponent(
      "Hello, I'm interested in your product: $itemTitle",
    );
    final uri = Uri.parse('https://wa.me/$normalizedPhone?text=$message');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
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
                        placeholder: (_, __) =>
                            Container(color: Colors.grey.shade200),
                        errorWidget: (_, __, ___) =>
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
                    ),
                    icon: const Icon(Icons.chat),
                    label: const Text(
                      'Order via WhatsApp',
                      style: TextStyle(
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
    if (selected == 'Electronics') return 'Electronics & Mobiles';
    if (selected == 'Kids') return 'Kids & Babies';
    return selected;
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
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final categoryName = category['name'] as String;
              final categoryIcon = category['icon'] as IconData;
              final isSelected = _selectedCategory == categoryName;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = isSelected ? null : categoryName;
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

            final allItems = snapshot.data ?? [];
            final mappedCategory = _mapSelectedCategoryToStoredValue(
              _selectedCategory,
            );

            List<StoreItem> filteredItems = allItems.where((item) {
              final matchesSearch =
                  _searchQuery.isEmpty ||
                  item.name.toLowerCase().contains(_searchQuery);

              final itemCategory = item.itemCategory.trim();
              final matchesCategory =
                  mappedCategory == null || itemCategory == mappedCategory;

              return matchesSearch && matchesCategory;
            }).toList();

            if (_selectedQuickFilter == 'New') {
              filteredItems = filteredItems.reversed.toList();
            }

            if (filteredItems.isEmpty) {
              return const SizedBox(
                height: 220,
                child: Center(child: Text('No products found')),
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
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBodyContent() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 8),
              _buildQuickFilters(),
              SizedBox(
                width: double.infinity,
                child: _buildCategoriesSection(),
              ),
              if (_shouldShowFeaturedSlider)
                StreamBuilder<List<StoreItem>>(
                  stream: _featuredItemsStream(),
                  builder: (context, snapshot) {
                    return FeaturedSliderWidget(
                      featuredItems: snapshot.data ?? [],
                      isLoading:
                          snapshot.connectionState == ConnectionState.waiting,
                      onTapItem: (item) {
                        final store = Store(
                          uid: item.storeUid,
                          name: item.brandName.isEmpty
                              ? 'Store'
                              : item.brandName,
                          imageUrl: item.imageUrl,
                          phone: item.sellerPhone,
                        );
                        _showQuickView(item, store);
                      },
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
                'إنشاء حساب الآن',
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
      backgroundColor: Colors.grey[100],
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
  final VoidCallback onTap;
  final VoidCallback onWhatsAppTap;

  const ProductCard({
    super.key,
    required this.item,
    required this.storeName,
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
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Hero(
                      tag: heroTag,
                      child: CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) =>
                            Container(color: Colors.grey.shade300),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'From ${storeName.isEmpty ? 'Store' : storeName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: Colors.black54),
              ),
              const SizedBox(height: 3),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              _buildRatingRow(),
              const SizedBox(height: 4),
              Text(
                '${item.currency.isEmpty ? '₪' : item.currency} ${item.itemPrice.isEmpty ? '0' : item.itemPrice}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '✓ FREE Delivery',
                      style: TextStyle(fontSize: 10.5, color: Colors.black54),
                    ),
                  ),
                  IconButton(
                    onPressed: onWhatsAppTap,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.chat,
                      color: Color(0xFF25D366),
                      size: 22,
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
