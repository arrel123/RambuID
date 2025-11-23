import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'rambu_view.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
class _RambuPreviewCard extends StatefulWidget {
  final VoidCallback onViewAll;
  const _RambuPreviewCard({required this.onViewAll});

  @override
  State<_RambuPreviewCard> createState() => _RambuPreviewCardState();
}

class _RambuPreviewCardState extends State<_RambuPreviewCard> {
  List<Rambu> _rambuList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRambuPreview();
  }

  Future<void> _loadRambuPreview() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getRambuList();
      if (result['success'] == true) {
        final List<dynamic> data = result['data'] ?? [];
        final loaded = data
            .map((item) => Rambu.fromJson(item as Map<String, dynamic>))
            .toList();
        setState(() {
          // Ambil maksimal 4 rambu teratas untuk preview
          _rambuList = loaded.take(4).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Gagal memuat data rambu';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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

            // Tampilkan loading, error, atau data rambu
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[400]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadRambuPreview,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              )
            else if (_rambuList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada data rambu',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ..._rambuList.map((rambu) {
                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          rambu.imageUrl != null && rambu.imageUrl!.isNotEmpty
                          ? Image.network(
                              rambu.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                  ),
                            )
                          : const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                    ),
                  ),
                  title: Text(
                    rambu.nama,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: rambu.kategoriColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(rambu.kategoriLabel),
                    ],
                  ),
                );
              }).toList(),

            const SizedBox(height: 16),

            // 🔹 REQ 3: Tombol untuk pindah halaman
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: widget.onViewAll, // Panggil callback-nya
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
