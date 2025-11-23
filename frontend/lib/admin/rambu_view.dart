import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';

// --- Model Data Rambu ---
class Rambu {
  final int id;
  final String nama;
  final String deskripsi;
  final String? imageUrl;
  final String kategori;

  Rambu({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.imageUrl,
    required this.kategori,
  });

  factory Rambu.fromJson(Map<String, dynamic> json) {
    // Helper untuk mendapatkan full URL gambar
    String? getFullImageUrl(String? url) {
      if (url == null || url.isEmpty) return null;
      // Jika sudah full URL, return as is
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
      // Jika path relatif, gabungkan dengan baseUrl
      final baseUrl = ApiService.baseUrl;
      // Pastikan path dimulai dengan /
      final path = url.startsWith('/') ? url : '/$url';
      return '$baseUrl$path';
    }

    return Rambu(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      nama: json['nama']?.toString() ?? '-',
      deskripsi: json['deskripsi']?.toString() ?? '',
      imageUrl: getFullImageUrl(json['gambar_url']?.toString()),
      kategori: json['kategori']?.toString() ?? 'larangan',
    );
  }

  // Helper untuk mendapatkan label kategori
  String get kategoriLabel {
    switch (kategori.toLowerCase()) {
      case 'larangan':
        return 'Larangan';
      case 'peringatan':
        return 'Peringatan';
      case 'petunjuk':
        return 'Petunjuk';
      case 'perintah':
        return 'Perintah';
      default:
        return kategori;
    }
  }

  // Helper untuk mendapatkan warna kategori
  Color get kategoriColor {
    switch (kategori.toLowerCase()) {
      case 'larangan':
        return Colors.red;
      case 'peringatan':
        return Colors.orange;
      case 'petunjuk':
        return Colors.blue;
      case 'perintah':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class RambuView extends StatefulWidget {
  const RambuView({super.key});

  @override
  State<RambuView> createState() => _RambuViewState();
}

class _RambuViewState extends State<RambuView> {
  final List<Rambu> _rambuList = [];
  List<Rambu> _filteredRambuList = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterRambu);
    _loadRambuList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRambuList() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.getRambuList();
    if (result['success'] == true) {
      final List<dynamic> data = result['data'] ?? [];
      final loaded = data
          .map((item) => Rambu.fromJson(item as Map<String, dynamic>))
          .toList();
      setState(() {
        _rambuList
          ..clear()
          ..addAll(loaded);
        _filteredRambuList = List.from(_rambuList);
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Gagal memuat data rambu';
        _isLoading = false;
      });
    }
  }

  void _showSnack(String message, {Color color = Colors.green}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _filterRambu() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRambuList = _rambuList.where((rambu) {
        return rambu.nama.toLowerCase().contains(query) ||
            rambu.deskripsi.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _tambahDataRambu() async {
    final result = await showDialog<RambuFormResult>(
      context: context,
      builder: (context) => const _RambuEditDialog(),
    );

    if (result != null) {
      await _handleCreateRambu(result);
    }
  }

  Future<void> _editDataRambu(Rambu rambuToEdit) async {
    final result = await showDialog<RambuFormResult>(
      context: context,
      builder: (context) => _RambuEditDialog(rambuToEdit: rambuToEdit),
    );

    if (result != null) {
      await _handleUpdateRambu(rambuToEdit, result);
    }
  }

  Future<void> _handleCreateRambu(RambuFormResult result) async {
    if (result.imageFile == null) {
      _showSnack('Silakan pilih gambar terlebih dahulu', color: Colors.red);
      return;
    }

    final response = await ApiService.createRambu(
      nama: result.nama,
      deskripsi: result.deskripsi,
      kategori: result.kategori,
      gambar: result.imageFile!,
    );

    if (response['success'] == true) {
      _showSnack('Rambu berhasil ditambahkan');
      await _loadRambuList();
    } else {
      _showSnack(
        response['message'] ?? 'Gagal menambahkan rambu',
        color: Colors.red,
      );
    }
  }

  Future<void> _handleUpdateRambu(
    Rambu existing,
    RambuFormResult result,
  ) async {
    final response = await ApiService.updateRambu(
      id: existing.id,
      nama: result.nama,
      deskripsi: result.deskripsi,
      kategori: result.kategori,
      gambar: result.imageFile,
    );

    if (response['success'] == true) {
      _showSnack('Rambu berhasil diperbarui');
      await _loadRambuList();
    } else {
      _showSnack(
        response['message'] ?? 'Gagal memperbarui rambu',
        color: Colors.red,
      );
    }
  }

  Future<void> _hapusDataRambu(Rambu rambuToDelete) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Rambu?'),
        content: Text('Anda yakin ingin menghapus "${rambuToDelete.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final response = await ApiService.deleteRambu(rambuToDelete.id);
      if (response['success'] == true) {
        _showSnack('Rambu berhasil dihapus');
        await _loadRambuList();
      } else {
        _showSnack(
          response['message'] ?? 'Gagal menghapus rambu',
          color: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width <= 650;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daftar Rambu',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Search Bar & Tombol Tambah
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildAddButton(),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: _buildSearchBar()),
                      const SizedBox(width: 16),
                      _buildAddButton(),
                    ],
                  ),
            const SizedBox(height: 24),

            // Tabel Data dengan Custom Table
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _errorMessage != null
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red[400]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadRambuList,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : _filteredRambuList.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey,
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Belum ada data rambu',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          horizontalMargin: 24,
                          columnSpacing: 32,
                          headingRowHeight: 56,
                          dataRowHeight: 80,
                          headingRowColor: MaterialStateProperty.all(
                            Colors.grey[50],
                          ),
                          dividerThickness: 1,
                          columns: const [
                            DataColumn(
                              label: Text(
                                'GAMBAR',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'NAMA RAMBU',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'KATEGORI',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: SizedBox(
                                width: 400,
                                child: Text(
                                  'DESKRIPSI',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'AKSI',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                          rows: _filteredRambuList.map((rambu) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[100],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child:
                                          rambu.imageUrl != null &&
                                              rambu.imageUrl!.isNotEmpty
                                          ? Image.network(
                                              rambu.imageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
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
                                ),
                                DataCell(
                                  Text(
                                    rambu.nama,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: rambu.kategoriColor.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: rambu.kategoriColor.withOpacity(
                                          0.3,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
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
                                        Text(
                                          rambu.kategoriLabel,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: rambu.kategoriColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    width: 400,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      rambu.deskripsi,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        height: 1.4,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => _editDataRambu(rambu),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFFDD835,
                                          ),
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Edit',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: Colors.grey[600],
                                          size: 22,
                                        ),
                                        onPressed: () => _hapusDataRambu(rambu),
                                        tooltip: 'Hapus',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Mencari...',
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFFDD835), width: 2),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.add, color: Colors.black, size: 20),
      label: const Text(
        'Tambah Data Rambu',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFDD835),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _tambahDataRambu,
    );
  }
}

// --- DIALOG UNTUK TAMBAH/EDIT RAMBU ---
class _RambuEditDialog extends StatefulWidget {
  final Rambu? rambuToEdit;

  const _RambuEditDialog({this.rambuToEdit});

  @override
  State<_RambuEditDialog> createState() => _RambuEditDialogState();
}

class _RambuEditDialogState extends State<_RambuEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late TextEditingController _deskripsiController;
  Uint8List? _imageBytes;
  String? _imageName;
  XFile? _pickedImageFile;
  String _selectedKategori = 'larangan';

  // List kategori yang tersedia
  final List<String> _kategoriList = [
    'larangan',
    'peringatan',
    'petunjuk',
    'perintah',
  ];

  // Map kategori ke label
  final Map<String, String> _kategoriLabels = {
    'larangan': 'Larangan',
    'peringatan': 'Peringatan',
    'petunjuk': 'Petunjuk',
    'perintah': 'Perintah',
  };

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(
      text: widget.rambuToEdit?.nama ?? '',
    );
    _deskripsiController = TextEditingController(
      text: widget.rambuToEdit?.deskripsi ?? '',
    );
    _selectedKategori = widget.rambuToEdit?.kategori ?? 'larangan';
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      // Pilih gambar dari gallery atau camera
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        // Baca file sebagai bytes untuk preview
        final bytes = await pickedFile.readAsBytes();

        if (mounted) {
          setState(() {
            _pickedImageFile = pickedFile;
            _imageBytes = bytes;
            _imageName = pickedFile.name;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final bool isEditing = widget.rambuToEdit != null;

      // Validasi untuk tambah data baru harus ada gambar
      if (!isEditing && _pickedImageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan pilih gambar terlebih dahulu'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Navigator.pop(
        context,
        RambuFormResult(
          nama: _namaController.text,
          deskripsi: _deskripsiController.text,
          kategori: _selectedKategori,
          imageFile: _pickedImageFile,
        ),
      );
    }
  }

  Widget _buildImagePreview() {
    // Jika ada gambar baru yang dipilih, tampilkan preview
    if (_imageBytes != null && _imageBytes!.isNotEmpty) {
      return Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Image.memory(
                _imageBytes!,
                fit: BoxFit.cover,
                width: 280,
                height: 280,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 50),
                        SizedBox(height: 12),
                        Text(
                          'Gagal memuat gambar',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Badge "Preview"
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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

    // Jika sedang edit dan ada gambar existing, tampilkan gambar existing
    if (widget.rambuToEdit?.imageUrl != null &&
        widget.rambuToEdit!.imageUrl!.isNotEmpty) {
      return Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Image.network(
                widget.rambuToEdit!.imageUrl!,
                fit: BoxFit.cover,
                width: 280,
                height: 280,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 50,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Gagal memuat gambar',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Badge "Gambar Saat Ini"
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Gambar Saat Ini',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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

    // Jika tidak ada gambar sama sekali
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, color: Colors.grey, size: 64),
          SizedBox(height: 16),
          Text(
            'Belum Ada Gambar',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Klik tombol "Pilih Gambar" di bawah',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.rambuToEdit != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'Edit Rambu' : 'Tambah Rambu Baru',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Field Nama Rambu
              const Text(
                'Nama Rambu',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nama rambu...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),

              // Field Deskripsi
              const Text(
                'Deskripsi',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan deskripsi rambu...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 3,
                validator: (value) =>
                    value!.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),

              // Field Kategori
              const Text(
                'Kategori',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                decoration: const InputDecoration(
                  hintText: 'Pilih kategori...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _kategoriList.map((kategori) {
                  return DropdownMenuItem(
                    value: kategori,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getKategoriColor(kategori),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(_kategoriLabels[kategori] ?? kategori),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedKategori = value;
                    });
                  }
                },
                validator: (value) => value == null ? 'Pilih kategori' : null,
              ),
              const SizedBox(height: 20),

              // Section Gambar
              const Text(
                'Gambar Rambu',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),

              // Preview Gambar - Lebih besar dan jelas
              Center(child: _buildImagePreview()),
              const SizedBox(height: 16),

              // Info file yang dipilih
              if (_imageName != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'File dipilih:',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _imageName!,
                              style: TextStyle(
                                color: Colors.green[900],
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              if (_imageName != null) const SizedBox(height: 16),

              // Tombol Pilih/Ganti Gambar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file, size: 20),
                  label: Text(
                    _imageBytes != null
                        ? 'Ganti Gambar'
                        : isEditing
                        ? 'Ganti Gambar'
                        : 'Pilih Gambar',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDD835),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Petunjuk
              Center(
                child: Text(
                  isEditing
                      ? 'Pilih gambar baru untuk mengganti gambar saat ini'
                      : 'Pilih gambar untuk rambu baru',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFDD835),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(isEditing ? 'Simpan Perubahan' : 'Tambah Rambu'),
        ),
      ],
      actionsPadding: const EdgeInsets.all(20),
    );
  }

  Color _getKategoriColor(String kategori) {
    switch (kategori.toLowerCase()) {
      case 'larangan':
        return Colors.red;
      case 'peringatan':
        return Colors.orange;
      case 'petunjuk':
        return Colors.blue;
      case 'perintah':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class RambuFormResult {
  final String nama;
  final String deskripsi;
  final String kategori;
  final XFile? imageFile;

  RambuFormResult({
    required this.nama,
    required this.deskripsi,
    required this.kategori,
    this.imageFile,
  });
}
