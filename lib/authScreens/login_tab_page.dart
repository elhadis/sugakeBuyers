import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sugacke/global/app_ui_tokens.dart';
import 'package:sugacke/l10n/translations.dart';
import 'package:sugacke/mainScreens/home_screen.dart';
import 'package:sugacke/services/firebase_auth_service.dart';
import 'package:sugacke/services/user_session_service.dart';
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

  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  String? _validateResetEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppTranslations.text(context, 'please_enter_email');
    }
    if (!_emailRegex.hasMatch(value)) {
      return AppTranslations.text(context, 'please_enter_valid_email');
    }
    return null;
  }

  Future<void> _showResetPasswordDialog() async {
    final resetEmailController = TextEditingController(
      text: emailTextEditingController.text.trim(),
    );
    final resetFormKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var sending = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                AppTranslations.text(context, 'reset_password'),
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Form(
                key: resetFormKey,
                child: SingleChildScrollView(
                  child: CustomTextFaild(
                    textEditingController: resetEmailController,
                    hintText: AppTranslations.text(context, 'email'),
                    isObscure: false,
                    iconData: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateResetEmail,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: sending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    AppTranslations.text(context, 'cancel'),
                    style: TextStyle(
                      color: sending
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: sending
                      ? null
                      : () async {
                          if (resetFormKey.currentState?.validate() != true) {
                            if (!mounted) return;
                            final trimmed = resetEmailController.text.trim();
                            final msg = trimmed.isEmpty
                                ? AppTranslations.text(
                                    context,
                                    'please_enter_email_dot',
                                  )
                                : AppTranslations.text(
                                    context,
                                    'please_enter_valid_email_address',
                                  );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(msg)));
                            return;
                          }
                          setDialogState(() => sending = true);
                          final email = resetEmailController.text.trim();
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: email,
                            );
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppTranslations.text(
                                    context,
                                    'password_reset_sent',
                                  ),
                                ),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            setDialogState(() => sending = false);
                            if (!mounted) return;
                            final message = switch (e.code) {
                              'invalid-email' =>
                                AppTranslations.text(context, 'email_not_valid'),
                              'user-not-found' =>
                                AppTranslations.text(
                                  context,
                                  'no_account_for_email',
                                ),
                              'network-request-failed' =>
                                AppTranslations.text(
                                  context,
                                  'network_error_check_connection',
                                ),
                              _ =>
                                e.message ??
                                AppTranslations.text(
                                  context,
                                  'could_not_send_reset_email',
                                ),
                            };
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(message)));
                          } catch (_) {
                            setDialogState(() => sending = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  AppTranslations.text(
                                    context,
                                    'something_went_wrong',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                  child: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.orange,
                          ),
                        )
                      : Text(
                          AppTranslations.text(context, 'send'),
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    resetEmailController.dispose();
  }

  Future<void> _handleLogin() async {
    if (!loginFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await _authService.signIn(
        email: emailTextEditingController.text,
        password: passwordTextEditingController.text,
      );

      final user = credential.user;
      if (user != null) {
        await UserSessionService.loadSellerIntoSharedPreferences(user);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(AppTranslations.text(context, 'login_successful'))),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? AppTranslations.text(context, 'login_failed'),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(AppTranslations.text(context, 'something_went_wrong'))),
      );
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final contentWidth = width > AppUiTokens.maxContentWidth
            ? 520.0
            : double.infinity;
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Form(
                    key: loginFormKey,
                    child: Column(
                      children: [
                        CustomTextFaild(
                          textEditingController: emailTextEditingController,
                          hintText: AppTranslations.text(context, 'email'),
                          isObscure: false,
                          iconData: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppTranslations.text(
                                context,
                                'please_enter_email',
                              );
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return AppTranslations.text(
                                context,
                                'please_enter_valid_email',
                              );
                            }
                            return null;
                          },
                        ),
                        CustomTextFaild(
                          textEditingController: passwordTextEditingController,
                          hintText: AppTranslations.text(context, 'password'),
                          iconData: Icons.lock,
                          isObscure: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppTranslations.text(
                                context,
                                'please_enter_password',
                              );
                            }
                            if (value.length < 6) {
                              return AppTranslations.text(context, 'password_min_6');
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : _showResetPasswordDialog,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              AppTranslations.text(context, 'forgot_password'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(AppTranslations.text(context, 'login')),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
