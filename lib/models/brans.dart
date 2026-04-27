import 'package:cloud_firestore/cloud_firestore.dart';

class Brands {
  String? brandId;
  String? branInfo;
  String? brandTitle;
  Timestamp? publishedDate;
  String? sellerUID;
  String? status;
  String? thumbnailUrl;
  Brands({
    this.brandId,
    this.branInfo,
    this.brandTitle,
    this.publishedDate,
    this.sellerUID,
    this.status,
    this.thumbnailUrl,
  });

  Brands.fromJson(Map<String, dynamic> json) {
    brandId = (json['brandId'] ?? json['brandID'])?.toString();
    branInfo = json['brandInfo'];
    brandTitle = json['brandTitle'];
    publishedDate = json['publishedDate'];
    sellerUID = json['sellerUID'];
    status = json['status'];
    thumbnailUrl = json['thumbnailUrl'];
  }
}
