import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Diperlukan untuk Timer
import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';

class BahasaPage extends StatelessWidget {
  const BahasaPage({super.key});

  // --- FUNGSI POP-UP GAYA LOGIN PAGE (PENGGANTI SNACKBAR) ---
  void _showSuccessDialog(BuildContext context, String languageName) {
    showDialog(
      context: context,
      barrierDismissible: false, // User tidak bisa klik luar
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Icon Checklis Biru
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF64B5F6), // Warna Biru Muda
                size: 60,
              ),
              const SizedBox(height: 16),
              
              // 2. Judul Besar
              const Text(
                'Berhasil Diganti',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF555555), // Abu Gelap
                ),
              ),
              const SizedBox(height: 10),
              
              // 3. Subtitle
              Text(
                'Bahasa diubah ke $languageName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF777777), // Abu Terang
                ),
              ),
            ],
          ),
        );
      },
    );

    // Timer 2 Detik: Tutup Pop-up Otomatis
    Future.delayed(const Duration(seconds: 2), () {
      // Cek apakah context masih valid sebelum pop
      // Kita menggunakan Navigator.of(context, rootNavigator: true) untuk memastikan dialog tertutup
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLanguage = languageProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: Color(0xFFD6D588)),
              child: Row(
                children: [
                  // Back Button
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title
                  Expanded(
                    child: Text(
                      l10n.language,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Language Options
            Expanded(
              child: Column(
                children: [
                  _buildLanguageOption(
                    context: context,
                    code: 'en',
                    title: 'ENGLISH',
                    subtitle: '(EN)',
                    isSelected: currentLanguage == 'en',
                  ),
                  _buildDivider(),
                  _buildLanguageOption(
                    context: context,
                    code: 'id',
                    title: 'BAHASA INDONESIA',
                    subtitle: '(Default)',
                    isSelected: currentLanguage == 'id',
                  ),
                  _buildDivider(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String code,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          _showLanguageConfirmationDialog(context, code);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        color: Colors.white,
        child: Row(
          children: [
            // Checkmark
            SizedBox(
              width: 24,
              child: isSelected
                  ? const Icon(Icons.check, color: Color(0xFFD6D588), size: 20)
                  : const SizedBox(),
            ),
            const SizedBox(width: 16),
            // Language Text
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    TextSpan(
                      text: ' $subtitle',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[600],
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

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  void _showLanguageConfirmationDialog(BuildContext context, String newLanguage) {
    final l10n = AppLocalizations.of(context);
    final languageName = newLanguage == 'en' ? l10n.english : l10n.indonesian;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            l10n.changeLanguage,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '${l10n.confirmLanguageChange} $languageName?',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                l10n.cancel,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                // 1. Ubah Bahasa
                await Provider.of<LanguageProvider>(context, listen: false)
                    .changeLanguage(newLanguage);
                
                // 2. Tutup Dialog Konfirmasi (dialogContext)
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                
                // 3. Tampilkan Pop-up Sukses (Gaya Login)
                // Menggunakan 'context' utama (bukan dialogContext)
                if (context.mounted) {
                  _showSuccessDialog(context, languageName);
                }
              },
              child: Text(
                l10n.yes,
                style: const TextStyle(
                  color: Color(0xFFD6D588),
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