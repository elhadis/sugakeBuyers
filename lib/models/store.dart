class Store {
  final String uid;
  final String name;
  final String imageUrl;
  final String phone;

  const Store({
    required this.uid,
    required this.name,
    required this.imageUrl,
    required this.phone,
  });

  factory Store.fromJson(Map<String, dynamic> json, {String? docId}) {
    return Store(
      uid: (json['uid'] ?? json['userId'] ?? json['sellerUID'] ?? docId ?? '')
          .toString(),
      name: (json['name'] ?? json['storeName'] ?? json['sellerName'] ?? '')
          .toString(),
      imageUrl:
          (json['imageUrl'] ??
                  json['photoUrl'] ??
                  json['logo'] ??
                  json['thumbnailUrl'] ??
                  '')
              .toString(),
      phone: (json['phone'] ?? json['phoneNumber'] ?? json['mobile'] ?? '')
          .toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'imageUrl': imageUrl,
    'phone': phone,
  };
}

class StoreBrand {
  final String brandId;
  final String storeUid;
  final String name;
  final String imageUrl;

  const StoreBrand({
    required this.brandId,
    required this.storeUid,
    required this.name,
    required this.imageUrl,
  });

  factory StoreBrand.fromJson(Map<String, dynamic> json, {String? docId}) {
    return StoreBrand(
      brandId: (json['brandId'] ?? json['brandID'] ?? docId ?? '').toString(),
      storeUid: (json['storeUid'] ?? json['sellerUID'] ?? '').toString(),
      name: (json['name'] ?? json['brandTitle'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['thumbnailUrl'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'brandId': brandId,
    'storeUid': storeUid,
    'name': name,
    'imageUrl': imageUrl,
  };
}

class StoreItem {
  final String itemId;
  final String brandId;
  final String storeUid;
  final String name;
  final double price;
  final String itemPrice;
  final String imageUrl;
  final String brandName;
  final String itemCategory;
  final String currency;
  final String sellerPhone;

  const StoreItem({
    required this.itemId,
    required this.brandId,
    required this.storeUid,
    required this.name,
    required this.price,
    required this.itemPrice,
    required this.imageUrl,
    required this.brandName,
    required this.itemCategory,
    required this.currency,
    required this.sellerPhone,
  });

  factory StoreItem.fromJson(Map<String, dynamic> json, {String? docId}) {
    final dynamic rawPrice =
        json['itemPrice'] ??
        json['price'] ??
        json['item_price'] ??
        json['item price'] ??
        json['itemPriceText'] ??
        '';

    final String itemPriceText = rawPrice.toString().trim();
    final String normalizedPriceText = itemPriceText.replaceAll(
      RegExp(r'[^0-9.\-]'),
      '',
    );
    final double parsedPrice = double.tryParse(normalizedPriceText) ?? 0.0;

    return StoreItem(
      itemId: (json['itemId'] ?? json['itemID'] ?? docId ?? '').toString(),
      brandId: (json['brandId'] ?? json['brandID'] ?? '').toString(),
      storeUid: (json['storeUid'] ?? json['userId'] ?? json['sellerUID'] ?? '')
          .toString(),
      name: (json['name'] ?? json['itemTitle'] ?? json['item_title'] ?? '')
          .toString(),
      price: parsedPrice,
      itemPrice: itemPriceText.isEmpty ? '0' : itemPriceText,
      imageUrl:
          (json['imageUrl'] ??
                  json['thumbnailUrl'] ??
                  json['itemThumbnailUrl'] ??
                  '')
              .toString(),
      brandName: (json['brandName'] ?? json['storeName'] ?? '').toString(),
      itemCategory: (json['itemCategory'] ?? '').toString(),
      currency: (json['currency'] ?? json['addressCurrency'] ?? '₪').toString(),
      sellerPhone:
          (json['sellerPhone'] ?? json['phone'] ?? json['phoneNumber'] ?? '')
              .toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'itemId': itemId,
    'brandId': brandId,
    'storeUid': storeUid,
    'name': name,
    'itemPrice': itemPrice,
    'imageUrl': imageUrl,
    'brandName': brandName,
    'itemCategory': itemCategory,
    'currency': currency,
    'sellerPhone': sellerPhone,
  };
}
