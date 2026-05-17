import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as fStorage;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sugacke/global/app_ui_tokens.dart';
import 'package:sugacke/global/country_currency_config.dart';
import 'package:sugacke/global/global.dart';
import 'package:sugacke/l10n/translations.dart';
import 'package:sugacke/mainScreens/home_screen.dart';
import 'package:sugacke/widgets/custom_text_faild.dart';

class RegistrationTabPage extends StatefulWidget {
  const RegistrationTabPage({super.key});

  @override
  State<RegistrationTabPage> createState() => _RegistrationTabPageState();
}

class _RegistrationTabPageState extends State<RegistrationTabPage> {
  static const Map<String, String> _storeCategoryTranslationKeyByValue = {
    'Men\'s Shoes': 'category_mens_shoes',
    'Women & Home World': 'category_women_home_world',
    'Electronics': 'category_electronics',
    'Kids': 'category_kids',
    'Supermarket': 'category_supermarket',
    'Services': 'category_services',
  };

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
  bool _agreedToTerms = false;

  final List<String> storeCategories = const [
    'Men\'s Shoes',
    'Women & Home World',
    'Electronics',
    'Kids',
    'Supermarket',
    'Services',
  ];
  String selectedStoreCategory = 'Men\'s Shoes';

  static const Map<String, String> _countryDialCode = {
    'Sudan': '+249',
    'Saudi Arabia': '+966',
    'UAE': '+971',
    'Egypt': '+20',
    'USA': '+1',
    'Qatar': '+974',
    'Kuwait': '+965',
    'Morocco': '+212',
    'Kenya': '+254',
    'Uganda': '+256',
    'Ethiopia': '+251',
    'Rwanda': '+250',
    'UK': '+44',
    'France': '+33',
    'Germany': '+49',
    'Netherlands': '+31',
    'Italy': '+39',
    'Spain': '+34',
    'Turkey': '+90',
    'Canada': '+1',
    'India': '+91',
  };

  late final List<String> _countryNames;
  String selectedCountry = 'Saudi Arabia';
  String detectedCurrency = 'SAR';

  static const List<String> _privacyPolicyPoints = [
    'All rights within this application are owned by the developers of the application. Customers are not allowed to sell or rent them or benefit from them to achieve a material return outside the features.',
    'The managerial and technical responsibility is the direct responsibility of the team developers.',
    'Providing technical support and immediate response to problem solving is one of the tasks of the developers team.',
    'Data protection and privacy are guaranteed; it is not allowed to upload pornographic content or content against public modesty, and such products may not be circulated or shared.',
    'The subscriber is committed to honesty and credibility in delivering the product according to the specified prices.',
    'It is not allowed to display products photographed with the effect of AI.',
    'Provide real and correct data to the subscriber.',
    'The obligation to pay monthly subscription fees after the free trial period, which is estimated at one or two months.',
  ];

  @override
  void initState() {
    super.initState();
    _countryNames = getCountryNamesSorted();
    selectedCountry = _countryNames.contains('Saudi Arabia')
        ? 'Saudi Arabia'
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
    final value = currencyCodeForCountry(country);
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
    return currencyCodeForCountry(country);
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

  Future<void> _showPrivacyPolicyDialog() async {
    final bool? accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepOrange, Colors.orangeAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.privacy_tip_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Privacy Policy & Terms",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Please read carefully before continuing:",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._privacyPolicyPoints.asMap().entries.map((entry) {
                          final int index = entry.key + 1;
                          final String text = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  margin: const EdgeInsets.only(top: 2),
                                  decoration: const BoxDecoration(
                                    color: Colors.orangeAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "$index",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    text,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 13.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          "Decline",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text(
                          "I Agree",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (accepted == true && mounted) {
      setState(() {
        _agreedToTerms = true;
      });
    }
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

    if (!_agreedToTerms) {
      Fluttertoast.showToast(
        msg: "Please read and agree to the Privacy Policy first",
      );
      await _showPrivacyPolicyDialog();
      if (!_agreedToTerms) return;
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
            "agreedToPrivacyPolicy": true,
            "agreedAt": FieldValue.serverTimestamp(),
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
            "agreedToPrivacyPolicy": true,
            "agreedAt": FieldValue.serverTimestamp(),
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

  Widget _sectionHeader({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.deepOrange, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.deepOrange,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Divider(color: Color(0xFFFFD8B5), thickness: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyDisplay = _currencyDisplayForCountry(selectedCountry);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final contentWidth = width > AppUiTokens.maxContentWidth
            ? AppUiTokens.maxCompactContentWidth
            : double.infinity;
        final avatarOuterRadius = width < 360 ? 54.0 : 64.0;
        final avatarInnerRadius = width < 360 ? 49.0 : 58.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _isLoading ? null : getImageFromGallery,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.30),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: avatarOuterRadius,
                            backgroundColor: Colors.orangeAccent,
                            child: CircleAvatar(
                              radius: avatarInnerRadius,
                              backgroundColor: Colors.white,
                              backgroundImage: selectedImage == null
                                  ? null
                                  : FileImage(File(selectedImage!.path)),
                              child: selectedImage == null
                                  ? const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: Colors.orangeAccent,
                                      size: 44,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.deepOrange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Create Seller Account",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width < 360 ? 19 : 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Professional onboarding for your store",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: width < 360 ? 12 : 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Form(
                    key: registrationFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _sectionHeader(
                                icon: Icons.storefront_outlined,
                                title: AppTranslations.text(
                                  context,
                                  'store_details',
                                ),
                              ),
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
                                  final translatedCategory =
                                      AppTranslations.text(
                                        context,
                                        _storeCategoryTranslationKeyByValue[category] ??
                                            category,
                                      );
                                  return DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(translatedCategory),
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
                              const SizedBox(height: 12),
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
                                          detectedCurrency =
                                              _currencyCodeOnlyForCountry(
                                                selectedCountry,
                                              );
                                        });
                                      },
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3D6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFFD89A),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.attach_money,
                                      color: Colors.brown,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Your store currency: $currencyDisplay',
                                        style: const TextStyle(
                                          color: Colors.brown,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _sectionHeader(
                                icon: Icons.person_outline,
                                title: AppTranslations.text(
                                  context,
                                  'personal_information',
                                ),
                              ),
                              CustomTextFaild(
                                textEditingController:
                                    nameTextEditingController,
                                hintText: AppTranslations.text(context, 'name'),
                                iconData: Icons.person,
                                isObscure: false,
                                isEnabled: !_isLoading,
                              ),
                              const SizedBox(height: 6),
                              CustomTextFaild(
                                textEditingController:
                                    emailTextEditingController,
                                hintText: AppTranslations.text(context, 'email'),
                                iconData: Icons.email,
                                isObscure: false,
                                isEnabled: !_isLoading,
                              ),
                              const SizedBox(height: 6),
                              CustomTextFaild(
                                textEditingController:
                                    phoneTextEditingController,
                                hintText: AppTranslations.text(
                                  context,
                                  'phone_with_country_code',
                                ),
                                iconData: Icons.phone,
                                isObscure: false,
                                isEnabled: !_isLoading,
                              ),
                            ],
                          ),
                        ),
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _sectionHeader(
                                icon: Icons.lock_outline,
                                title: AppTranslations.text(context, 'security'),
                              ),
                              CustomTextFaild(
                                textEditingController:
                                    passwordTextEditingController,
                                hintText: AppTranslations.text(
                                  context,
                                  'password',
                                ),
                                iconData: Icons.lock,
                                isObscure: true,
                                isEnabled: !_isLoading,
                              ),
                              const SizedBox(height: 6),
                              CustomTextFaild(
                                textEditingController:
                                    confirmPasswordTextEditingController,
                                hintText: AppTranslations.text(
                                  context,
                                  'confirm_password',
                                ),
                                iconData: Icons.lock,
                                isObscure: true,
                                isEnabled: !_isLoading,
                              ),
                            ],
                          ),
                        ),
                        _buildCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _agreedToTerms = !_agreedToTerms;
                                        });
                                      },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: _agreedToTerms,
                                          activeColor: Colors.deepOrange,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          onChanged: _isLoading
                                              ? null
                                              : (bool? value) {
                                                  setState(() {
                                                    _agreedToTerms =
                                                        value ?? false;
                                                  });
                                                },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 13.5,
                                              height: 1.4,
                                            ),
                                            children: [
                                              const TextSpan(
                                                text: "I agree to the ",
                                              ),
                                              const TextSpan(
                                                text: "Privacy Policy & Terms",
                                                style: TextStyle(
                                                  color: Colors.deepOrange,
                                                  fontWeight: FontWeight.w700,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                              const TextSpan(
                                                text:
                                                    " of this application (tap to read).",
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : _showPrivacyPolicyDialog,
                                  icon: const Icon(
                                    Icons.description_outlined,
                                    color: Colors.deepOrange,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    "Read full Privacy Policy",
                                    style: TextStyle(
                                      color: Colors.deepOrange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 0,
                                    ),
                                    minimumSize: const Size(0, 32),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              _isLoading
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: CircularProgressIndicator(
                                          color: Colors.orangeAccent,
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _agreedToTerms
                                              ? Colors.deepOrange
                                              : Colors.grey.shade400,
                                          disabledBackgroundColor:
                                              Colors.grey.shade400,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: _agreedToTerms ? 4 : 0,
                                        ),
                                        onPressed: _agreedToTerms
                                            ? formValidation
                                            : () async {
                                                Fluttertoast.showToast(
                                                  msg:
                                                      "Please read and agree to the Privacy Policy first",
                                                );
                                                await _showPrivacyPolicyDialog();
                                              },
                                        icon: Icon(
                                          _agreedToTerms
                                              ? Icons.check_circle_outline
                                              : Icons.lock_outline,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          "Sign Up",
                                          style: TextStyle(
                                            fontSize: 17,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
