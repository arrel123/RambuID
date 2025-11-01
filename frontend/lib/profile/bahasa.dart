import 'package:flutter/material.dart';

class BahasaPage extends StatefulWidget {
  const BahasaPage({super.key});

  @override
  State<BahasaPage> createState() => _BahasaPageState();
}

class _BahasaPageState extends State<BahasaPage> {
  String selectedLanguage = 'id'; // 'id' for Indonesian, 'en' for English

  @override
  Widget build(BuildContext context) {
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
                  const Expanded(
                    child: Text(
                      'Bahasa',
                      style: TextStyle(
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
                    code: 'en',
                    title: 'ENGLISH',
                    subtitle: '(EN)',
                  ),
                  _buildDivider(),
                  _buildLanguageOption(
                    code: 'id',
                    title: 'BAHASA INDONESIA',
                    subtitle: '(Default)',
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
    required String code,
    required String title,
    required String subtitle,
  }) {
    final bool isSelected = selectedLanguage == code;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          _showLanguageConfirmationDialog(code);
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

  void _showLanguageConfirmationDialog(String newLanguage) {
    final String languageName = newLanguage == 'en'
        ? 'English'
        : 'Bahasa Indonesia';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Ganti Bahasa',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin mengubah bahasa ke $languageName?',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedLanguage = newLanguage;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bahasa berhasil diubah ke $languageName'),
                    backgroundColor: const Color(0xFF8B9C4A),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Ya',
                style: TextStyle(
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
