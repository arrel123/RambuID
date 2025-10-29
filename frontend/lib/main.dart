import 'package:flutter/material.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';

// Import halaman lain
import 'features/edukasi.dart';
import 'profile/setting_acc.dart';
import 'auth/login_page.dart';
import 'auth/regis.dart';
import 'features/beranda.dart';
import 'features/deteksi.dart';
import 'features/jelajahi_maps.dart'; 
import 'admin/admin_main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: const Color(0xFFD6D588),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD6D588)),
      ),
      // 🔹 Mulai dari halaman Login
      home: const LoginPage(),
      // 🔹 Define routes untuk navigasi
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisPage(),
        '/admin_dashboard': (context) => const AdminMainScreen(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Daftar halaman untuk tiap tab
  final List<Widget> _pages = [
    const KatalogRambuScreen(),
    const EdukasiPage(),
    const DeteksiPage(),
    const JelajahiMapsPage(), 
    const SettingAccPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: _pages[_selectedIndex],

      // 🔹 Curved Navigation Bar
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: const Color(0xFFFFFFFF),
        color: const Color(0xFFD6D588),
        buttonBackgroundColor: const Color(0xFFD6D588),
        animationDuration: const Duration(milliseconds: 300),
        items: const [
          CurvedNavigationBarItem(
            child: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.description_outlined),
            label: 'Edukasi',
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.document_scanner_outlined),
            label: 'Deteksi',
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.location_on_outlined),
            label: 'Jelajahi',
          ),
          CurvedNavigationBarItem(
            child: Icon(Icons.perm_identity),
            label: 'Personal',
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
