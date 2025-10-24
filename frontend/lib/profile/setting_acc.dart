import 'package:flutter/material.dart';
import 'tentang_pribadi.dart';
import 'riwayat.dart';
import 'bahasa.dart';
import '../auth/login_page.dart';

class SettingAccPage extends StatelessWidget {
  const SettingAccPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 35,
                  backgroundImage: AssetImage('assets/images/profile.png'),
                  backgroundColor: Colors.grey[300],
                ),
                const SizedBox(width: 16),
                // Profile Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Andika Dwi',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'rezzy123@gmail.com',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Batam center',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu List
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(
                  icon: Icons.card_membership_outlined,
                  title: 'Tentang Pribadi',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TentangPribadiPage(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.language,
                  title: 'Bahasa',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BahasaPage(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.history,
                  title: 'Riwayat',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RiwayatPage(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'Bantuan',
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'Tentang Kami',
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: OutlinedButton(
              onPressed: () {
                _showLogoutDialog(context);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout, color: Color(0xFFD6D588)),
                  SizedBox(width: 8),
                  Text(
                    'Keluar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFD6D588),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Konfirmasi Logout',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari aplikasi?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to login page and clear navigation stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text(
                'Keluar',
                style: TextStyle(
                  color: Color(0xFFD6D588),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
