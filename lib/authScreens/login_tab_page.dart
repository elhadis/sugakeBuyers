import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/mainScreens/home_screen.dart';
import 'package:sugacke/services/firebase_auth_service.dart';
import 'package:sugacke/widgets/custom_text_faild.dart';

class LoginTabPage extends StatefulWidget {
  const LoginTabPage({super.key});

  @override
  State<LoginTabPage> createState() => _LoginTabPageState();
}

class _LoginTabPageState extends State<LoginTabPage> {
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!loginFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signIn(
        email: emailTextEditingController.text,
        password: passwordTextEditingController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login successful')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Login failed')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Something went wrong')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          Form(
            key: loginFormKey,
            child: Column(
              children: [
                CustomTextFaild(
                  textEditingController: emailTextEditingController,
                  hintText: 'Email',
                   isObscure: false,
                  iconData: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                CustomTextFaild(
                  textEditingController: passwordTextEditingController,
                  hintText: 'Password',
                  iconData: Icons.lock,
                  isObscure: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
