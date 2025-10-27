import 'package:flutter/material.dart';
import 'tentang_pribadi.dart';
import 'bahasa.dart';
import 'riwayat.dart';

class SettingAccPage extends StatefulWidget {
  const SettingAccPage({super.key});

  @override
  State<SettingAccPage> createState() => _SettingAccPageState();
}

class _SettingAccPageState extends State<SettingAccPage> {
  String _namaLengkap = 'Andika Dwi';
  String _email = 'rezzy123@gmail.com';
  String _alamat = 'Batam center';

  void _updateProfile(String nama, String email, String alamat) {
    setState(() {
      _namaLengkap = nama;
      _email = email;
      _alamat = alamat;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Profile Picture
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/profile.png'),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: const Color(0xFFD6D588), width: 3),
                ),
              ),

              const SizedBox(height: 20),

              // Name
              Text(
                _namaLengkap,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              // Email
              Text(
                _email,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 4),

              // Location
              Text(
                _alamat,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // Menu Items
              _buildMenuItem(
                context,
                icon: Icons.credit_card_outlined,
                title: 'Tentang Pribadi',
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TentangPribadiPage(
                        initialNama: _namaLengkap,
                        initialEmail: _email,
                        initialAlamat: _alamat,
                      ),
                    ),
                  );

                  if (result != null && result is Map<String, dynamic>) {
                    _updateProfile(
                      result['nama'] as String,
                      result['email'] as String,
                      result['alamat'] as String,
                    );
                  }
                },
              ),

              _buildMenuItem(
                context,
                icon: Icons.language_outlined,
                title: 'Bahasa',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BahasaPage()),
                  );
                },
              ),

              _buildMenuItem(
                context,
                icon: Icons.history_outlined,
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
                context,
                icon: Icons.help_outline,
                title: 'Bantuan',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Halaman Bantuan belum tersedia'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              _buildMenuItem(
                context,
                icon: Icons.info_outline,
                title: 'Tentang Kami',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Halaman Tentang Kami belum tersedia'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showLogoutDialog(context);
                    },
                    icon: const Icon(Icons.logout, color: Color(0xFFD6D588)),
                    label: const Text(
                      'Keluar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD6D588),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F5F5),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 18),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 24, color: Colors.black54),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Keluar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6D588),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
