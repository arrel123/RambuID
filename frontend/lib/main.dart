import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:provider/provider.dart';

// Import halaman lain
import 'features/edukasi.dart';
import 'profile/setting_acc.dart';
import 'auth/login_page.dart';
import 'auth/regis.dart';
import 'features/beranda.dart';
import 'features/deteksi.dart';
import 'features/jelajahi_maps.dart'; 
import 'admin/admin_main_screen.dart';
import 'l10n/app_localizations.dart';
import 'providers/language_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          
          // 🌍 Localization Setup
          locale: languageProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('id', ''), // Indonesian
          ],
          
          theme: ThemeData(
            fontFamily: 'Poppins',
            primaryColor: const Color(0xFFD6D588),
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD6D588)),
          ),
          
          home: const LoginPage(),
          
          routes: {
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisPage(),
          },
          
          onGenerateRoute: (settings) {
            if (settings.name == '/home') {
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => HomePage(
                  userId: args?['userId'] ?? 0,
                  username: args?['username'] ?? '',
                ),
              );
            } else if (settings.name == '/admin/dashboard_view') {
              return MaterialPageRoute(
                builder: (context) => const AdminMainScreen(),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final int userId;
  final String username;

  const HomePage({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    final List<Widget> pages = [
      const KatalogRambuScreen(),
      const EdukasiPage(),
      const DeteksiPage(),
      JelajahiMapsEmbedPage(), 
      SettingAccPage(
        userId: widget.userId,
        username: widget.username,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: pages[_selectedIndex],

      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: const Color(0xFFFFFFFF),
        color: const Color(0xFFD6D588),
        buttonBackgroundColor: const Color(0xFFD6D588),
        animationDuration: const Duration(milliseconds: 300),
        items: [
          CurvedNavigationBarItem(
            child: const Icon(Icons.home_outlined),
            label: l10n.navHome,
          ),
          CurvedNavigationBarItem(
            child: const Icon(Icons.description_outlined),
            label: l10n.navEducation,
          ),
          CurvedNavigationBarItem(
            child: const Icon(Icons.document_scanner_outlined),
            label: l10n.navDetection,
          ),
          CurvedNavigationBarItem(
            child: const Icon(Icons.location_on_outlined),
            label: l10n.navExplore,
          ),
          CurvedNavigationBarItem(
            child: const Icon(Icons.perm_identity),
            label: l10n.navPersonal,
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}