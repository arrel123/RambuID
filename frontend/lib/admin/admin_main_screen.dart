import 'package:flutter/material.dart';
import 'side_menu.dart';
import 'dashboard_view.dart';
import 'rambu_view.dart';
import 'data_pengguna_view.dart';

// 🔹 Konstanta untuk alignment header
const double kHeaderHeight = 90.0;

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardView(onViewAllRambu: () => _onMenuSelected(1)),
      const RambuView(),
      const DataPenggunaView(),
    ];
  }

  void _onMenuSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  // 🔹 FUNGSI LOGIKA POPUP MENU
  void _handlePopupMenuSelection(BuildContext context, int value) async {
    if (value == 0) {
      // Tampilkan Dialog Profil
      _showProfileDialog(context);
    } else if (value == 1) {
      // Logika Logout
      final should = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                elevation: 0,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        ),
      );

      if (should == true) {
        if (!context.mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  // 🔹 FUNGSI DIALOG PROFIL
  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 350,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profil Admin',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey),
                      splashRadius: 20,
                    )
                  ],
                ),
                const Divider(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.yellowAccent[700]!, width: 3),
                  ),
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFFDD835),
                    child: Icon(Icons.person, size: 50, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Admin',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Administrator',
                    style: TextStyle(fontSize: 12, color: Colors.blue[800], fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildProfileRow(Icons.email_outlined, 'Email', 'admin@gmail.com'),
                      const Divider(height: 24),
                      _buildProfileRow(Icons.verified_user_outlined, 'Status Akun', 'Aktif'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD835),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width <= 650;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Poppins'),
      ),
      child: Scaffold(
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
                actions: [
                  PopupMenuButton<int>(
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (val) => _handlePopupMenuSelection(context, val),
                    itemBuilder: (context) => _buildPopupMenuItems(),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFFFDD835),
                        child: Icon(Icons.person, size: 20, color: Colors.black),
                      ),
                    ),
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
              if (!isMobile)
                SideMenu(
                  currentIndex: _selectedIndex,
                  onMenuSelected: _onMenuSelected,
                ),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    if (!isMobile)
                      _MainHeader(
                        selectedMenuIndex: _selectedIndex,
                        onMenuAction: (val) => _handlePopupMenuSelection(context, val),
                        menuItems: _buildPopupMenuItems(),
                      ),
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
      ),
    );
  }

  List<PopupMenuEntry<int>> _buildPopupMenuItems() {
    return [
      const PopupMenuItem(
        value: 0,
        child: Row(
          children: [
            Icon(Icons.person_outline, color: Colors.grey, size: 20),
            SizedBox(width: 12),
            Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 1,
        child: Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 20),
            SizedBox(width: 12),
            Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ];
  }
}

// --- WIDGET HEADER (DESKTOP) ---
class _MainHeader extends StatelessWidget {
  final int selectedMenuIndex;
  final Function(int) onMenuAction;
  final List<PopupMenuEntry<int>> menuItems;

  const _MainHeader({
    required this.selectedMenuIndex,
    required this.onMenuAction,
    required this.menuItems,
  });

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
      height: kHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Judul Halaman
          Text(
            _getTitle(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C1D36),
            ),
          ),

          // Bagian Profil Kanan Atas (Teks DIHILANGKAN, hanya Avatar)
          Row(
            children: [
              // Avatar dengan Popup Menu
              PopupMenuButton<int>(
                offset: const Offset(0, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: onMenuAction,
                itemBuilder: (context) => menuItems,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2), 
                        blurRadius: 4, 
                        offset: const Offset(0, 2)
                      )
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFFDD835),
                    child: Icon(Icons.person, size: 28, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}