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

  // Proteksi untuk prevent double capture
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
      // Hanya inisialisasi ulang jika kita TIDAK sedang memproses gambar statis
      if (_capturedImage == null) {
        _initializeCamera();
      }
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
        debugPrint('Error init camera: $e');
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
      // Ignore flash error
    }
  }

  Future<void> _processImageWithAI(XFile image) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      debugPrint('📸 Memproses gambar...');
      
      final result = await ApiService.detectRambu(image);
      
      if (result['success']) {
        final data = result['data'];
        double conf = data['confidence'] ?? 0.0;
        
        // Threshold logic
        bool isConfident = conf > 0.60;
        bool apiDetected = data['terdeteksi'] ?? false;

        setState(() {
          _isTerdeteksi = apiDetected && isConfident;
          
          if (_isTerdeteksi) {
            _hasilNama = data['nama_rambu'] ?? "Tidak Diketahui";
            _hasilDeskripsi = data['deskripsi'] ?? "Belum ada deskripsi.";
            _hasilConfidence = "${(conf * 100).toStringAsFixed(1)}%";

            if (_capturedImage != null) {
              RiwayatService.addRiwayat(
                _hasilNama, 
                data['kategori'] ?? 'Rambu Lalu Lintas',
                _capturedImage!.path 
              );
            }
          } else {
            _hasilConfidence = "${(conf * 100).toStringAsFixed(1)}%";
            
            if (apiDetected && !isConfident) {
              _hasilNama = "Kurang Jelas";
              _hasilDeskripsi = "Kemungkinan: ${data['nama_rambu']}, namun akurasi terlalu rendah ($_hasilConfidence).\n\nMohon ambil gambar ulang.";
            } else {
              _hasilNama = "Tidak Terdeteksi";
              _hasilDeskripsi = data['pesan'] ?? "Objek tidak dikenali.";
            }
          }
        });

        if (mounted) _showResultDialog();
      } else {
        _showErrorDialog(result['message'] ?? 'Gagal mendeteksi rambu');
      }
    } catch (e) {
      debugPrint('🔴 Exception saat deteksi: $e');
      _showErrorDialog('Gagal memproses gambar. Periksa koneksi internet.');
    } finally {
      if (mounted) {
        setState(() { 
          _isProcessing = false;
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _captureAndDetect() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isProcessing || _isCapturing) return;

    if (_lastCaptureTime != null) {
      final timeSinceLastCapture = DateTime.now().difference(_lastCaptureTime!);
      if (timeSinceLastCapture < const Duration(milliseconds: 1500)) return;
    }

    try {
      setState(() {
        _isCapturing = true;
      });
      
      _lastCaptureTime = DateTime.now();
      final XFile image = await _cameraController!.takePicture();
      
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
      setState(() { 
        _isProcessing = false;
        _isCapturing = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (_isProcessing || _isCapturing) return;

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
        // Penting: Set capturedImage agar UI menampilkan gambar, bukan kamera yang crash
        setState(() {
          _capturedImage = File(image.path);
          _isProcessing = true; // Langsung set processing true agar loading muncul
        });
        
        await _processImageWithAI(image);
      }
    } catch (e) {
      debugPrint('Error gallery: $e');
      setState(() { 
        _isProcessing = false; 
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
      barrierDismissible: false, // User harus klik tombol tutup
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
                decoration: BoxDecoration(
                  color: _isTerdeteksi ? const Color(0xFFD6D588) : Colors.grey[400],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isTerdeteksi ? Icons.check_circle : Icons.help_outline, 
                      color: Colors.white
                    ),
                    const SizedBox(width: 8),
                    const Text(
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
              
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Akurasi AI:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isTerdeteksi ? Colors.green[100] : Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _hasilConfidence,
                              style: TextStyle(
                                fontSize: 12, 
                                color: _isTerdeteksi ? Colors.green[800] : Colors.orange[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _isTerdeteksi ? const Color(0xFFD6D588) : Colors.orange[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _hasilNama, 
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isTerdeteksi ? const Color(0xFF333333) : Colors.brown[900],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Keterangan:',
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
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Reset image agar kembali ke mode kamera
                        if (mounted) {
                          setState(() {
                            _capturedImage = null;
                            // Pastikan kamera di-init ulang jika perlu
                            if (!_isCameraInitialized) _initializeCamera();
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
                            if (!_isCameraInitialized) _initializeCamera();
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

  // ================= PERBAIKAN LOGIKA TAMPILAN =================
  Widget _buildCameraContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _buildCameraContent(),
      ),
    );
  }

  Widget _buildCameraContent() {
    // 1. Jika ada gambar hasil capture/galeri, TAMPILKAN GAMBAR ITU (bukan kamera)
    // Ini mencegah error "Camera not initialized" saat kembali dari galeri
    if (_capturedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _capturedImage!,
            fit: BoxFit.cover,
          ),
          // Tampilkan Overlay Loading yang Cantik di atas gambar
          if (_isProcessing) _buildComfortableLoading(),
        ],
      );
    }

    // 2. Jika kamera belum siap, tampilkan loading sederhana
    if (!_isCameraInitialized || _cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD6D588)),
        ),
      );
    }

    // 3. Jika kamera siap, tampilkan preview kamera + Frame
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
            if (!_isProcessing) _buildInstructions(),
            // Overlay processing (untuk mode capture langsung)
            if (_isProcessing) _buildComfortableLoading(),
          ],
        );
      },
    );
  }

  // ================= LOADING BARU YANG "NYAMAN" =================
  Widget _buildComfortableLoading() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7), // Background gelap transparan
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animasi Loading
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD6D588)), // Warna tema
                strokeWidth: 5,
              ),
            ),
            const SizedBox(height: 24),
            // Teks Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'Menganalisis Rambu...',
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 16, 
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlipCameraButton() {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
      child: IconButton(
        onPressed: _flipCamera, 
        icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 28), 
        padding: const EdgeInsets.all(12)
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 20, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6), 
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Arahkan kamera ke rambu lalu lintas',
            style: TextStyle(color: Colors.white, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      ),
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
            color: Colors.black.withValues(alpha: 0.1), 
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
              color: Colors.black.withValues(alpha: 0.2), 
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