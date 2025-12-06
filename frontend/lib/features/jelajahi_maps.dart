import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../services/api_service.dart';
import 'detailrambu.dart'; // IMPORT UNTUK DETAIL RAMBU

class JelajahiMapsPage extends StatefulWidget {
  const JelajahiMapsPage({super.key});

  @override
  State<JelajahiMapsPage> createState() => _JelajahiMapsPageState();
}

class _JelajahiMapsPageState extends State<JelajahiMapsPage> {
  final MapController mapController = MapController();
  final TextEditingController searchController = TextEditingController();
  List<Marker> markers = [];
  bool isLoading = true;
  bool isSearching = false;
  List<Map<String, dynamic>> searchResults = [];
  Marker? searchMarker;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      isSearching = true;
      searchResults = [];
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'q=$query, Batam&'
        'format=json&'
        'limit=5&'
        'viewbox=103.9,1.0,104.2,1.2&'
        'bounded=1'
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'RambuID Flutter App'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        setState(() {
          searchResults = data.map((item) => {
            'display_name': item['display_name'],
            'lat': double.parse(item['lat']),
            'lon': double.parse(item['lon']),
          }).toList();
          isSearching = false;
        });
      }
    } catch (e) {
      setState(() {
        isSearching = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mencari lokasi')),
        );
      }
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = result['lat'];
    final lon = result['lon'];
    
    mapController.move(LatLng(lat, lon), 17.0);
    
    if (searchMarker != null) {
      markers.remove(searchMarker);
    }
    
    searchMarker = Marker(
      width: 60,
      height: 60,
      point: LatLng(lat, lon),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.purple,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.location_on,
          color: Colors.white,
          size: 35,
        ),
      ),
    );
    
    setState(() {
      markers.add(searchMarker!);
      searchResults = [];
      searchController.clear();
    });
    
    FocusScope.of(context).unfocus();
  }

  Future<void> _loadMarkers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      markers = [];
      searchMarker = null;
    });

    try {
      final response = await ApiService.getJelajahiWithRambu();
      
      if (response['success'] == true) {
        final data = response['data'] as List<dynamic>;

        if (data.isEmpty) {
          setState(() {
            errorMessage = 'Belum ada data rambu.\nTambahkan data rambu terlebih dahulu.';
            isLoading = false;
          });
          return;
        }
        
        for (var item in data) {
          try {
            double? lat;
            double? lng;
            
            // Handle berbagai format latitude/longitude
            if (item['latitude'] is double) {
              lat = item['latitude'];
            } else if (item['latitude'] is String) {
              lat = double.tryParse(item['latitude']);
            } else if (item['latitude'] is int) {
              lat = (item['latitude'] as int).toDouble();
            }
            
            if (item['longitude'] is double) {
              lng = item['longitude'];
            } else if (item['longitude'] is String) {
              lng = double.tryParse(item['longitude']);
            } else if (item['longitude'] is int) {
              lng = (item['longitude'] as int).toDouble();
            }
            
            if (lat != null && lng != null) {
              Color color;
              IconData icon;
              String label = item['nama']?.toString().isNotEmpty == true 
                  ? item['nama'].toString().substring(0, 1).toUpperCase()
                  : '?';
              
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
                          Text(
                            label, 
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 8, 
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
          } catch (e) {
            // Skip invalid data
            continue;
          }
        }

        if (markers.isEmpty) {
          setState(() {
            errorMessage = 'Tidak ada marker valid yang dapat ditampilkan.';
          });
        }

      } else {
        setState(() {
          errorMessage = response['message'] ?? 'Gagal memuat data';
        });
      }

    } on TimeoutException catch (e) {
      setState(() {
        errorMessage = 'Koneksi timeout. Pastikan backend berjalan.';
      });
    } on SocketException catch (e) {
      setState(() {
        errorMessage = 'Tidak dapat terhubung ke server.';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  // TAMPILAN DIALOG RINGKAS (TANPA GAMBAR)
  void _showRambuInfo(Map<String, dynamic> rambuData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          rambuData['nama'] ?? 'Rambu',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kategori
              if (rambuData['kategori'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getKategoriColor(rambuData['kategori']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    rambuData['kategori'].toString().toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Koordinat
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${rambuData['latitude']}, ${rambuData['longitude']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Tombol Selengkapnya
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Tutup dialog
                    _navigateToDetail(rambuData); // Buka halaman detail
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Selengkapnya',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
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

  // NAVIGASI KE HALAMAN DETAIL
  void _navigateToDetail(Map<String, dynamic> rambuData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailRambuScreen(rambu: rambuData),
      ),
    );
  }

  Color _getKategoriColor(String kategori) {
    String kat = kategori.toLowerCase();
    if (kat.contains('larangan')) return Colors.red;
    if (kat.contains('perintah')) return Colors.blue;
    if (kat.contains('petunjuk')) return Colors.green;
    return Colors.orange;
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
    mapController.move(const LatLng(1.1190, 104.0488), 13.0);
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
              initialCenter: LatLng(1.1190, 104.0488),
              initialZoom: 13.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.rambuid.app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // LOADING INDICATOR
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Memuat peta rambu...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ERROR MESSAGE
          if (!isLoading && errorMessage != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.orange, size: 60),
                      const SizedBox(height: 20),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadMarkers,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // SEARCH BAR
          if (!isLoading && errorMessage == null)
            Positioned(
              top: 50,
              left: 20,
              right: 80,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari lokasi di Batam...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      searchController.clear();
                                      setState(() {
                                        searchResults = [];
                                      });
                                    },
                                  )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                      onSubmitted: _searchLocation,
                    ),
                    
                    // HASIL PENCARIAN
                    if (searchResults.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: searchResults.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final result = searchResults[index];
                            return ListTile(
                              leading: const Icon(Icons.location_on, color: Colors.blue),
                              title: Text(
                                result['display_name'],
                                style: const TextStyle(fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _selectSearchResult(result),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // TOMBOL CONTROLS
          if (!isLoading && errorMessage == null)
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
                    tooltip: 'Lihat Semua',
                    child: const Icon(Icons.my_location),
                  ),
                ],
              ),
            ),

          // TOMBOL REFRESH
          if (!isLoading && errorMessage == null)
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton(
                onPressed: _loadMarkers,
                backgroundColor: Colors.orange,
                tooltip: 'Refresh Data',
                child: const Icon(Icons.refresh),
              ),
            ),

          // INFO MARKER COUNT
          if (!isLoading && errorMessage == null && markers.isNotEmpty)
            Positioned(
              left: 20,
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${markers.length} Rambu',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}