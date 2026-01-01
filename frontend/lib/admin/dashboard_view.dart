import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'rambu_view.dart';

class DashboardView extends StatefulWidget {
  final VoidCallback onViewAllRambu;

  const DashboardView({super.key, required this.onViewAllRambu});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _totalUsers = 0;
  int _totalRambu = 0;
  bool _isLoading = true;

  // REVISI: Variabel _errorMessage dihapus karena tidak digunakan di UI summary

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.getStatistics();

      if (result['success'] == true) {
        final Map<String, dynamic> stats = result['data'];
        if (mounted) {
          setState(() {
            _totalUsers = stats['total_users'] ?? 0;
            _totalRambu = stats['total_rambu'] ?? 0;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('Gagal memuat statistik: ${result['message']}');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Terjadi kesalahan: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width <= 800;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- KARTU SUMMARY ---
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
                    const SizedBox(width: 32),
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

          // --- KARTU DAFTAR RAMBU (CUSTOM TABLE FULL WIDTH) ---
          _RambuPreviewCard(onViewAll: widget.onViewAllRambu),
        ],
      ),
    );
  }
}

// --- WIDGET HELPER ---
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            isLoading
                ? const SizedBox(
                    height: 36,
                    width: 36,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ],
        ),
      ),
    );
  }
}

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
        if (mounted) {
          setState(() {
            _rambuList = loaded.take(5).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = result['message'] ?? 'Gagal memuat data rambu';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width <= 800;

    return Container(
      width: double.infinity, // Pastikan container full width
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            // 1. JUDUL CENTER
            const Center(
              child: Text(
                'Daftar Rambu',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 2. SEARCH & BUTTON
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildAddButton(context),
                    ],
                  )
                : Row(
                    children: [
                      SizedBox(width: 300, child: _buildSearchBar()),
                      const Spacer(),
                      _buildAddButton(context),
                    ],
                  ),

            const SizedBox(height: 32),

            // 3. HEADER TABEL (CUSTOM ROW UNTUK FULL WIDTH & CENTER)
            // Menggunakan Row dengan Expanded agar memenuhi lebar container
            if (!_isLoading && _errorMessage == null && _rambuList.isNotEmpty)
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
                ),
                child: const Row(
                  children: [
                    Expanded(flex: 2, child: Center(child: Text("Gambar", style: TextStyle(fontWeight: FontWeight.bold)))),
                    Expanded(flex: 3, child: Center(child: Text("Nama Rambu", style: TextStyle(fontWeight: FontWeight.bold)))),
                    Expanded(flex: 2, child: Center(child: Text("Jenis Rambu", style: TextStyle(fontWeight: FontWeight.bold)))),
                    if(true) // Bisa di-hide di mobile jika perlu
                      Expanded(flex: 4, child: Center(child: Text("Deskripsi Rambu", style: TextStyle(fontWeight: FontWeight.bold)))),
                    Expanded(flex: 2, child: Center(child: Text("Aksi", style: TextStyle(fontWeight: FontWeight.bold)))),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // 4. ISI TABEL (DATA ROWS)
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Center(
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)))
            else if (_rambuList.isEmpty)
              const Center(child: Text("Belum ada data rambu"))
            else
              Column(
                children: _rambuList.map((rambu) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // GAMBAR (Center)
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: rambu.imageUrl != null
                                  ? Image.network(
                                      rambu.imageUrl!,
                                      fit: BoxFit.contain,
                                    )
                                  : const Icon(Icons.image_not_supported,
                                      color: Colors.grey),
                            ),
                          ),
                        ),
                        // NAMA (Center)
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Text(
                              rambu.nama,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        // JENIS (Center)
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              rambu.kategoriLabel,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        // DESKRIPSI (Align Left/Center) - Teks panjang sebaiknya start/center
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              rambu.deskripsi,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[800], fontSize: 13),
                              textAlign: TextAlign.left, // Deskripsi lebih rapi rata kiri
                            ),
                          ),
                        ),
                        // AKSI (Center)
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: widget.onViewAll,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFDD835),
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 0),
                                  minimumSize: const Size(0, 32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text('Edit',
                                    style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: widget.onViewAll,
                                child: Icon(Icons.delete,
                                    color: Colors.grey[700], size: 20),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Mencari',
        hintStyle:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: widget.onViewAll,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Tambah Data Rambu'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFDD835),
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}