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
            Locale('en', ''), 
            Locale('id', ''), 
          ],
          
          theme: ThemeData(
            fontFamily: 'Poppins',
            primaryColor: const Color(0xFFD6D588),
            scaffoldBackgroundColor: const Color(0xFFFFFFFF),
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
                  initialIndex: args?['initialIndex'] ?? 0,
                  initialCategory: args?['initialCategory'],
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
  final int initialIndex;
  final String? initialCategory;

  const HomePage({
    super.key,
    required this.userId,
    required this.username,
    this.initialIndex = 0,
    this.initialCategory,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Di dalam file main.dart -> class _HomePageState

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    final List<Widget> pages = [
      // 🔥 PERBAIKAN: Kirim userId dan username ke Beranda (KatalogRambuScreen)
      KatalogRambuScreen(
        userId: widget.userId,
        username: widget.username,
      ), 
      EdukasiPage(
        initialCategory: widget.initialCategory,
      ),
      const DeteksiPage(),
      JelajahiMapsPage(), 
      SettingAccPage(
        userId: widget.userId,
        username: widget.username,
      ),
    ];

    return Scaffold(
      // ✅ FIX 1: extendBody membuat konten memanjang ke belakang navbar (efek transparan)
      extendBody: true, 
      backgroundColor: const Color(0xFFFFFFFF),
      
      body: pages[_selectedIndex],

      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        // ✅ FIX 2: Background transparan agar menyatu dengan body
        backgroundColor: Colors.transparent, 
        
        // Warna batang navigasi
        color: const Color(0xFFD6D588),
        
        // Warna lingkaran tombol (Dikembalikan ke warna semula)
        buttonBackgroundColor: const Color(0xFFD6D588),
        
        height: 65, 
        animationDuration: const Duration(milliseconds: 300),
        
        // ✅ FIX 3: Ikon dikembalikan ke default (tanpa color: Colors.white)
        items: [
          CurvedNavigationBarItem(
            child: const Icon(Icons.home_outlined), 
            label: l10n.navHome,
            labelStyle: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
          CurvedNavigationBarItem(
            child: const Icon(Icons.description_outlined),
            label: l10n.navEducation,
            labelStyle: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
          CurvedNavigationBarItem(
            child: const Icon(Icons.document_scanner_outlined),
            label: l10n.navDetection,
            labelStyle: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
          CurvedNavigationBarItem(
            child: const Icon(Icons.location_on_outlined),
            label: l10n.navExplore,
            labelStyle: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
          CurvedNavigationBarItem(
            child: const Icon(Icons.perm_identity),
            label: l10n.navPersonal,
            labelStyle: const TextStyle(fontSize: 10, color: Colors.black54),
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
