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
      width: 250,
      height: double.infinity,
      color: const Color(0xFF0C1D36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 REQ 2 & 3: Header Logo (dengan tinggi konsisten)
          Container(
            height: kHeaderHeight,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Image.asset(
                  '/images/logo_rambuid.png', // 👈 PASTIKAN PATH LOGO BENAR
                  width: 36,
                  height: 36,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error, color: Colors.red),
                ),
                const SizedBox(width: 12),
                Text(
                  'RambuID',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellowAccent[700],
                  ),
                ),
              ],
            ),
          ),
          
          // Item Navigasi
          _buildNavItem(
            icon: Icons.dashboard_rounded,
            title: 'Dashboard',
            index: 0,
          ),
          _buildNavItem(
            icon: Icons.signpost_rounded,
            title: 'Rambu',
            index: 1,
          ),
          _buildNavItem(
            icon: Icons.people_alt_rounded,
            title: 'Data Pengguna',
            index: 2,
          ),
        ],
      ),
    );
  }

  // 🔹 REQ 1: Tombol menu yang bisa diklik
  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = (currentIndex == index);
    final color = isSelected ? Colors.black : Colors.white;
    final bgColor =
        isSelected ? Colors.yellowAccent[700] : Colors.transparent;

    return Container(
      color: bgColor,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => onMenuSelected(index),
      ),
    );
  }
}