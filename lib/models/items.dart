import 'package:cloud_firestore/cloud_firestore.dart';

class Items {
  String? brandId;
  String? itemId;
  String? currency;
  String? isFeatured;
  String? itemCategory;
  String? itemDesc;
  String? itemPrice;
  String? itemTitle;
  Timestamp? publishedDate;
  String? sellerName;
  String? sellerPhone;
  String? sellerUID;
  String? status;
  String? thumbnailUrl;

  Items({
    this.brandId,
    this.currency,
    this.isFeatured,
    this.itemCategory,
    this.itemPrice,
    this.itemTitle,
    this.sellerName,
    this.itemDesc,
    this.publishedDate,
    this.status,
    this.itemId,
    this.sellerPhone,
    this.sellerUID,
    this.thumbnailUrl,
  });
  Items.fromJson(Map<String, dynamic> json) {
    brandId = (json["brandId"] ?? json["barndId"])?.toString();
    currency = json["currency"]?.toString();
    isFeatured = json["isFeatured"]?.toString();
    itemCategory = json["itemCategory"]?.toString();
    itemPrice = json["itemPrice"]?.toString();
    itemTitle = (json["itemTitle"] ?? json["temTitle"])?.toString();
    sellerName = json["sellerName"]?.toString();
    itemDesc = json["itemDesc"]?.toString();
    publishedDate = json["publishedDate"] is Timestamp
        ? json["publishedDate"] as Timestamp
        : null;
    status = json["status"]?.toString();
    itemId = json["itemId"]?.toString();
    sellerPhone = json["sellerPhone"]?.toString();
    sellerUID = json["sellerUID"]?.toString();
    thumbnailUrl = json["thumbnailUrl"]?.toString();
  }
}
