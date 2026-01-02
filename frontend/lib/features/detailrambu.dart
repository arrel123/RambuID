import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/riwayat_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';

class DetailRambuScreen extends StatefulWidget {
  final Map<String, dynamic> rambu;
  final int userId; // --- TAMBAHAN PENTING: Menerima UserId dari EdukasiPage ---

  const DetailRambuScreen({
    super.key, 
    required this.rambu, 
    this.userId = 0, // Default nilai 0 jika tidak dikirim
  });

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
    _saveToRiwayat();
  }

  Future<void> _saveToRiwayat() async {
    try {
      final nama = widget.rambu['nama'] ?? 'Rambu Tanpa Nama';
      final kategori = widget.rambu['kategori'] ?? 'Tidak Diketahui';
      final gambarUrl = _getImageUrl();
      
      // Simpan ke riwayat
      // Pastikan service Anda menerima parameter yang sesuai.
      // Jika RiwayatService.addRiwayat butuh userId, tambahkan widget.userId di parameter pertama.
      await RiwayatService.addRiwayat(nama, kategori, gambarUrl);
      
    } catch (e) {
      debugPrint('❌ Gagal menyimpan riwayat: $e');
    }
  }

  void _initTts() async {
    flutterTts = FlutterTts();
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
    
    await flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers
        ],
        IosTextToSpeechAudioMode.defaultMode
    );

    flutterTts.setStartHandler(() {
      setState(() => isSpeaking = true);
    });

    flutterTts.setCompletionHandler(() {
      setState(() => isSpeaking = false);
    });

    flutterTts.setErrorHandler((msg) {
      setState(() => isSpeaking = false);
    });
  }

  Future<void> _playAudioDescription() async {
    if (isSpeaking) {
      await _stopSpeaking();
      return;
    }

    try {
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final currentLang = languageProvider.locale.languageCode;
      
      String namaRambu, deskripsi, textToSpeak;

      if (currentLang == 'en') {
        namaRambu = (widget.rambu['nama_en'] ?? widget.rambu['nama'] ?? '').replaceAll('\n', ' ');
        deskripsi = widget.rambu['deskripsi_en'] ?? widget.rambu['deskripsi'] ?? 'No description available';
        textToSpeak = "This is $namaRambu sign. $deskripsi";
        await flutterTts.setLanguage("en-US");
      } else {
        namaRambu = (widget.rambu['nama'] ?? '').replaceAll('\n', ' ');
        deskripsi = widget.rambu['deskripsi'] ?? 'Tidak ada deskripsi';
        textToSpeak = "Rambu $namaRambu, yaitu $deskripsi";
        await flutterTts.setLanguage("id-ID");
      }

      await flutterTts.speak(textToSpeak);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memutar audio: $e'), duration: const Duration(seconds: 1)),
      );
    }
  }

  Future<void> _stopSpeaking() async {
    await flutterTts.stop();
    setState(() => isSpeaking = false);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

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
    final l10n = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLang = languageProvider.locale.languageCode;

    String nama, kategori, deskripsi;

    if (currentLang == 'en') {
      nama = widget.rambu['nama_en'] ?? widget.rambu['nama'] ?? 'No Name';
      String rawCat = widget.rambu['kategori_en'] ?? widget.rambu['kategori'] ?? '-';
      kategori = rawCat; 
      deskripsi = widget.rambu['deskripsi_en'] ?? widget.rambu['deskripsi'] ?? 'No description available';
    } else {
      nama = widget.rambu['nama'] ?? 'Tanpa Nama';
      kategori = widget.rambu['kategori'] ?? '-';
      deskripsi = widget.rambu['deskripsi'] ?? 'Tidak ada deskripsi';
    }

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
        title: Text(
          l10n.translate('sign_detail'),
          style: const TextStyle(
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

              Container(
                width: 180, 
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => 
                              const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        )
                      : const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 30),

              Text(
                l10n.translate('information'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                  fontFamily: 'Poppins',
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection(
                      title: l10n.translate('sign_name'),
                      content: nama.replaceAll('\n', ' ').toUpperCase(),
                      isTitle: true,
                    ),
                    const Divider(height: 30),
                    _buildInfoSection(
                      title: l10n.translate('sign_type'),
                      content: kategori.isNotEmpty 
                          ? '${kategori[0].toUpperCase()}${kategori.substring(1)}'
                          : '-',
                    ),
                    const SizedBox(height: 20),
                    _buildInfoSection(
                      title: l10n.translate('information'),
                      content: deskripsi,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _playAudioDescription,
                  icon: Icon(
                    isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_rounded,
                    color: Colors.black87,
                    size: 26,
                  ),
                  label: Text(
                    isSpeaking ? l10n.translate('stop') : l10n.translate('listen'),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSpeaking ? Colors.grey[300] : const Color(0xFFD6D588),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
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

  Widget _buildInfoSection({required String title, required String content, bool isTitle = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.5,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: TextStyle(
            fontSize: isTitle ? 18 : 15,
            fontWeight: isTitle ? FontWeight.bold : FontWeight.w400,
            color: Colors.black87,
            height: 1.4,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}