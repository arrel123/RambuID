import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../services/riwayat_service.dart';
import '../profile/riwayat.dart';

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

  // TAMBAHAN: Proteksi untuk prevent double capture
  bool _isCapturing = false;
  DateTime? _lastCaptureTime;

  String _hasilNama = "";
  String _hasilDeskripsi = "";
  String _hasilConfidence = "";
  bool _isTerdeteksi = false;

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

  Future<void> _initializeCamera() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        return;
      }
    }

    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        _showErrorDialog('Tidak ada kamera tersedia');
        return;
      }
      
      if (_selectedCameraIndex >= _cameras!.length) {
        _selectedCameraIndex = 0;
      }

      _cameraController = CameraController(
        _cameras![_selectedCameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.jpeg 
            : ImageFormatGroup.bgra8888, 
      );

      await _cameraController!.initialize();
      
      if (_cameraController!.value.flashMode != FlashMode.off) {
        await _cameraController!.setFlashMode(FlashMode.off);
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isFlashOn = false;
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

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    
    try {
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
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
      if (mounted) {
        setState(() { 
          _isProcessing = false;
          _isCapturing = false; // PENTING: Reset flag capturing
        });
      }
    }
  }

  // ========== FUNGSI CAPTURE YANG SUDAH DIPERBAIKI ==========
  Future<void> _captureAndDetect() async {
    // PROTEKSI 1: Cek kamera siap
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showErrorDialog('Kamera belum siap');
      return;
    }

    // PROTEKSI 2: Cek apakah sedang processing
    if (_isProcessing) {
      debugPrint('⚠️ Masih memproses gambar sebelumnya...');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Tunggu proses deteksi selesai'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // PROTEKSI 3: Cek apakah sedang capturing (prevent rapid tap)
    if (_isCapturing) {
      debugPrint('⚠️ Sedang mengambil gambar...');
      return;
    }

    // PROTEKSI 4: Debouncing - minimal 1.5 detik antar capture
    if (_lastCaptureTime != null) {
      final timeSinceLastCapture = DateTime.now().difference(_lastCaptureTime!);
      if (timeSinceLastCapture < const Duration(milliseconds: 1500)) {
        debugPrint('⚠️ Terlalu cepat! Tunggu ${1500 - timeSinceLastCapture.inMilliseconds}ms');
        return;
      }
    }

    try {
      // Set flag bahwa sedang capturing
      setState(() {
        _isCapturing = true;
      });
      
      _lastCaptureTime = DateTime.now();
      debugPrint('📸 Mulai mengambil gambar...');

      final XFile image = await _cameraController!.takePicture();
      debugPrint('📸 Gambar berhasil diambil: ${image.path}');
      
      // Matikan flash setelah foto diambil
      if (_isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
        setState(() { _isFlashOn = false; });
      }

      setState(() {
        _capturedImage = File(image.path);
      });
      
      await _processImageWithAI(image);
      
    } catch (e) {
      debugPrint('🔴 Error saat capture: $e');
      _showErrorDialog('Gagal mengambil gambar: $e');
      
      // Reset semua flag jika error
      setState(() { 
        _isProcessing = false;
        _isCapturing = false;
      });
    }
  }
  // ===========================================================

  Future<void> _pickImageFromGallery() async {
    // Proteksi: Jangan bisa pilih dari galeri kalau masih processing
    if (_isProcessing || _isCapturing) {
      _showErrorDialog('Tunggu proses sebelumnya selesai');
      return;
    }

    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _capturedImage = File(image.path);
        });
        await _processImageWithAI(image);
      }
    } catch (e) {
      _showErrorDialog('Gagal memilih gambar dari galeri.');
      setState(() { 
        _isProcessing = false;
        _isCapturing = false;
      });
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 400,
            maxHeight: 600,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFD6D588),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Hasil Deteksi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content dengan scroll
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      if (_capturedImage != null)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 200,
                                maxWidth: 300,
                              ),
                              child: Image.file(
                                _capturedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Confidence
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Rambu Terdeteksi:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 16
                            ),
                          ),
                          if (_isTerdeteksi)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, 
                                vertical: 4
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _hasilConfidence,
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Nama Rambu
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isTerdeteksi 
                              ? const Color(0xFFD6D588) 
                              : Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _hasilNama, 
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Deskripsi
                      const Text(
                        'Deskripsi:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Text(
                        _hasilDeskripsi, 
                        style: const TextStyle(
                          fontSize: 14, 
                          height: 1.5
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (mounted) {
                          setState(() {
                            _capturedImage = null;
                          });
                        }
                      },
                      child: const Text('Tutup'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (mounted) {
                          setState(() {
                            _capturedImage = null;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6D588),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Scan Lagi'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
          _buildActionButton(
            icon: Icons.image_outlined, 
            onPressed: (_isProcessing || _isCapturing) ? () {} : _pickImageFromGallery,
            isDisabled: _isProcessing || _isCapturing,
          ),
          _buildCaptureButton(),
          _buildActionButton(
            icon: _isFlashOn ? Icons.flash_on : Icons.flash_off, 
            onPressed: _toggleFlash, 
            isActive: _isFlashOn,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon, 
    required VoidCallback onPressed, 
    bool isActive = false,
    bool isDisabled = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDisabled 
            ? Colors.grey[300] 
            : (isActive ? const Color(0xFFD6D588) : Colors.white),
        shape: BoxShape.circle, 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), 
            blurRadius: 8, 
            offset: const Offset(0, 2)
          )
        ]
      ),
      child: IconButton(
        onPressed: isDisabled ? null : onPressed, 
        icon: Icon(
          icon, 
          size: 28, 
          color: isDisabled 
              ? Colors.grey[500]
              : (isActive ? Colors.white : Colors.black)
        ), 
        padding: const EdgeInsets.all(16)
      ),
    );
  }

  Widget _buildCaptureButton() {
    final isDisabled = _isProcessing || _isCapturing;
    
    return GestureDetector(
      onTap: isDisabled ? null : _captureAndDetect,
      child: Container(
        width: 70, 
        height: 70, 
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey[400] : const Color(0xFFD6D588),
          shape: BoxShape.circle, 
          border: Border.all(color: Colors.white, width: 4), 
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), 
              blurRadius: 12, 
              offset: const Offset(0, 4)
            )
          ]
        ), 
        child: _isCapturing 
            ? const Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              )
            : const Icon(Icons.search, size: 36, color: Colors.white)
      ),
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