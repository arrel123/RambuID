import 'package:flutter/material.dart';
import 'side_menu.dart';
import 'dashboard_view.dart';
import 'rambu_view.dart';
import 'data_pengguna_view.dart';

// 🔹 Konstanta untuk alignment header
const double kHeaderHeight = 80.0;

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 🔹 Daftar halaman/view yang akan ditampilkan
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      // 🔹 Halaman Dashboard (index 0)
      // Kirim fungsi untuk pindah halaman ke Rambu (index 1)
      DashboardView(
        onViewAllRambu: () => _onMenuSelected(1),
      ),
      
      // 🔹 Halaman Rambu (index 1)
      const RambuView(),
      
      // 🔹 Halaman Data Pengguna (index 2)
      const DataPenggunaView(),
    ];
  }

  // 🔹 Fungsi untuk mengubah halaman
  void _onMenuSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Jika di mobile, tutup drawer setelah diklik
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width <= 650;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: isMobile
          ? AppBar(
              title: Text(
                'RambuID',
                style: TextStyle(
                  color: Colors.yellowAccent[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: const Color(0xFF0C1D36),
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              // Tambahkan menu aksi (profil / logout) di AppBar untuk mobile
              actions: [
                PopupMenuButton<int>(
                  onSelected: (value) async {
                    if (value == 1) {
                      // Konfirmasi logout
                      final should = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Anda yakin ingin keluar?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Batal')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFDD835),
                                  foregroundColor: Colors.black),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );

                      if (should == true) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (route) => false);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 0, child: Text('Profil')),
                    const PopupMenuItem(value: 1, child: Text('Logout')),
                  ],
                ),
              ],
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: SideMenu(
                currentIndex: _selectedIndex,
                onMenuSelected: _onMenuSelected,
              ),
            )
          : null,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu Samping (Desktop)
            if (!isMobile)
              SideMenu(
                currentIndex: _selectedIndex,
                onMenuSelected: _onMenuSelected,
              ),
            
            // Konten Halaman
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  // 🔹 Header Konten (Desktop)
                  if (!isMobile)
                    _MainHeader(selectedMenuIndex: _selectedIndex),
                  
                  // 🔹 Halaman yang dipilih akan tampil di sini
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _pages,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET: Header Konten Utama ---
class _MainHeader extends StatelessWidget {
  final int selectedMenuIndex;
  const _MainHeader({required this.selectedMenuIndex});

  String _getTitle() {
    switch (selectedMenuIndex) {
      case 0: return 'Dashboard';
      case 1: return 'Rambu';
      case 2: return 'Data Pengguna';
      default: return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 🔹 REQ 3: Alignment dengan tinggi konsisten
      height: kHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getTitle(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Popup menu pada avatar (Profil / Logout) untuk desktop header
          PopupMenuButton<int>(
            onSelected: (value) async {
              if (value == 1) {
                final should = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Anda yakin ingin keluar?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Batal')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFDD835),
                            foregroundColor: Colors.black),
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (should == true) {
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 0, child: Text('Profil')),
              PopupMenuItem(value: 1, child: Text('Logout')),
            ],
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFE0E0E0),
              child: Icon(
                Icons.person_outline_rounded,
                size: 24,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}