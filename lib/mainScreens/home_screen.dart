import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:sugacke/global/country_currency_config.dart';
import 'package:sugacke/global/app_ui_tokens.dart';
import 'package:sugacke/global/global.dart';
import 'package:sugacke/l10n/translations.dart';
import 'package:sugacke/mainScreens/brans_ui_desing_widget.dart';
import 'package:sugacke/mainScreens/upload_brands_screen.dart';
import 'package:sugacke/models/brans.dart';
// import 'package:sugacke/models/items.dart';
import 'package:sugacke/widgets/my_drawer.dart';
import 'package:sugacke/widgets/text_delegat_header_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // late final List<String> _countryNames;
  // late String _selectedCountry;
  // late String _selectedCurrency;

  @override
  void initState() {
    super.initState();
    //   _countryNames = getCountryNamesSorted();
    //   final savedCountry = sharedPreferences?.getString('country');
    //   _selectedCountry =
    //       (savedCountry != null && _countryNames.contains(savedCountry))
    //       ? savedCountry
    //       : (_countryNames.contains('Saudi Arabia')
    //             ? 'Saudi Arabia'
    //             : _countryNames.first);
    //   _selectedCurrency = currencyCodeForCountry(_selectedCountry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orangeAccent, Colors.orange],
              begin: FractionalOffset(0.0, 0.0),
              end: FractionalOffset(1.0, 0.0),
              stops: [0.0, 1.0],
              tileMode: TileMode.clamp,
            ),
          ),
        ),

        title: Text(
          AppTranslations.text(context, 'app_title'),
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const UploadBrandsScreen()),
              );
            },
            icon: const Icon(Icons.add, color: Colors.black, size: 40),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final contentWidth = width > AppUiTokens.maxContentWidth
              ? AppUiTokens.maxContentWidth
              : width;
          final horizontalInset = contentWidth < 380 ? 8.0 : 12.0;

          return Center(
            child: SizedBox(
              width: contentWidth,
              child: CustomScrollView(
                slivers: [
                  // SliverToBoxAdapter(
                  //   child: Padding(
                  //     padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  //     child: DropdownButtonFormField<String>(
                  //       initialValue: _selectedCountry,
                  //       decoration: InputDecoration(
                  //         labelText: "Filter products by country",
                  //         prefixIcon: const Icon(Icons.public),
                  //         border: OutlineInputBorder(
                  //           borderRadius: BorderRadius.circular(12),
                  //         ),
                  //       ),
                  //       items: _countryNames
                  //           .map(
                  //             (country) => DropdownMenuItem<String>(
                  //               value: country,
                  //               child: Text(country),
                  //             ),
                  //           )
                  //           .toList(),
                  //       onChanged: (value) {
                  //         if (value == null) return;
                  //         setState(() {
                  //           _selectedCountry = value;
                  //           _selectedCurrency = currencyCodeForCountry(value);
                  //         });
                  //         sharedPreferences?.setString('country', value);
                  //       },
                  //     ),
                  //   ),
                  // ),
                  // SliverToBoxAdapter(
                  //   child: Padding(
                  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  //     child: Text(
                  //       "Showing products for $_selectedCountry ($_selectedCurrency)",
                  //       style: const TextStyle(fontWeight: FontWeight.w600),
                  //     ),
                  //   ),
                  // ),
                  // SliverPersistentHeader(
                  //   delegate: TextDelegatHeaderWidget(title: "Filtered Products"),
                  //   pinned: true,
                  // ),
                  // StreamBuilder<QuerySnapshot>(
                  //   stream: FirebaseFirestore.instance
                  //       .collection("items")
                  //       .where("currency", isEqualTo: _selectedCurrency)
                  //       .snapshots(),
                  //   builder: (context, snapshot) {
                  //     if (snapshot.connectionState == ConnectionState.waiting) {
                  //       return const SliverToBoxAdapter(
                  //         child: Padding(
                  //           padding: EdgeInsets.all(16),
                  //           child: Center(child: CircularProgressIndicator()),
                  //         ),
                  //       );
                  //     }

                  //     if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  //       return const SliverToBoxAdapter(
                  //         child: Padding(
                  //           padding: EdgeInsets.all(16),
                  //           child: Center(
                  //             child: Text("No products found for selected country."),
                  //           ),
                  //         ),
                  //       );
                  //     }

                  //     return SliverList(
                  //       delegate: SliverChildBuilderDelegate((context, index) {
                  //         final data =
                  //             snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  //         final item = Items.fromJson(data);
                  //         return ListTile(
                  //           leading: const Icon(Icons.inventory_2_outlined),
                  //           title: Text(item.itemTitle ?? 'Unnamed Product'),
                  //           subtitle: Text('Currency: ${item.currency ?? '-'}'),
                  //           trailing: Text(item.itemPrice ?? ''),
                  //         );
                  //       }, childCount: snapshot.data!.docs.length),
                  //     );
                  //   },
                  // ),
                  SliverPersistentHeader(
                    delegate: TextDelegatHeaderWidget(
                      title: AppTranslations.text(context, 'my_brands'),
                    ),
                    pinned: true,
                  ),
                  //write qerry
                  //model
                  //design
                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("sellers")
                        .doc(sharedPreferences!.getString("uid"))
                        .collection("brands")
                        .orderBy("publishedDate", descending: true)
                        .snapshots(),
                    builder: (context, AsyncSnapshot dataSnapshot) {
                      if (dataSnapshot.hasData) {
                        return SliverPadding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalInset,
                            vertical: 6,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              var model = dataSnapshot.data!.docs[index].data();
                              return BransUiDesingWidget(
                                model: Brands.fromJson(model),
                                context: context,
                              );
                            }, childCount: dataSnapshot.data!.docs.length),
                          ),
                        );
                      } else {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Text(
                              AppTranslations.text(
                                context,
                                'no_brands_published',
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
