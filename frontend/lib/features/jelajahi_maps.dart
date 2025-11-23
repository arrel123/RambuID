import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:Rambuid/features/detailrambu.dart';

class JelajahiMapsPage extends StatefulWidget {
  const JelajahiMapsPage({super.key});

  @override
  State<JelajahiMapsPage> createState() => _JelajahiMapsPageState();
}

class _JelajahiMapsPageState extends State<JelajahiMapsPage> {
  late final MapController _mapController;
  LatLng _userPos = const LatLng(
    -1.1191,
    104.0534,
  ); // Default Batam (Politeknik)
  StreamSubscription<Position>? _posStream;
  String _userLocationName = 'Lokasi Anda';

  // Untuk pencarian
  final TextEditingController _searchController = TextEditingController();
  LatLng? _destinationPos;
  String? _destinationName;
  bool _showRouteInfo = false;
  bool _isBottomSheetExpanded = true;

  final List<String> _kategoriList = [
    'Semua',
    'Perintah',
    'Petunjuk',
    'Larangan',
    'Peringatan',
  ];
  String _activeKategori = 'Semua';

  // --- Data rambu yang akan di-generate berdasarkan lokasi user ---
  List<Map<String, dynamic>> _rambuAll = [];

  // Data dummy lokasi untuk pencarian
  final List<Map<String, dynamic>> _lokasiPopuler = [
    {'name': 'Politeknik Negeri Batam', 'lat': -1.1191, 'lng': 104.0534},
    {'name': 'Bandara Hang Nadim', 'lat': -1.1211, 'lng': 104.1189},
    {'name': 'Mega Mall', 'lat': -1.1308, 'lng': 104.0534},
    {'name': 'BCS Mall', 'lat': -1.1142, 'lng': 104.0295},
    {'name': 'Harbor Bay', 'lat': -1.0858, 'lng': 104.0292},
    {'name': 'Nagoya Hill', 'lat': -1.1291, 'lng': 104.0286},
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _generateDummyRambu(_userPos); // Generate rambu di posisi default
    _initLocation();
  }

  @override
  void dispose() {
    _posStream?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _userPos = LatLng(pos.latitude, pos.longitude);
      _getUserLocationName(pos);
      // Generate rambu baru di sekitar lokasi GPS user
      _generateDummyRambu(_userPos);
    });
    _mapController.move(_userPos, 15.0);

    _posStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 10,
          ),
        ).listen((p) {
          setState(() => _userPos = LatLng(p.latitude, p.longitude));
          _getUserLocationName(p);
        });
  }

  // Fungsi untuk generate rambu dummy di sekitar posisi tertentu
  void _generateDummyRambu(LatLng center) {
    _rambuAll = [
      {
        'id': 'r1',
        'title': 'Wajib Belok Kanan',
        'category': 'Perintah',
        'lat': center.latitude,
        'lng': center.longitude + 0.001,
        'description':
            'Rambu perintah yang menginstruksikan pengendara untuk belok kanan.',
        'image': 'assets/images/dilarang_belok_kiri.png',
      },
      {
        'id': 'r2',
        'title': 'Gunakan Jalur Kiri',
        'category': 'Perintah',
        'lat': center.latitude + 0.0005,
        'lng': center.longitude + 0.0015,
        'description': 'Rambu perintah agar kendaraan tetap di jalur kiri.',
        'image': 'assets/images/penyeberangan_pejalan_kaki.png',
      },
      {
        'id': 'r3',
        'title': 'Penyeberangan Pejalan Kaki',
        'category': 'Petunjuk',
        'lat': center.latitude - 0.0005,
        'lng': center.longitude,
        'description': 'Menunjukkan area penyeberangan bagi pejalan kaki.',
        'image': 'assets/images/penyeberangan_pejalan_kaki.png',
      },
      {
        'id': 'r4',
        'title': 'Rumah Sakit di Depan',
        'category': 'Petunjuk',
        'lat': center.latitude + 0.0015,
        'lng': center.longitude + 0.001,
        'description': 'Menunjukkan lokasi rumah sakit di depan jalan.',
        'image': 'assets/images/jalan_tidak_rata.png',
      },
      {
        'id': 'r5',
        'title': 'Dilarang Parkir',
        'category': 'Larangan',
        'lat': center.latitude + 0.001,
        'lng': center.longitude - 0.001,
        'description': 'Menandakan area ini dilarang untuk parkir kendaraan.',
        'image': 'assets/images/dilarang_parkir.png',
      },
      {
        'id': 'r6',
        'title': 'Dilarang Masuk',
        'category': 'Larangan',
        'lat': center.latitude + 0.002,
        'lng': center.longitude + 0.0005,
        'description': 'Melarang semua kendaraan masuk ke area tertentu.',
        'image': 'assets/images/dilarang_putar_balik.png',
      },
      {
        'id': 'r7',
        'title': 'Jalan Menurun',
        'category': 'Peringatan',
        'lat': center.latitude - 0.001,
        'lng': center.longitude - 0.0015,
        'description': 'Peringatan bahwa jalan di depan menurun.',
        'image': 'assets/images/jalan_tidak_rata.png',
      },
      {
        'id': 'r8',
        'title': 'Hati-Hati Sekolah',
        'category': 'Peringatan',
        'lat': center.latitude - 0.002,
        'lng': center.longitude + 0.0015,
        'description': 'Peringatan adanya area sekolah di sekitar jalan.',
        'image': 'assets/images/jalan_tidak_rata.png',
      },
    ];
  }

  // Fungsi untuk mendapatkan nama lokasi user (simplified)
  void _getUserLocationName(Position pos) {
    // Anda bisa integrate dengan Geocoding API untuk mendapat nama sebenarnya
    // Untuk sementara, cek apakah dekat dengan lokasi yang dikenal
    for (var lokasi in _lokasiPopuler) {
      final distance = _calculateDistance(
        LatLng(pos.latitude, pos.longitude),
        LatLng(lokasi['lat'], lokasi['lng']),
      );
      if (distance < 1.0) {
        // dalam radius 1km
        setState(() => _userLocationName = 'Dekat ${lokasi['name']}');
        return;
      }
    }
    setState(() => _userLocationName = 'Lokasi Anda');
  }

  List<Map<String, dynamic>> get _rambuFiltered {
    if (_activeKategori == 'Semua') return _rambuAll;
    return _rambuAll.where((r) => r['category'] == _activeKategori).toList();
  }

  Color _colorForKategori(String k) {
    switch (k) {
      case 'Perintah':
        return Colors.blueAccent;
      case 'Petunjuk':
        return Colors.green;
      case 'Larangan':
        return Colors.redAccent;
      case 'Peringatan':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }

  IconData _iconForKategori(String k) {
    switch (k) {
      case 'Perintah':
        return Icons.arrow_circle_right;
      case 'Petunjuk':
        return Icons.info;
      case 'Larangan':
        return Icons.block;
      case 'Peringatan':
        return Icons.warning;
      default:
        return Icons.traffic;
    }
  }

  void _showDetailRambu(Map<String, dynamic> r) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailRambuScreen(rambu: r)),
    );
  }

  // Fungsi untuk menghitung jarak
  double _calculateDistance(LatLng from, LatLng to) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, from, to);
  }

  // Fungsi untuk menampilkan bottom sheet pencarian
  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari lokasi...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _lokasiPopuler.length,
                itemBuilder: (context, index) {
                  final lokasi = _lokasiPopuler[index];
                  final distance = _calculateDistance(
                    _userPos,
                    LatLng(lokasi['lat'], lokasi['lng']),
                  );

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.location_on)),
                    title: Text(lokasi['name']),
                    subtitle: Text(
                      '${distance.toStringAsFixed(1)} km dari lokasi Anda',
                    ),
                    onTap: () {
                      setState(() {
                        _destinationPos = LatLng(lokasi['lat'], lokasi['lng']);
                        _destinationName = lokasi['name'];
                        _showRouteInfo = true;
                      });
                      _mapController.move(_destinationPos!, 14.0);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userPos,
                initialZoom: 15.0,
                minZoom: 3.0,
                maxZoom: 19.0,
                // Pengaturan interaksi yang lebih smooth
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                  pinchZoomThreshold: 0.5,
                  scrollWheelVelocity: 0.005,
                  pinchZoomWinGestures: MultiFingerGesture.all,
                  pinchMoveThreshold: 40.0,
                  rotationThreshold: 20.0,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.rambuid',
                ),
                // Polyline untuk rute (garis kuning)
                if (_destinationPos != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_userPos, _destinationPos!],
                        strokeWidth: 4.0,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    // Marker posisi user
                    Marker(
                      point: _userPos,
                      width: 42,
                      height: 42,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blueAccent,
                        size: 40,
                      ),
                    ),
                    // Marker destinasi
                    if (_destinationPos != null)
                      Marker(
                        point: _destinationPos!,
                        width: 42,
                        height: 42,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    // Marker rambu
                    ..._rambuFiltered.map(
                      (r) => Marker(
                        point: LatLng(r['lat'], r['lng']),
                        width: 42,
                        height: 42,
                        child: GestureDetector(
                          onTap: () => _showDetailRambu(r),
                          child: Icon(
                            _iconForKategori(r['category']),
                            color: _colorForKategori(r['category']),
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 🔹 Search bar
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: GestureDetector(
                onTap: _showSearchBottomSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(
                        'Cari lokasi tujuan...',
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 🔹 Tombol kategori
            Positioned(
              top: 70,
              left: 12,
              right: 12,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _kategoriList.map((k) {
                    final active = k == _activeKategori;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(k),
                        selected: active,
                        onSelected: (sel) =>
                            setState(() => _activeKategori = sel ? k : 'Semua'),
                        selectedColor: Colors.white,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        side: BorderSide(
                          color: active
                              ? Colors.blueAccent
                              : Colors.grey.shade300,
                        ),
                        labelStyle: TextStyle(
                          color: active ? Colors.blueAccent : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // 🔹 Info rute di bagian bawah
            if (_showRouteInfo && _destinationPos != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isBottomSheetExpanded = !_isBottomSheetExpanded;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    height: _isBottomSheetExpanded ? 280 : 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${(_calculateDistance(_userPos, _destinationPos!)).toStringAsFixed(1)} km',
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            _isBottomSheetExpanded
                                                ? Icons.keyboard_arrow_down
                                                : Icons.keyboard_arrow_up,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          setState(() {
                                            _showRouteInfo = false;
                                            _destinationPos = null;
                                            _destinationName = null;
                                            _isBottomSheetExpanded = true;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (_isBottomSheetExpanded) ...[
                                    Text(
                                      'Estimasi ${(_calculateDistance(_userPos, _destinationPos!) * 2).toInt()} menit',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: const BoxDecoration(
                                              color: Colors.amber,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Center(
                                              child: Text(
                                                '45%',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              'Rute tercepat saat ini berdasarkan kondisi lalu lintas',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.circle,
                                          size: 12,
                                          color: Colors.black,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _userLocationName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _destinationName ?? 'Destinasi',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 🔹 Tombol fokus ke lokasi pengguna
            Positioned(
              right: 14,
              bottom: _showRouteInfo
                  ? (_isBottomSheetExpanded ? 300 : 100)
                  : 20,
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: () => _mapController.move(_userPos, 16.5),
                child: const Icon(Icons.my_location, color: Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
