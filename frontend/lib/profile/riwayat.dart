import 'package:flutter/material.dart';

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title
                  const Expanded(
                    child: Text(
                      'Riwayat',
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

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // September - First Group
                  _buildMonthHeader('September', '18/09/2025'),
                  const SizedBox(height: 12),
                  _buildHistoryItem(
                    icon: 'assets/images/dilarang_belok_kiri.png',
                    title: 'Dilarang Belok Kiri',
                  ),
                  const SizedBox(height: 12),
                  _buildHistoryItem(
                    icon: 'assets/images/jalan_tidak_rata.png',
                    title: 'Hati-Hati Jalan Licin',
                  ),
                  const SizedBox(height: 12),
                  _buildHistoryItem(
                    icon: 'assets/images/dilarang_parkir.png',
                    title: 'Dilarang Parkir',
                  ),
                  const SizedBox(height: 12),
                  _buildHistoryItem(
                    icon: 'assets/images/dilarang_putar_balik.png',
                    title: 'Dilarang Putar Balik',
                  ),
                  const SizedBox(height: 24),

                  // September - Second Group
                  _buildMonthHeader('September', '16/09/2025'),
                  const SizedBox(height: 12),
                  _buildHistoryItem(
                    icon: 'assets/images/jalan_tidak_rata.png',
                    title: 'Jalan Tidak Rata',
                  ),
                  const SizedBox(height: 12),
                  _buildHistoryItem(
                    icon: 'assets/images/jalan_tidak_rata.png',
                    title: 'Jalan Mananjak Landai',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(String month, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          month,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(date, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildHistoryItem({required String icon, required String title}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(icon, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
