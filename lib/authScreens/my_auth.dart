import 'package:flutter/material.dart';
import 'package:sugacke/authScreens/login_tab_page.dart';
import 'package:sugacke/authScreens/registration_tab_page.dart';
import 'package:sugacke/global/app_ui_tokens.dart';
import 'package:sugacke/l10n/translations.dart';
import 'package:sugacke/services/whatsapp_tracking_service.dart';

class MyAuth extends StatefulWidget {
  const MyAuth({super.key});

  @override
  State<MyAuth> createState() => _MyAuthState();
}

class _MyAuthState extends State<MyAuth> with SingleTickerProviderStateMixin {
  static const String _supportPhoneE164 = '249123323290';

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openSupportWhatsApp() async {
    await WhatsAppTrackingService.openTrackedChat(
      phoneNumber: _supportPhoneE164,
      storeName: 'Support',
      country: WhatsAppTrackingService.resolveCountry(null),
      customMessage:
          'Hello, I need help with the Sugacke app. Thank you.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSupportFab = _tabController.index == 0;

    return Scaffold(
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
          title: const Text(
            'سوقك',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(
                icon: Icon(Icons.lock_open_outlined, color: Colors.white),
                text: 'تسجيل الدخول',
              ),
              Tab(
                icon: Icon(
                  Icons.app_registration_outlined,
                  color: Colors.white,
                ),
                text: 'إنشاء حساب',
              ),
            ],
          ),
        ),
      floatingActionButton: showSupportFab
            ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppUiTokens.whatsapp.withValues(alpha: 0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: _openSupportWhatsApp,
                  backgroundColor: AppUiTokens.whatsapp,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  highlightElevation: 2,
                  icon: const Icon(Icons.support_agent_rounded, size: 26),
                  label: Text(
                    AppTranslations.text(context, 'support'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      fontSize: 15,
                    ),
                  ),
                ),
              )
            : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orangeAccent, Colors.orange],
              begin: FractionalOffset(0.0, 0.0),
              end: FractionalOffset(1.0, 0.0),
              stops: [0.0, 1.0],
              tileMode: TileMode.clamp,
            ),
          ),
          child: TabBarView(
            controller: _tabController,
            children: const [
              LoginTabPage(),
              RegistrationTabPage(),
            ],
          ),
        ),
    );
  }
}
