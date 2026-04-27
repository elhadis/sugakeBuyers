import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as fStorage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sugacke/global/global.dart';
import 'package:sugacke/mainScreens/home_screen.dart';
import 'package:sugacke/models/brans.dart';

class UploadItemsScreen extends StatefulWidget {
  final Brands? model;
  const UploadItemsScreen({super.key, this.model});

  @override
  State<UploadItemsScreen> createState() => _UploadItemsScreenState();
}

class _UploadItemsScreenState extends State<UploadItemsScreen> {
  XFile? selectedImage;
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController itemDescriptionTextEditingController =
      TextEditingController();
  final TextEditingController itemTitleTextEditingController =
      TextEditingController();
  final TextEditingController itemPriceTextEditingController =
      TextEditingController();

  bool upLoading = false;
  bool isFeatured = false;
  String downloadUrlImage = "";
  String itemUniqId = DateTime.now().millisecondsSinceEpoch.toString();

  bool get isFormValid {
    return selectedImage != null &&
        itemDescriptionTextEditingController.text.trim().isNotEmpty &&
        itemTitleTextEditingController.text.trim().isNotEmpty &&
        itemPriceTextEditingController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    itemDescriptionTextEditingController.dispose();
    itemTitleTextEditingController.dispose();
    itemPriceTextEditingController.dispose();
    super.dispose();
  }

  Future<File?> _compressImageFile(File originalFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${p.basenameWithoutExtension(originalFile.path)}.jpg';

      final XFile? compressedXFile =
          await FlutterImageCompress.compressAndGetFile(
            originalFile.path,
            targetPath,
            quality: 70,
            minWidth: 1080,
            minHeight: 1080,
            format: CompressFormat.jpeg,
          );

      if (compressedXFile == null) return null;
      return File(compressedXFile.path);
    } catch (_) {
      return null;
    }
  }

  Future<void> _onFeaturedToggleChanged(bool value) async {
    if (!value) {
      setState(() {
        isFeatured = false;
      });
      return;
    }

    final String? currentUid = sharedPreferences?.getString("uid");
    if (currentUid == null || currentUid.isEmpty) {
      return;
    }

    final featuredItemsSnapshot = await FirebaseFirestore.instance
        .collection("items")
        .where("sellerUID", isEqualTo: currentUid)
        .where("isFeatured", isEqualTo: true)
        .get();

    if (featuredItemsSnapshot.docs.length >= 4) {
      if (!mounted) return;
      setState(() {
        isFeatured = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum of 4 featured items allowed.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isFeatured = true;
    });
  }

  Future<void> saveBrandInfoToFirestore() async {
    final String? brandId = widget.model?.brandId;
    if (brandId == null || brandId.isEmpty) {
      throw Exception("Brand ID is missing. Please reopen from a valid brand.");
    }

    final String itemCategory =
        sharedPreferences?.getString("storeCategory") ?? "Others";
    final String itemCurrency =
        sharedPreferences?.getString("addressCurrency") ?? "SDG";

    await FirebaseFirestore.instance
        .collection("sellers")
        .doc(sharedPreferences!.getString("uid"))
        .collection("brands")
        .doc(brandId)
        .collection("items")
        .doc(itemUniqId)
        .set({
          "itemId": itemUniqId,
          "brandId": brandId,
          "sellerUID": sharedPreferences!.getString("uid"),
          "sellerName": sharedPreferences!.getString("name"),
          "sellerPhone": sharedPreferences!.getString("phone"),
          "itemDesc": itemDescriptionTextEditingController.text.trim(),
          "itemTitle": itemTitleTextEditingController.text.trim(),
          "itemPrice": itemPriceTextEditingController.text.trim(),
          "itemCategory": itemCategory,
          "currency": itemCurrency,
          "isFeatured": isFeatured,
          "publishedDate": DateTime.now(),
          "status": "available",
          "thumbnailUrl": downloadUrlImage,
        })
        .then((onValue) {
          FirebaseFirestore.instance.collection("items").doc(itemUniqId).set({
            "itemId": itemUniqId,
            "brandId": brandId,
            "sellerUID": sharedPreferences!.getString("uid"),
            "sellerName": sharedPreferences!.getString("name"),
            "sellerPhone": sharedPreferences!.getString("phone"),
            "itemDesc": itemDescriptionTextEditingController.text.trim(),
            "itemTitle": itemTitleTextEditingController.text.trim(),
            "itemPrice": itemPriceTextEditingController.text.trim(),
            "itemCategory": itemCategory,
            "currency": itemCurrency,
            "isFeatured": isFeatured,
            "publishedDate": DateTime.now(),
            "status": "available",
            "thumbnailUrl": downloadUrlImage,
          });
        });

    if (!mounted) return;

    setState(() {
      itemDescriptionTextEditingController.clear();
      itemTitleTextEditingController.clear();
      itemPriceTextEditingController.clear();
      selectedImage = null;
      isFeatured = false;
      upLoading = false;
      itemUniqId = DateTime.now().millisecondsSinceEpoch.toString();
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<void> validateUploadForm() async {
    if (!isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select image and fill all fields'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      upLoading = true;
    });

    File? compressedFile;

    try {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final File originalFile = File(selectedImage!.path);
      compressedFile = await _compressImageFile(originalFile);

      final File fileForUpload = compressedFile ?? originalFile;

      final fStorage.Reference reference = fStorage.FirebaseStorage.instance
          .ref()
          .child("sellersItemsImages")
          .child(fileName);

      final fStorage.UploadTask uploadTask = reference.putFile(fileForUpload);
      final fStorage.TaskSnapshot taskSnapshot = await uploadTask;
      downloadUrlImage = await taskSnapshot.ref.getDownloadURL();

      await saveBrandInfoToFirestore();
    } catch (e, st) {
      if (kDebugMode) {
        print('Upload error: $e');
        print(st);
      }

      if (!mounted) return;
      setState(() {
        upLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed. Please check network and retry.\n$e',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (compressedFile != null && await compressedFile.exists()) {
        await compressedFile.delete();
      }
    }
  }

  Future<void> getImageFromGallery() async {
    Navigator.pop(context);
    selectedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
    setState(() {});
  }

  Future<void> getImageFromCamera() async {
    Navigator.pop(context);
    selectedImage = await _imagePicker.pickImage(source: ImageSource.camera);
    setState(() {});
  }

  Widget _loadingOverlay() {
    if (!upLoading) return const SizedBox.shrink();

    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
          color: Colors.black45,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  Widget uploadFormScreen() {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: IconButton(
              onPressed: upLoading ? null : validateUploadForm,
              icon: const Icon(Icons.cloud_upload, color: Colors.white),
            ),
          ),
        ],
        backgroundColor: Colors.orangeAccent,
        elevation: 0,
        title: const Text('Upload New Item'),
        centerTitle: true,
      ),
      backgroundColor: Colors.orangeAccent,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    height: 230,
                    width: 230,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: FileImage(File(selectedImage!.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const Divider(
                    height: 20,
                    thickness: 2,
                    color: Colors.orangeAccent,
                  ),
                  ListTile(
                    leading: const Icon(Icons.description, color: Colors.white),
                    title: TextField(
                      controller: itemDescriptionTextEditingController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Item description',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const Divider(
                    height: 20,
                    thickness: 2,
                    color: Colors.orangeAccent,
                  ),
                  ListTile(
                    leading: const Icon(Icons.title, color: Colors.white),
                    title: TextField(
                      controller: itemTitleTextEditingController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'itemtitle',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.camera, color: Colors.white),
                    title: TextField(
                      controller: itemPriceTextEditingController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'item Price',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.white),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.shade300),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SwitchListTile(
                      activeThumbColor: Colors.deepOrange,
                      value: isFeatured,
                      onChanged: upLoading ? null : _onFeaturedToggleChanged,
                      title: const Text(
                        'Promotion Card',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Mark this product as featured (max 4)',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Opacity(
                    opacity: isFormValid ? 1 : 0.6,
                    child: ElevatedButton.icon(
                      onPressed: upLoading || !isFormValid
                          ? null
                          : validateUploadForm,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Upload Item'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _loadingOverlay(),
        ],
      ),
    );
  }

  Widget defaultScreen() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        elevation: 0,
        title: const Text('Add New Items'),
        centerTitle: true,
      ),
      backgroundColor: Colors.orangeAccent,
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Align(
              alignment: const Alignment(0, -0.25),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Colors.white,
                    size: 200,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: upLoading ? null : optainImageDialogBox,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Add New Item'),
                  ),
                ],
              ),
            ),
          ),
          _loadingOverlay(),
        ],
      ),
    );
  }

  Future<void> optainImageDialogBox() {
    return showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text(
            'Select brand Image From',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          children: [
            SimpleDialogOption(
              onPressed: getImageFromCamera,
              child: const Text(
                'Capture image with Camera',
                style: TextStyle(color: Colors.black),
              ),
            ),
            SimpleDialogOption(
              onPressed: getImageFromGallery,
              child: const Text(
                'Select image from Gallery',
                style: TextStyle(color: Colors.orange),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return selectedImage == null ? defaultScreen() : uploadFormScreen();
  }
}
