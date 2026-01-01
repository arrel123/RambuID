import 'package:flutter/material.dart';
import 'admin_main_screen.dart'; // Import untuk kHeaderHeight

class SideMenu extends StatelessWidget {
  final int currentIndex;
  final Function(int) onMenuSelected;

  const SideMenu({
    super.key,
    required this.currentIndex,
    required this.onMenuSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270, // Lebar sedikit ditambah
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0C1D36),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(2, 0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER LOGO ---
          Container(
            height: kHeaderHeight, // Konsisten dengan header kanan
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                // Gambar Logo
                Image.asset(
                  'assets/images/logo_rambuid.png', 
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent[700],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.traffic, color: Colors.black, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                // Teks Logo
                Text(
                  'RambuID',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent[700],
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          
          // Garis pemisah halus
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 32), // Jarak yang cukup jauh setelah logo

          // --- MENU ITEMS (DENGAN JARAK & STYLE ELEGAN) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // Margin kiri-kanan
            child: Column(
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_rounded,
                  title: 'Dashboard',
                  index: 0,
                ),
                const SizedBox(height: 12), // Jarak antar menu
                _buildNavItem(
                  icon: Icons.signpost_rounded,
                  title: 'Rambu',
                  index: 1,
                ),
                const SizedBox(height: 12), // Jarak antar menu
                _buildNavItem(
                  icon: Icons.people_alt_rounded,
                  title: 'Data Pengguna',
                  index: 2,
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Versi App di bawah
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'RambuID v1.0',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = (currentIndex == index);
    
    // Styling warna
    final bgColor = isSelected ? Colors.yellowAccent[700] : Colors.transparent;
    final fgColor = isSelected ? Colors.black : Colors.grey[300];
    final iconColor = isSelected ? Colors.black : Colors.grey[400];
    final fontWeight = isSelected ? FontWeight.bold : FontWeight.w500;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onMenuSelected(index),
        borderRadius: BorderRadius.circular(12), // Radius sudut menu
        hoverColor: Colors.white.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: fgColor,
                  fontWeight: fontWeight,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}