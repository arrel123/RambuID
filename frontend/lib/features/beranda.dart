import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class KatalogRambuScreen extends StatelessWidget {
  // 🔥 TAMBAHKAN INI: Variabel untuk menampung data user
  final int userId;
  final String username;

  const KatalogRambuScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  void _navigateToEdukasi(BuildContext context, String category) {
    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {
        'userId': userId,     // ✅ GUNAKAN VARIABEL userId YANG BENAR
        'username': username, // ✅ GUNAKAN VARIABEL username YANG BENAR
        'initialIndex': 1,    // Pindah ke Tab EDUKASI
        'initialCategory': category,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo_rambuid.png',
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'RambuID',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9CAF4C),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.trafficSignsCatalog,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                        // Padding bawah agar tidak tertutup navbar
                        padding: const EdgeInsets.only(bottom: 100),
                        children: [
                          _buildMenuCard(
                            context: context,
                            icon: Icons.do_not_disturb,
                            label: l10n.translate('category_prohibition'),
                            color: const Color(0xFFE53935),
                            iconColor: Colors.white,
                            onTap: () => _navigateToEdukasi(context, 'Larangan'),
                          ),
                          _buildMenuCard(
                            context: context,
                            icon: Icons.warning,
                            label: l10n.translate('category_warning'),
                            color: const Color(0xFFFFC107),
                            iconColor: Colors.white,
                            onTap: () => _navigateToEdukasi(context, 'Peringatan'),
                          ),
                          _buildMenuCard(
                            context: context,
                            icon: Icons.arrow_forward,
                            label: l10n.translate('category_command'),
                            color: const Color(0xFF1E88E5),
                            iconColor: Colors.white,
                            onTap: () => _navigateToEdukasi(context, 'Perintah'),
                          ),
                          _buildMenuCard(
                            context: context,
                            icon: Icons.arrow_upward,
                            label: l10n.translate('category_direction'),
                            color: const Color(0xFF00897B),
                            iconColor: Colors.white,
                            onTap: () => _navigateToEdukasi(context, 'Petunjuk'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 38),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
