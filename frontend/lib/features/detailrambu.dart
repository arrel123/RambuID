import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/api_service.dart'; // Import API Service untuk URL

class DetailRambuScreen extends StatefulWidget {
  final Map<String, dynamic> rambu;

  const DetailRambuScreen({super.key, required this.rambu});

  @override
  State<DetailRambuScreen> createState() => _DetailRambuScreenState();
}

class _DetailRambuScreenState extends State<DetailRambuScreen> {
  late FlutterTts flutterTts;
  bool isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() {
    flutterTts = FlutterTts();
    flutterTts.setLanguage("id-ID");
    flutterTts.setSpeechRate(1.0);
    flutterTts.setPitch(1.0);
    flutterTts.setVolume(1.0);

    flutterTts.setStartHandler(() {
      setState(() {
        isSpeaking = true;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        isSpeaking = false;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        isSpeaking = false;
      });
      debugPrint("TTS Error: $msg");
    });
  }

  Future<void> _playAudioDescription() async {
    if (isSpeaking) {
      await _stopSpeaking();
      return;
    }

    try {
      // Ubah akses key sesuai database: 'nama' dan 'deskripsi'
      String namaRambu = (widget.rambu['nama'] ?? '').replaceAll('\n', ' ');
      String deskripsi = widget.rambu['deskripsi'] ?? 'Tidak ada deskripsi';
      String textToSpeak = "Rambu $namaRambu, yaitu $deskripsi";

      await flutterTts.speak(textToSpeak);
    } catch (e) {
      debugPrint("Error speaking: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memutar audio: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _stopSpeaking() async {
    await flutterTts.stop();
    setState(() {
      isSpeaking = false;
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  // Helper untuk mendapatkan URL gambar
  String _getImageUrl() {
    String? partialUrl = widget.rambu['gambar_url'];
    if (partialUrl == null || partialUrl.isEmpty) return '';
    if (partialUrl.startsWith('/')) {
      return '${ApiService.baseUrl}$partialUrl';
    }
    return partialUrl;
  }

  @override
  Widget build(BuildContext context) {
    // Ambil data menggunakan key dari database
    final nama = widget.rambu['nama'] ?? 'Tanpa Nama';
    final kategori = widget.rambu['kategori'] ?? '-';
    final deskripsi = widget.rambu['deskripsi'] ?? 'Tidak ada deskripsi';
    final imageUrl = _getImageUrl();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFD6D588),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            _stopSpeaking();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Detail Rambu',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Rambu Image (Sekarang pakai Network)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE53935),
                        width: 8,
                      ),
                    ),
                    child: ClipOval(
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => 
                                  const Icon(Icons.broken_image, size: 50),
                            )
                          : const Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'KETERANGAN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 1.5,
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 24),

              // Detail Information
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection(
                      title: 'NAMA RAMBU',
                      content: nama.replaceAll('\n', ' ').toUpperCase(),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoSection(
                      title: 'JENIS RAMBU',
                      // Capitalize huruf pertama kategori
                      content: kategori.isNotEmpty 
                          ? '${kategori[0].toUpperCase()}${kategori.substring(1)}'
                          : '-',
                    ),
                    const SizedBox(height: 20),
                    _buildInfoSection(
                      title: 'KETERANGAN',
                      content: deskripsi,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Dengarkan Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _playAudioDescription,
                  icon: Icon(
                    isSpeaking ? Icons.volume_off : Icons.volume_up,
                    color: Colors.black87,
                    size: 24,
                  ),
                  label: Text(
                    isSpeaking ? 'Berhenti' : 'Dengarkan',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSpeaking
                        ? Colors.grey
                        : const Color(0xFFD6D588),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            height: 1.5,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}