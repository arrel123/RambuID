import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardView extends StatefulWidget {
  // 🔹 REQ 3: Fungsi callback untuk pindah halaman
  final VoidCallback onViewAllRambu;

  const DashboardView({super.key, required this.onViewAllRambu});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _totalUsers = 0;
  int _totalRambu = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getStatistics();

      print('🔵 Dashboard: Statistics result = $result');

      if (result['success'] == true) {
        final Map<String, dynamic> stats = result['data'];
        setState(() {
          _totalUsers = stats['total_users'] ?? 0;
          _totalRambu = stats['total_rambu'] ?? 0;
          _isLoading = false;
        });
        print(
          '🔵 Dashboard: Total Users = $_totalUsers, Total Rambu = $_totalRambu',
        );
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Gagal memuat statistik';
          _isLoading = false;
        });
        print('🔴 Dashboard: Error = $_errorMessage');
      }
    } catch (e) {
      print('🔴 Dashboard: Exception = $e');
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width <= 650;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kartu Summary (Total Pengguna & Rambu)
          isMobile
              ? Column(
                  children: [
                    _SummaryCard(
                      title: 'Total Pengguna',
                      value: _isLoading ? '...' : _totalUsers.toString(),
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),
                    _SummaryCard(
                      title: 'Total Rambu Terpasang',
                      value: _isLoading ? '...' : _totalRambu.toString(),
                      isLoading: _isLoading,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total Pengguna',
                        value: _isLoading ? '...' : _totalUsers.toString(),
                        isLoading: _isLoading,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Total Rambu Terpasang',
                        value: _isLoading ? '...' : _totalRambu.toString(),
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),

          const SizedBox(height: 32),

          // 🔹 REQ 2 & 3: Preview Daftar Rambu
          _RambuPreviewCard(onViewAll: widget.onViewAllRambu),
        ],
      ),
    );
  }
}

// --- WIDGET: _SummaryCard (Helper) ---
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isLoading;
  const _SummaryCard({
    required this.title,
    required this.value,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            isLoading
                ? const SizedBox(
                    height: 36,
                    width: 36,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET: _RambuPreviewCard (Helper) ---
class _RambuPreviewCard extends StatelessWidget {
  final VoidCallback onViewAll;
  const _RambuPreviewCard({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Rambu (Preview)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Ini hanya preview, Anda bisa ganti dengan 3 data rambu teratas
            ListTile(
              leading: Image.asset('/images/dilarang_parkir.png', width: 40),
              title: const Text('Dilarang Parkir'),
              subtitle: const Text('Larangan'),
            ),
            ListTile(
              leading: Image.asset('/images/tikungan.png', width: 40),
              title: const Text('Tikungan Tajam'),
              subtitle: const Text('Peringatan'),
            ),
            ListTile(
              leading: Image.asset('/images/wajib_kiri.png', width: 40),
              title: const Text('Wajib Belok Kiri'),
              subtitle: const Text('Perintah'),
            ),
            ListTile(
              leading: Image.asset('/images/petunjuk.jpg', width: 40),
              title: const Text('Petunjuk Arah'),
              subtitle: const Text('Petunjuk'),
            ),
            const SizedBox(height: 16),

            // 🔹 REQ 3: Tombol untuk pindah halaman
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onViewAll, // Panggil callback-nya
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent[700],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Lihat Semua Rambu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
