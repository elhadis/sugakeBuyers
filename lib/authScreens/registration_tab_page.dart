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

  final TextEditingController nameTextEditingController =
      TextEditingController();
  final TextEditingController emailTextEditingController =
      TextEditingController();
  final TextEditingController passwordTextEditingController =
      TextEditingController();
  final TextEditingController confirmPasswordTextEditingController =
      TextEditingController();
  final TextEditingController phoneTextEditingController =
      TextEditingController();

  XFile? selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  String downloadUrlImage = "";
  bool _isLoading = false;

  final List<String> storeCategories = const [
    'Men\'s Shoes',
    'Women & Home World',
    'Electronics',
    'Kids',
    'Supermarket',
    'Others',
  ];
  String selectedStoreCategory = 'Men\'s Shoes';

  static const Map<String, String> _countryToCurrency = {
    'Palestine': '₪ (ILS)',
    'Sudan': 'SDG',
    'Saudi Arabia': 'SAR',
    'UAE': 'AED',
    'Egypt': 'EGP',
    'USA': 'USD',
    'Jordan': 'JOD',
  };

  static const Map<String, String> _countryDialCode = {
    'Palestine': '+970',
    'Sudan': '+249',
    'Saudi Arabia': '+966',
    'UAE': '+971',
    'Egypt': '+20',
    'USA': '+1',
    'Jordan': '+962',
  };

  late final List<String> _countryNames;
  String selectedCountry = 'Palestine';
  String detectedCurrency = 'ILS';

  @override
  void initState() {
    super.initState();
    _countryNames = _countryToCurrency.keys.toList()..sort();
    selectedCountry = _countryNames.contains('Palestine')
        ? 'Palestine'
        : _countryNames.first;
    detectedCurrency = _currencyCodeOnlyForCountry(selectedCountry);
    phoneTextEditingController.addListener(_handlePhoneCurrencyAutoDetect);
  }

  @override
  void dispose() {
    phoneTextEditingController.removeListener(_handlePhoneCurrencyAutoDetect);
    nameTextEditingController.dispose();
    emailTextEditingController.dispose();
    passwordTextEditingController.dispose();
    confirmPasswordTextEditingController.dispose();
    phoneTextEditingController.dispose();
    super.dispose();
  }

  void _handlePhoneCurrencyAutoDetect() {
    final String rawPhone = phoneTextEditingController.text.trim();
    if (rawPhone.isEmpty) return;

    String? matchedCountry;
    int bestLength = 0;

    for (final entry in _countryDialCode.entries) {
      final dial = entry.value;
      if (rawPhone.startsWith(dial) && dial.length > bestLength) {
        matchedCountry = entry.key;
        bestLength = dial.length;
      }
    }

    if (matchedCountry != null && matchedCountry != selectedCountry) {
      if (!mounted) return;
      setState(() {
        selectedCountry = matchedCountry!;
        detectedCurrency = _currencyCodeOnlyForCountry(selectedCountry);
      });
    }
  }

  String _currencyCodeOnlyForCountry(String country) {
    final value = _countryToCurrency[country] ?? 'USD';
    if (value.contains('(') && value.contains(')')) {
      final start = value.indexOf('(') + 1;
      final end = value.indexOf(')');
      if (start > 0 && end > start) {
        return value.substring(start, end).trim();
      }
    }
    return value.trim();
  }

  String _currencyDisplayForCountry(String country) {
    return _countryToCurrency[country] ?? 'USD';
  }

  Future<void> getImageFromGallery() async {
    selectedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
    setState(() {
      selectedImage;
    });
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email.trim());
  }

  bool _isValidPhone(String phone) {
    final normalized = phone.trim();
    final regex = RegExp(r'^\+?[0-9]{7,15}$');
    return regex.hasMatch(normalized);
  }

  Future<void> formValidation() async {
    if (selectedImage == null) {
      Fluttertoast.showToast(msg: "Please select an image");
      return;
    }

    final name = nameTextEditingController.text.trim();
    final email = emailTextEditingController.text.trim();
    final password = passwordTextEditingController.text.trim();
    final confirmPassword = confirmPasswordTextEditingController.text.trim();
    final phone = phoneTextEditingController.text.trim();

    if (name.isEmpty) {
      Fluttertoast.showToast(msg: "Please enter your name");
      return;
    }

    if (!_isValidEmail(email)) {
      Fluttertoast.showToast(msg: "Please enter a valid email");
      return;
    }

    if (password.length < 6) {
      Fluttertoast.showToast(msg: "Password must be at least 6 characters");
      return;
    }

    if (password != confirmPassword) {
      Fluttertoast.showToast(msg: "Passwords do not match");
      return;
    }

    if (!_isValidPhone(phone)) {
      Fluttertoast.showToast(
        msg: "Please enter a valid phone number with country code",
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await saveInformationToDatabase();
    } catch (error) {
      Fluttertoast.showToast(msg: "Error: ${error.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> saveInformationToDatabase() async {
    try {
      UserCredential auth = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailTextEditingController.text.trim(),
            password: passwordTextEditingController.text.trim(),
          );

      User? currentUser = auth.user;
      if (currentUser == null) {
        throw Exception("Authentication failed: user is null");
      }

      String fileName =
          "${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}";
      fStorage.Reference reference = fStorage.FirebaseStorage.instance
          .ref()
          .child("usersImages")
          .child(fileName);

      fStorage.UploadTask uploadTask = reference.putFile(
        File(selectedImage!.path),
      );
      fStorage.TaskSnapshot taskSnapshot = await uploadTask;
      downloadUrlImage = await taskSnapshot.ref.getDownloadURL();

      await saveInfoToFirestoreAndLocal(currentUser);
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
        msg: "Auth error (${e.code}): ${e.message ?? 'Authentication failed'}",
      );
      rethrow;
    } on FirebaseException catch (e) {
      Fluttertoast.showToast(
        msg: "Firebase error (${e.code}): ${e.message ?? 'Operation failed'}",
      );
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveInfoToFirestoreAndLocal(User currentUser) async {
    try {
      final currencyCode = _currencyCodeOnlyForCountry(selectedCountry);

      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .set({
            "uid": currentUser.uid,
            "name": nameTextEditingController.text.trim(),
            "email":
                currentUser.email ?? emailTextEditingController.text.trim(),
            "phone": phoneTextEditingController.text.trim(),
            "photoUrl": downloadUrlImage,
            "storeCategory": selectedStoreCategory,
            "currency": currencyCode,
            "country": selectedCountry,
            "status": "approved",
            "createdAt": FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance
          .collection("sellers")
          .doc(currentUser.uid)
          .set({
            "uid": currentUser.uid,
            "name": nameTextEditingController.text.trim(),
            "email":
                currentUser.email ?? emailTextEditingController.text.trim(),
            "phone": phoneTextEditingController.text.trim(),
            "photoUrl": downloadUrlImage,
            "storeCategory": selectedStoreCategory,
            "currency": currencyCode,
            "country": selectedCountry,
            "status": "approved",
            "createdAt": FieldValue.serverTimestamp(),
          });

      sharedPreferences = await SharedPreferences.getInstance();
      await sharedPreferences!.setString("uid", currentUser.uid);
      await sharedPreferences!.setString(
        "name",
        nameTextEditingController.text.trim(),
      );
      await sharedPreferences!.setString(
        "email",
        currentUser.email ?? emailTextEditingController.text.trim(),
      );
      await sharedPreferences!.setString(
        "phone",
        phoneTextEditingController.text.trim(),
      );
      await sharedPreferences!.setString("photoUrl", downloadUrlImage);
      await sharedPreferences!.setString(
        "storeCategory",
        selectedStoreCategory,
      );
      await sharedPreferences!.setString("addressCurrency", currencyCode);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (c) => const HomeScreen()),
        );
      }
    } on FirebaseException catch (e) {
      Fluttertoast.showToast(
        msg: "Database error (${e.code}): ${e.message ?? 'Write failed'}",
      );
      rethrow;
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
      rethrow;
    }
  }

  InputDecoration _dropdownDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.deepOrange,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: Colors.orangeAccent),
      filled: true,
      fillColor: const Color(0xFFFFFAF6),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFC89C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepOrange, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyDisplay = _currencyDisplayForCountry(selectedCountry);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        children: [
          const SizedBox(height: 6),
          GestureDetector(
            onTap: getImageFromGallery,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 62,
                backgroundColor: Colors.orangeAccent,
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.white,
                  backgroundImage: selectedImage == null
                      ? null
                      : FileImage(File(selectedImage!.path)),
                  child: selectedImage == null
                      ? const Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Colors.orangeAccent,
                          size: 42,
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Create Seller Account",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Professional onboarding for your store",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Form(
              key: registrationFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedStoreCategory,
                    decoration: _dropdownDecoration(
                      label: "Store Category",
                      icon: Icons.category_outlined,
                    ),
                    iconEnabledColor: Colors.orangeAccent,
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w500,
                    ),
                    items: storeCategories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: _isLoading
                        ? null
                        : (String? value) {
                            if (value == null) return;
                            setState(() {
                              selectedStoreCategory = value;
                            });
                          },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCountry,
                    decoration: _dropdownDecoration(
                      label: "Country",
                      icon: Icons.public,
                    ),
                    iconEnabledColor: Colors.orangeAccent,
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w500,
                    ),
                    items: _countryNames.map((String country) {
                      return DropdownMenuItem<String>(
                        value: country,
                        child: Text(country),
                      );
                    }).toList(),
                    onChanged: _isLoading
                        ? null
                        : (String? value) {
                            if (value == null) return;
                            setState(() {
                              selectedCountry = value;
                              detectedCurrency = _currencyCodeOnlyForCountry(
                                selectedCountry,
                              );
                            });
                          },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3D6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD89A)),
                    ),
                    child: Text(
                      'Your store currency: $currencyDisplay',
                      style: const TextStyle(
                        color: Colors.brown,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomTextFaild(
                    textEditingController: nameTextEditingController,
                    hintText: "Name",
                    iconData: Icons.person,
                    isObscure: false,
                    isEnabled: !_isLoading,
                  ),
                  const SizedBox(height: 6),
                  CustomTextFaild(
                    textEditingController: emailTextEditingController,
                    hintText: "Email",
                    iconData: Icons.email,
                    isObscure: false,
                    isEnabled: !_isLoading,
                  ),
                  const SizedBox(height: 6),
                  CustomTextFaild(
                    textEditingController: passwordTextEditingController,
                    hintText: "Password",
                    iconData: Icons.lock,
                    isObscure: true,
                    isEnabled: !_isLoading,
                  ),
                  const SizedBox(height: 6),
                  CustomTextFaild(
                    textEditingController: confirmPasswordTextEditingController,
                    hintText: "Confirm Password",
                    iconData: Icons.lock,
                    isObscure: true,
                    isEnabled: !_isLoading,
                  ),
                  const SizedBox(height: 6),
                  CustomTextFaild(
                    textEditingController: phoneTextEditingController,
                    hintText: "Phone (with country code)",
                    iconData: Icons.phone,
                    isObscure: false,
                    isEnabled: !_isLoading,
                  ),
                  const SizedBox(height: 18),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.orangeAccent,
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: formValidation,
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
