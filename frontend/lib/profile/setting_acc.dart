import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../l10n/app_localizations.dart';
import 'tentang_pribadi.dart';
import 'bahasa.dart';
import 'riwayat.dart';
import 'bantuan.dart';
import 'tentang_kami.dart';

class SettingAccPage extends StatefulWidget {
  final int userId;
  final String username;

  const SettingAccPage({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<SettingAccPage> createState() => _SettingAccPageState();
}

class _SettingAccPageState extends State<SettingAccPage> {
  String _namaLengkap = '';
  String _email = '';
  String _alamat = '';
  String? _profileImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    final result = await ApiService.getUserProfile(widget.userId);

    if (mounted) {
      if (result['success']) {
        dynamic profileData = result['data'];
        
        if (profileData is Map<String, dynamic> && profileData.containsKey('data')) {
           profileData = profileData['data'];
        }
        if (profileData is Map<String, dynamic> && profileData.containsKey('user')) {
           profileData = profileData['user'];
        }

        setState(() {
          _namaLengkap = profileData['nama_lengkap'] ?? 'Pengguna';
          _email = profileData['username'] ?? widget.username;
          // FIX: Jangan hardcode 'Belum ada alamat' disini, biarkan kosong jika null
          _alamat = profileData['alamat'] ?? ''; 
          _profileImage = profileData['profile_image'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _namaLengkap = 'Pengguna';
          _email = widget.username;
          _alamat = '';
          _isLoading = false;
        });
      }
    }
  }

  void _updateProfile(String nama, String email, String alamat, String? profileImage) {
    setState(() {
      _namaLengkap = nama;
      _email = email;
      _alamat = alamat;
      if (profileImage != null) {
        _profileImage = profileImage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // LOGIKA BAHASA UNTUK TEXT DEFAULT
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final Size screenSize = MediaQuery.of(context).size;

    // Tentukan teks alamat yang ditampilkan
    String displayAlamat = _alamat;
    if (_alamat.isEmpty) {
      displayAlamat = isEnglish ? 'No address set' : 'Belum ada alamat';
    }

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD6D588)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: double.infinity,
        height: screenSize.height,
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 20), 

            // --- BAGIAN PROFIL ---
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD6D588), width: 3),
                color: Colors.grey[200],
              ),
              child: ClipOval(
                child: _profileImage != null && _profileImage!.isNotEmpty
                    ? Image.network(
                        ApiService.getImageUrl(_profileImage),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                           return Icon(Icons.person, size: 50, color: Colors.grey[400]);
                        },
                      )
                    : Icon(Icons.person, size: 50, color: Colors.grey[400]),
              ),
            ),

            const SizedBox(height: 12),
            
            Text(
              _namaLengkap,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Text(_email, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            
            // TAMPILKAN ALAMAT (Data Asli atau Text Default Bahasa Inggris/Indo)
            Text(
              displayAlamat, 
              style: TextStyle(
                fontSize: 14, 
                color: _alamat.isEmpty ? Colors.redAccent : Colors.grey, // Merah dikit kalau kosong biar sadar
                fontStyle: _alamat.isEmpty ? FontStyle.italic : FontStyle.normal
              )
            ),

            const SizedBox(height: 20),
            const Divider(thickness: 1, color: Color(0xFFEEEEEE)),

            // --- LIST MENU ---
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.credit_card_outlined,
                    title: l10n.personalInfo,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TentangPribadiPage(
                            userId: widget.userId,
                            initialNama: _namaLengkap,
                            initialEmail: _email,
                            initialAlamat: _alamat, // Kirim data asli (bisa kosong)
                            initialProfileImage: _profileImage,
                          ),
                        ),
                      );
                      if (result != null && result is Map<String, dynamic>) {
                        _updateProfile(
                          result['nama'] as String,
                          result['email'] as String,
                          result['alamat'] as String,
                          result['profileImage'] as String?,
                        );
                      }
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.language_outlined,
                    title: l10n.language,
                    onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const BahasaPage())
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.history_outlined,
                    title: l10n.history,
                    onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const RiwayatPage())
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.help_outline,
                    title: l10n.help,
                    onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const BantuanPage())
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.info_outline,
                    title: l10n.aboutUs,
                    onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (context) => const TentangKamiPage())
                    ),
                  ),
                ],
              ),
            ),

            // --- TOMBOL LOGOUT ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: InkWell(
                onTap: () => _showLogoutDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout, color: Color(0xFF2C3E50), size: 22),
                      const SizedBox(width: 10),
                      Text(
                        l10n.logout,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 85), 
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF9F9F9), width: 1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD6D588).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.logout, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(l10n.logoutConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6D588),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(l10n.logout, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}