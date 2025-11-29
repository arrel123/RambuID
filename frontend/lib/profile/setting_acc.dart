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
    setState(() {
      _isLoading = true;
    });

    final result = await ApiService.getUserProfile(widget.userId);

    if (result['success']) {
      final profile = result['data'];
      setState(() {
        _namaLengkap = profile['nama_lengkap'] ?? 'Pengguna';
        _email = profile['username'] ?? widget.username;
        _alamat = profile['alamat'] ?? 'Belum ada alamat';
        _profileImage = profile['profile_image'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _namaLengkap = 'Pengguna';
        _email = widget.username;
        _alamat = 'Belum ada alamat';
        _isLoading = false;
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? l10n.profileLoadFailed),
            backgroundColor: Colors.orange,
          ),
        );
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
    
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD6D588),
          ),
        ),
      );
    }

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
                  border: Border.all(color: const Color(0xFFD6D588), width: 3),
                  color: Colors.grey[200],
                ),
                child: ClipOval(
                  child: _profileImage != null && _profileImage!.isNotEmpty
                      ? Image.network(
                          '${ApiService.baseUrl}$_profileImage',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey[400],
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: const Color(0xFFD6D588),
                              ),
                            );
                          },
                        )
                      : Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                _namaLengkap,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _email,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                _alamat,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // Menu Items
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
                        initialAlamat: _alamat,
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
                title: l10n.history,
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
                title: l10n.help,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BantuanPage(),
                    ),
                  );
                },
              ),

              _buildMenuItem(
                context,
                icon: Icons.info_outline,
                title: l10n.aboutUs,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TentangKamiPage(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _showLogoutDialog(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout,
                              color: Color(0xFFD6D588),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.logout,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFD6D588),
                              ),
                            ),
                          ],
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
    final l10n = AppLocalizations.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            l10n.logout,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(l10n.logoutConfirm),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
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
              child: Text(
                l10n.logout,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}