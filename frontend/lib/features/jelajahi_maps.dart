import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/db_service.dart';

class JelajahiMapsPage extends StatefulWidget {
  const JelajahiMapsPage({super.key});

  @override
  State<JelajahiMapsPage> createState() => _JelajahiMapsPageState();
}

class _JelajahiMapsPageState extends State<JelajahiMapsPage> {
  final MapController mapController = MapController();
  List<Marker> markers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    print('🗺️  INIT MAPS PAGE');
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    print('🔄 LOADING MARKERS...');
    
    setState(() {
      isLoading = true;
      markers = [];
    });

    // MARKER TEST - PASTI MUNCUL
    markers.add(
      Marker(
        width: 70,
        height: 70,
        point: const LatLng(1.1300, 104.0500),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flag, color: Colors.white, size: 25),
              Text('TEST', style: TextStyle(color: Colors.white, fontSize: 8)),
            ],
          ),
        ),
      ),
    );

    try {
      final data = await DbService.getJelajahiWithRambu();
      print('📊 DATA DITERIMA: ${data.length} rambu');

      int successCount = 0;
      
      for (var item in data) {
        try {
          double? lat = double.tryParse(item['latitude'].toString());
          double? lng = double.tryParse(item['longitude'].toString());
          
          if (lat != null && lng != null) {
            // Tentukan warna berdasarkan kategori
            Color color;
            IconData icon;
            String label = item['nama'].toString().substring(0, 1);
            
            String kategori = (item['kategori'] ?? '').toString().toLowerCase();
            
            if (kategori.contains('larangan')) {
              color = Colors.red;
              icon = Icons.block;
            } else if (kategori.contains('perintah')) {
              color = Colors.blue;
              icon = Icons.arrow_circle_right;
            } else if (kategori.contains('petunjuk')) {
              color = Colors.green;
              icon = Icons.info;
            } else {
              color = Colors.orange;
              icon = Icons.warning;
            }

            markers.add(
              Marker(
                width: 50,
                height: 50,
                point: LatLng(lat, lng),
                child: GestureDetector(
                  onTap: () {
                    _showRambuInfo(item);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: Colors.white, size: 20),
                        Text(label, 
                             style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            );
            
            successCount++;
            print('✅ MARKER: ${item['nama']} di $lat, $lng');
          }
        } catch (e) {
          print('❌ ERROR memproses: ${item['nama']} - $e');
        }
      }

      print('🎉 BERHASIL: $successCount marker ditambahkan');

    } catch (e) {
      print('💥 ERROR LOAD: $e');
    }

    setState(() {
      isLoading = false;
    });

    print('🏁 SELESAI: ${markers.length} total markers');
  }

  void _showRambuInfo(Map<String, dynamic> rambuData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(rambuData['nama'] ?? 'Rambu'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rambuData['kategori'] != null)
              Text('Kategori: ${rambuData['kategori']}'),
            if (rambuData['deskripsi'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Deskripsi: ${rambuData['deskripsi']}'),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Lokasi: ${rambuData['latitude']}, ${rambuData['longitude']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _zoomIn() {
    final cam = mapController.camera;
    mapController.move(cam.center, cam.zoom + 1);
  }

  void _zoomOut() {
    final cam = mapController.camera;
    mapController.move(cam.center, cam.zoom - 1);
  }

  void _goToAllMarkers() {
    // Pindah ke area dimana semua marker berada (sekitar koordinat Anda)
    mapController.move(const LatLng(1.1190, 104.0488), 16.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PETA
          FlutterMap(
            mapController: mapController,
            options: const MapOptions(
              initialCenter: LatLng(1.1190, 104.0488), // Area marker Anda
              initialZoom: 16.0, // Zoom dekat
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // LOADING
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Memuat peta rambu...', 
                         style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          // TOMBOL CONTROLS
          Positioned(
            right: 20,
            top: 150,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoom_in",
                  mini: true,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "zoom_out", 
                  mini: true,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "view_all",
                  mini: true,
                  onPressed: _goToAllMarkers,
                  child: const Icon(Icons.map),
                ),
              ],
            ),
          ),

          // TOMBOL REFRESH
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: _loadMarkers,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }
}