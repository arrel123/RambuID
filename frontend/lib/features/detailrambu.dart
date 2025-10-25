import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

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

    // Konfigurasi TTS - Kecepatan diubah menjadi 1.0 (normal/lebih cepat)
    flutterTts.setLanguage("id-ID"); // Bahasa Indonesia
    flutterTts.setSpeechRate(
      1.0,
    ); // ⭐ DIUBAH: Kecepatan bicara menjadi 1.0 (normal)
    flutterTts.setPitch(1.0); // Nada suara (0.5 - 2.0)
    flutterTts.setVolume(1.0); // Volume (0.0 - 1.0)

    // Handler untuk event TTS
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
      // ⭐ DIUBAH: Format "Nama Rambu" yaitu "Keterangan"
      String namaRambu = widget.rambu['title'].replaceAll('\n', ' ');
      String textToSpeak = "$namaRambu yaitu ${widget.rambu['description']}";

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFD6D588),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            _stopSpeaking(); // Stop TTS ketika kembali
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

              // Rambu Image
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
                      child: Image.asset(
                        widget.rambu['image'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // KETERANGAN Title
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
                      title: 'NAMA RAMBU',
                      content: widget.rambu['title']
                          .replaceAll('\n', ' ')
                          .toUpperCase(),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoSection(
                      title: 'JENIS RAMBU',
                      content: widget.rambu['category'],
                    ),
                    const SizedBox(height: 20),
                    _buildInfoSection(
                      title: 'KETERANGAN',
                      content: widget.rambu['description'],
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
