import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as fStorage;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sugacke/global/global.dart';
import 'package:sugacke/mainScreens/home_screen.dart';
import 'package:sugacke/widgets/custom_text_faild.dart';

class RegistrationTabPage extends StatefulWidget {
  const RegistrationTabPage({super.key});

  @override
  State<RegistrationTabPage> createState() => _RegistrationTabPageState();
}

class _RegistrationTabPageState extends State<RegistrationTabPage> {
  final GlobalKey<FormState> registrationFormKey = GlobalKey<FormState>();
  
  final TextEditingController nameTextEditingController = TextEditingController();
  final TextEditingController emailTextEditingController = TextEditingController();
  final TextEditingController passwordTextEditingController = TextEditingController();
  final TextEditingController confirmPasswordTextEditingController = TextEditingController();
  final TextEditingController phoneTextEditingController = TextEditingController();

  XFile? selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  String downloadUrlImage = "";
  bool _isLoading = false;

  /// 1. Pick image from gallery
  Future<void> getImageFromGallery() async {
    selectedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
    setState(() {});
  }

  /// 2. Validate form and start the process
  Future<void> formValidation() async {
    if (selectedImage == null) {
      Fluttertoast.showToast(msg: "Please select an image");
      return;
    }

    if (passwordTextEditingController.text.trim() !=
        confirmPasswordTextEditingController.text.trim()) {
      Fluttertoast.showToast(msg: "Passwords do not match");
      return;
    }

    if (nameTextEditingController.text.trim().isEmpty ||
        emailTextEditingController.text.trim().isEmpty ||
        passwordTextEditingController.text.trim().isEmpty ||
        phoneTextEditingController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await saveInformationToDatabase();
    } catch (error) {
      print("Error during registration flow: $error");
      Fluttertoast.showToast(msg: "Error: ${error.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 3. Create Firebase Auth User, then upload image, then save to Firestore.
  Future<void> saveInformationToDatabase() async {
    try {
      print("STEP 1: Creating User Auth...");
      UserCredential auth = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTextEditingController.text.trim(),
        password: passwordTextEditingController.text.trim(),
      );

      User? currentUser = auth.user;
      if (currentUser == null) {
        throw Exception("Authentication failed: user is null");
      }

     
      String fileName = "${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}";
      fStorage.Reference reference = fStorage.FirebaseStorage.instance
          .ref()
          .child("usersImages")
          .child(fileName);

      fStorage.UploadTask uploadTask = reference.putFile(File(selectedImage!.path));
      fStorage.TaskSnapshot taskSnapshot = await uploadTask;
      downloadUrlImage = await taskSnapshot.ref.getDownloadURL();
     

     
      await saveInfoToFirestoreAndLocal(currentUser);
    } on FirebaseAuthException catch (e) {
    
      Fluttertoast.showToast(msg: "Auth error (${e.code}): ${e.message ?? 'Authentication failed'}");
      rethrow;
    } on FirebaseException catch (e) {
      Fluttertoast.showToast(msg: "Firebase error (${e.code}): ${e.message ?? 'Operation failed'}");
      rethrow;
    } catch (e) {
      print("saveInformationToDatabase Error: $e");
      rethrow;
    }
  }

  /// 4. Save Data to Firestore and SharedPrefs
  Future<void> saveInfoToFirestoreAndLocal(User currentUser) async {
    try {
      await FirebaseFirestore.instance.collection("users").doc(currentUser.uid).set({
        "uid": currentUser.uid,
        "name": nameTextEditingController.text.trim(),
        "email": currentUser.email ?? emailTextEditingController.text.trim(),
        "phone": phoneTextEditingController.text.trim(),
        "photoUrl": downloadUrlImage,
        "status": "approved",
        "createdAt": FieldValue.serverTimestamp(),
      });

     
      sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences!.setString("uid", currentUser.uid);
      await sharedPreferences!.setString("name", nameTextEditingController.text.trim());
      await sharedPreferences!.setString(
        "email",
        currentUser.email ?? emailTextEditingController.text.trim(),
      );
      await sharedPreferences!.setString("phone", phoneTextEditingController.text.trim());
      await sharedPreferences!.setString("photoUrl", downloadUrlImage);

      print("Registration Complete!");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const HomeScreen()),
        );
      }
    } on FirebaseException catch (e) {
      print("Firestore/Storage FirebaseException: code=${e.code}, message=${e.message}");
      Fluttertoast.showToast(msg: "Database error (${e.code}): ${e.message ?? 'Write failed'}");
      rethrow;
    } catch (e) {
      print("Firestore/Local Error: $e");
      Fluttertoast.showToast(msg: e.toString());
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          GestureDetector(
            onTap: getImageFromGallery,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Colors.orangeAccent,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white,
                backgroundImage: selectedImage == null
                    ? null
                    : FileImage(File(selectedImage!.path)),
                child: selectedImage == null
                    ? const Icon(Icons.add_photo_alternate, color: Colors.orangeAccent, size: 40)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Form(
            key: registrationFormKey,
            child: Column(
              children: [
                CustomTextFaild(
                  textEditingController: nameTextEditingController,
                  hintText: "Name",
                  iconData: Icons.person,
                  isObscure: false,
                  isEnabled: !_isLoading,
                ),
                CustomTextFaild(
                  textEditingController: emailTextEditingController,
                  hintText: "Email",
                  iconData: Icons.email,
                  isObscure: false,
                  isEnabled: !_isLoading,
                ),
                CustomTextFaild(
                  textEditingController: passwordTextEditingController,
                  hintText: "Password",
                  iconData: Icons.lock,
                  isObscure: true,
                  isEnabled: !_isLoading,
                ),
                CustomTextFaild(
                  textEditingController: confirmPasswordTextEditingController,
                  hintText: "Confirm Password",
                  iconData: Icons.lock,
                  isObscure: true,
                  isEnabled: !_isLoading,
                ),
                CustomTextFaild(
                  textEditingController: phoneTextEditingController,
                  hintText: "Phone",
                  iconData: Icons.phone,
                  isObscure: false,
                  isEnabled: !_isLoading,
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.orangeAccent)
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                        ),
                        onPressed: formValidation,
                        child: const Text(
                          "Register",
                          style: TextStyle(fontSize: 18, color: Colors.deepOrange, fontWeight: FontWeight.bold),
                        ),
                      ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}