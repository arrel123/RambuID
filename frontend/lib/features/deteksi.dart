import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../services/api_service.dart';      // Import API Service
import '../services/riwayat_service.dart';  // Import Riwayat Service
import '../profile/riwayat.dart';           // Halaman Riwayat

class DeteksiPage extends StatefulWidget {
  const DeteksiPage({super.key});

  @override
  State<DeteksiPage> createState() => _DeteksiPageState();
}

class _DeteksiPageState extends State<DeteksiPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isProcessing = false;
  File? _capturedImage;
  final ImagePicker _picker = ImagePicker();
  int _selectedCameraIndex = 0;

  // --- VARIABEL UNTUK MENAMPUNG HASIL AI ---
  String _hasilNama = "";
  String _hasilDeskripsi = "";
  String _hasilConfidence = "";
  bool _isTerdeteksi = false;
  // -----------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  // --- FUNGSI INISIALISASI KAMERA YANG SUDAH DIOPTIMALKAN ---
  Future<void> _initializeCamera() async {
    // 1. Minta Izin Kamera Terlebih Dahulu
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        return; // Jika ditolak, stop.
      }
    }

    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        _showErrorDialog('Tidak ada kamera tersedia');
        return;
      }
      
      // Pastikan index kamera valid
      if (_selectedCameraIndex >= _cameras!.length) {
        _selectedCameraIndex = 0;
      }

      // 2. Setting Controller dengan Resolusi MEDIUM (Agar Cepat/Tidak Lelet)
      _cameraController = CameraController(
        _cameras![_selectedCameraIndex],
        ResolutionPreset.medium, // Ubah dari max/high ke medium (720p) cukup untuk AI
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.jpeg 
            : ImageFormatGroup.bgra8888, 
      );

      await _cameraController!.initialize();
      
      // 3. Matikan Flash Secara Default (Agar tidak otomatis nyala)
      if (_cameraController!.value.flashMode != FlashMode.off) {
        await _cameraController!.setFlashMode(FlashMode.off);
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isFlashOn = false; // Reset status UI flash
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Gagal menginisialisasi kamera: $e');
      }
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      _showErrorDialog('Tidak ada kamera lain yang tersedia');
      return;
    }
    setState(() {
      _isCameraInitialized = false;
      _isFlashOn = false;
    });
    
    await _cameraController?.dispose();
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;
    await _initializeCamera();
  }

  // --- LOGIKA FLASH MANUAL ---
  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    try {
      if (_isFlashOn) {
        // Matikan Flash
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        // Nyalakan Flash (Torch = Senter Terus Nyala, Always = Nyala pas jepret)
        // Disarankan Torch agar user bisa melihat objek gelap sebelum difoto
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      _showErrorDialog('Gagal mengatur flash');
    }
  }

  Future<void> _processImageWithAI(XFile image) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('📸 Memproses gambar untuk deteksi...');
      debugPrint('📸 File path: ${image.path}');
      debugPrint('📸 File name: ${image.name}');
      
      final result = await ApiService.detectRambu(image);
      debugPrint('📸 Hasil deteksi: ${result['success']}');

      if (result['success']) {
        final data = result['data'];
        debugPrint('📸 Data terdeteksi: ${data['terdeteksi']}');
        debugPrint('📸 Nama rambu: ${data['nama_rambu']}');
        
        setState(() {
          _isTerdeteksi = data['terdeteksi'] ?? false;
          
          if (_isTerdeteksi) {
            _hasilNama = data['nama_rambu'] ?? "Tidak Diketahui";
            _hasilDeskripsi = data['deskripsi'] ?? "Belum ada deskripsi.";
            double conf = data['confidence'] ?? 0.0;
            _hasilConfidence = "${(conf * 100).toStringAsFixed(1)}%";

            // Simpan ke Riwayat jika file gambar masih ada
            if (_capturedImage != null) {
              RiwayatService.addRiwayat(
                _hasilNama, 
                data['kategori'] ?? 'Rambu Lalu Lintas',
                _capturedImage!.path 
              );
            }

          } else {
            _hasilNama = "Tidak Terdeteksi";
            _hasilDeskripsi = data['pesan'] ?? "Objek tidak dikenali.";
            _hasilConfidence = "0%";
            debugPrint('📸 Tidak ada rambu terdeteksi: ${data['pesan']}');
          }
        });

        if (mounted) _showResultDialog();
      } else {
        debugPrint('🔴 Error deteksi: ${result['message']}');
        _showErrorDialog(result['message'] ?? 'Gagal mendeteksi rambu');
      }
    } catch (e, stackTrace) {
      debugPrint('🔴 Exception saat deteksi: $e');
      debugPrint('🔴 Stack trace: $stackTrace');
      _showErrorDialog('Error aplikasi: $e\n\nPastikan backend berjalan dan terhubung ke jaringan yang sama.');
    } finally {
      if (mounted) setState(() { _isProcessing = false; });
    }
  }

  Future<void> _captureAndDetect() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isProcessing) return;

    try {
      // Matikan Flash sementara saat jepret jika mode torch aktif (opsional, tergantung selera)
      // Tapi untuk AI biasanya mode Torch lebih stabil pencahayaannya daripada Flash kilat.
      
      final XFile image = await _cameraController!.takePicture();
      
      // Matikan flash otomatis setelah foto diambil (Hemat baterai)
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
        setState(() { _isFlashOn = false; });
      }

      setState(() {
        _capturedImage = File(image.path);
      });
      await _processImageWithAI(image); 
    } catch (e) {
      _showErrorDialog('Gagal mengambil gambar: $e');
      setState(() { _isProcessing = false; });
    }
  }

  Future<void> _pickImageFromGallery() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
       await Permission.storage.request();
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Kompres sedikit agar upload cepat
      );

      if (image != null) {
        setState(() {
          _capturedImage = File(image.path);
        });
        await _processImageWithAI(image);
      }
    } catch (e) {
      _showErrorDialog('Gagal memilih gambar dari galeri.');
      setState(() { _isProcessing = false; });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Info'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Hasil Deteksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView( // Tambahkan scroll agar aman di layar kecil
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_capturedImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _capturedImage!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rambu Terdeteksi:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (_isTerdeteksi)
                    Text(
                      _hasilConfidence,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isTerdeteksi ? const Color(0xFFD6D588) : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _hasilNama, 
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Deskripsi:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              
              Text(
                _hasilDeskripsi, 
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _capturedImage = null;
              });
            },
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _capturedImage = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD6D588),
              foregroundColor: Colors.black,
            ),
            child: const Text('Scan Lagi'),
          ),
        ],
      ),
    );
  }

  void _navigateToRiwayat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RiwayatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildHeader(),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(child: _buildCameraContainer()),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: const Color(0xFFD6D588),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Text(
        'Deteksi',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: _navigateToRiwayat,
          icon: const Icon(Icons.history, size: 28, color: Colors.black),
          padding: const EdgeInsets.all(8),
        ),
      ],
    );
  }

  Widget _buildCameraContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _buildCameraPreview(),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final cameraAspectRatio = _cameraController!.value.aspectRatio;
        final containerAspectRatio = constraints.maxWidth / constraints.maxHeight;
        double scaleX = 1.0;
        double scaleY = 1.0;
        if (cameraAspectRatio > containerAspectRatio) {
          scaleY = cameraAspectRatio / containerAspectRatio;
        } else {
          scaleX = containerAspectRatio / cameraAspectRatio;
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scaleX: scaleX,
              scaleY: scaleY,
              child: Center(
                child: AspectRatio(
                  aspectRatio: cameraAspectRatio,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
            CustomPaint(painter: DetectionFramePainter()),
            Positioned(
              top: 16,
              right: 16,
              child: _buildFlipCameraButton(),
            ),
            if (_isProcessing) _buildProcessingOverlay(),
            if (!_isProcessing) _buildInstructions(),
          ],
        );
      },
    );
  }

  Widget _buildFlipCameraButton() {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
      child: IconButton(onPressed: _flipCamera, icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 28), padding: const EdgeInsets.all(12)),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)), SizedBox(height: 16), Text('Mendeteksi rambu...', style: TextStyle(color: Colors.white, fontSize: 16))])),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 20, left: 0, right: 0,
      child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), borderRadius: BorderRadius.circular(20)), child: const Text('Arahkan kamera ke rambu lalu lintas', style: TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center))),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(icon: Icons.image_outlined, onPressed: _pickImageFromGallery),
          _buildCaptureButton(),
          _buildActionButton(icon: _isFlashOn ? Icons.flash_on : Icons.flash_off, onPressed: _toggleFlash, isActive: _isFlashOn),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onPressed, bool isActive = false}) {
    return Container(
      decoration: BoxDecoration(color: isActive ? const Color(0xFFD6D588) : Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]),
      child: IconButton(onPressed: onPressed, icon: Icon(icon, size: 28, color: isActive ? Colors.white : Colors.black), padding: const EdgeInsets.all(16)),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isProcessing ? null : _captureAndDetect,
      child: Container(width: 70, height: 70, decoration: BoxDecoration(color: const Color(0xFFD6D588), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))]), child: const Icon(Icons.search, size: 36, color: Colors.white)),
    );
  }
}

class DetectionFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFD6D588)..style = PaintingStyle.stroke..strokeWidth = 4;
    final frameRect = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width * 0.75, height: size.height * 0.55);
    final cornerLength = 40.0;
    canvas.drawLine(frameRect.topLeft, Offset(frameRect.left + cornerLength, frameRect.top), paint);
    canvas.drawLine(frameRect.topLeft, Offset(frameRect.left, frameRect.top + cornerLength), paint);
    canvas.drawLine(frameRect.topRight, Offset(frameRect.right - cornerLength, frameRect.top), paint);
    canvas.drawLine(frameRect.topRight, Offset(frameRect.right, frameRect.top + cornerLength), paint);
    canvas.drawLine(frameRect.bottomLeft, Offset(frameRect.left + cornerLength, frameRect.bottom), paint);
    canvas.drawLine(frameRect.bottomLeft, Offset(frameRect.left, frameRect.bottom - cornerLength), paint);
    canvas.drawLine(frameRect.bottomRight, Offset(frameRect.right - cornerLength, frameRect.bottom), paint);
    canvas.drawLine(frameRect.bottomRight, Offset(frameRect.right, frameRect.bottom - cornerLength), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}