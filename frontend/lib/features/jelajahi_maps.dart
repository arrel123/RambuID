import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'detailrambu.dart';
import '../services/api_service.dart';

class JelajahiMapsPage extends StatefulWidget {
  const JelajahiMapsPage({super.key});

  @override
  State<JelajahiMapsPage> createState() => _JelajahiMapsPageState();
}

class _JelajahiMapsPageState extends State<JelajahiMapsPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> rambuData = [];
  List<Map<String, dynamic>> filteredLocations = [];
  bool _mapReady = false;
  bool _showSearchResults = false;
  bool _isSearching = false;
  Map<String, dynamic>? _selectedRambu;

  List<Map<String, dynamic>> _edukasiRambuList = [];

  final List<Map<String, dynamic>> batamLocations = [
    {'nama': 'Baloi Permai', 'kecamatan': 'Batam Kota', 'lat': 1.1167, 'lng': 104.0167},
    {'nama': 'Belian', 'kecamatan': 'Batam Kota', 'lat': 1.1100, 'lng': 104.0250},
    {'nama': 'Sukajadi', 'kecamatan': 'Batam Kota', 'lat': 1.1233, 'lng': 104.0200},
    {'nama': 'Sungai Panas', 'kecamatan': 'Batam Kota', 'lat': 1.1150, 'lng': 104.0100},
    {'nama': 'Taman Baloi', 'kecamatan': 'Batam Kota', 'lat': 1.1200, 'lng': 104.0150},
    {'nama': 'Teluk Tering', 'kecamatan': 'Batam Kota', 'lat': 1.1050, 'lng': 104.0300},
    {'nama': 'Batam Center', 'kecamatan': 'Batam Kota', 'lat': 1.0807, 'lng': 104.0065},
  ];

  @override
  void initState() {
    super.initState();
    loadRambuData();
    loadEdukasiRambu();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadRambuData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/rambu.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);

      print('📍 Total data rambu di JSON: ${jsonList.length}');

      // Track koordinat yang sudah muncul untuk menambahkan offset
      Map<String, int> coordCount = {};

      setState(() {
        rambuData = jsonList.asMap().entries.map<Map<String, dynamic>>((entry) {
          int index = entry.key;
          var e = entry.value;
          
          String colorName;
          switch (e['warna']) {
            case 'red':
              colorName = 'red';
              break;
            case 'blue':
              colorName = 'blue';
              break;
            case 'orange':
              colorName = 'orange';
              break;
            case 'green':
              colorName = 'green';
              break;
            default:
              colorName = 'grey';
          }

          // Buat key untuk tracking koordinat duplikat
          String coordKey = '${e['lat']},${e['lng']}';
          
          // Hitung berapa kali koordinat ini sudah muncul
          if (!coordCount.containsKey(coordKey)) {
            coordCount[coordKey] = 0;
          } else {
            coordCount[coordKey] = coordCount[coordKey]! + 1;
          }

          int duplicateCount = coordCount[coordKey]!;
          
          // Tambahkan offset kecil jika koordinat duplikat
          double offsetLat = e['lat'];
          double offsetLng = e['lng'];
          
          if (duplicateCount > 0) {
            // Offset dalam pola melingkar
            double angle = (duplicateCount * 360 / 8) * (3.14159 / 180); // Convert to radians
            double distance = 0.00008 * duplicateCount; // Jarak offset yang sangat kecil
            offsetLat += distance * cos(angle);
            offsetLng += distance * sin(angle);
          }
          
          return {
            ...Map<String, dynamic>.from(e),
            'colorName': colorName,
            'index': index,
            'original_lat': e['lat'],
            'original_lng': e['lng'],
            'lat': offsetLat,
            'lng': offsetLng,
          };
        }).toList();
        _mapReady = true;
      });

      print('✅ Total marker yang akan ditampilkan: ${rambuData.length}');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (rambuData.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 800), () {
            _fitBoundsToMarkers();
          });
        }
      });
    } catch (e) {
      print('❌ Error loading JSON: $e');
    }
  }

  // Helper function untuk cos (karena dart:math perlu diimport)
  double cos(double radians) {
    return (radians * radians * radians * radians / 24 - 
            radians * radians / 2 + 1);
  }

  // Helper function untuk sin
  double sin(double radians) {
    return radians - (radians * radians * radians) / 6;
  }

  Future<void> loadEdukasiRambu() async {
    try {
      final result = await ApiService.getRambuList(); 
      if (result['success']) {
        setState(() {
          _edukasiRambuList = List<Map<String, dynamic>>.from(result['data']);
        });
      }
    } catch (e) {
      print('Error loading edukasi rambu: $e');
    }
  }

  String _getEdukasiImageUrl(String rambuName) {
    final match = _edukasiRambuList.firstWhere(
      (r) => r['nama'].toString().toLowerCase() == rambuName.toLowerCase(),
      orElse: () => {},
    );
    if (match.isNotEmpty && match['gambar_url'] != null) {
      return match['gambar_url'].toString().startsWith('http')
          ? match['gambar_url']
          : '${ApiService.baseUrl}${match['gambar_url']}';
    }
    return '';
  }

  void _showMarkerInfo(Map<String, dynamic> rambu) {
    final gambarUrl = _getEdukasiImageUrl(rambu['nama']);
    setState(() {
      _selectedRambu = {
        ...rambu,
        'gambar_url': gambarUrl.isNotEmpty ? gambarUrl : null,
      };
    });
  }

  void _closeMarkerInfo() => setState(() => _selectedRambu = null);

  void _fitBoundsToMarkers() {
    if (rambuData.isEmpty) return;
    double minLat = rambuData[0]['lat'];
    double maxLat = rambuData[0]['lat'];
    double minLng = rambuData[0]['lng'];
    double maxLng = rambuData[0]['lng'];
    
    for (var rambu in rambuData) {
      if (rambu['lat'] < minLat) minLat = rambu['lat'];
      if (rambu['lat'] > maxLat) maxLat = rambu['lat'];
      if (rambu['lng'] < minLng) minLng = rambu['lng'];
      if (rambu['lng'] > maxLng) maxLng = rambu['lng'];
    }
    
    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }

  void _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        filteredLocations = [];
        _showSearchResults = false;
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });

    try {
      final localResults = batamLocations.where((location) {
        final nama = location['nama'].toString().toLowerCase();
        final kecamatan = location['kecamatan'].toString().toLowerCase();
        return nama.contains(query.toLowerCase()) || kecamatan.contains(query.toLowerCase());
      }).toList();

      final nominatimUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query + ' Batam')}&format=json&limit=10&countrycodes=id');

      final response = await http.get(nominatimUrl, headers: {'User-Agent': 'BatamRambuApp/1.0'});

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        final nominatimResults = results.map((place) {
          return {
            'nama': place['display_name'].toString().split(',')[0],
            'alamat': place['display_name'],
            'lat': double.parse(place['lat']),
            'lng': double.parse(place['lon']),
            'type': 'search',
          };
        }).toList();

        setState(() {
          filteredLocations = [...localResults, ...nominatimResults];
          _isSearching = false;
        });
      } else {
        setState(() {
          filteredLocations = localResults;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Search error: $e');
      setState(() {
        filteredLocations = batamLocations;
        _isSearching = false;
      });
    }
  }

  void _moveToLocation(Map<String, dynamic> location) {
    _mapController.move(LatLng(location['lat'], location['lng']), 15);
    setState(() {
      _showSearchResults = false;
      _searchController.clear();
    });
  }

  void _zoomIn() => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
  void _zoomOut() => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jelajahi Peta Rambu Batam (${rambuData.length})'),
        backgroundColor: const Color(0xFFD6D588),
        centerTitle: true,
      ),
      body: _mapReady
          ? Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(1.0807, 104.0065),
                    initialZoom: 13,
                    minZoom: 10,
                    maxZoom: 18,
                    onTap: (_, __) => _closeMarkerInfo(),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.rambuid',
                    ),
                    MarkerLayer(
                      markers: rambuData.map<Marker>((rambu) {
                        return Marker(
                          point: LatLng(rambu['lat'], rambu['lng']),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showMarkerInfo(rambu),
                            child: Image.network(
                              'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-${rambu['colorName']}.png',
                              width: 25,
                              height: 41,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.location_on,
                                  color: _getColorFromName(rambu['colorName']),
                                  size: 40,
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                // Search bar
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari kelurahan/daerah di Batam...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchLocation('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: _searchLocation,
                    ),
                  ),
                ),

                // Search results
                if (_showSearchResults && (filteredLocations.isNotEmpty || _isSearching))
                  Positioned(
                    top: 72,
                    left: 16,
                    right: 16,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredLocations.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final location = filteredLocations[index];
                                  final isLocal = location['type'] != 'search';
                                  return ListTile(
                                    leading: Icon(
                                      isLocal ? Icons.place : Icons.search,
                                      color: isLocal ? Colors.blue : Colors.orange,
                                      size: 20,
                                    ),
                                    title: Text(
                                      location['nama'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      isLocal ? 'Kec. ${location['kecamatan']}' : location['alamat'] ?? '',
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    dense: true,
                                    onTap: () => _moveToLocation(location),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),

                // Marker Info Card
                if (_selectedRambu != null)
                  Positioned(
                    top: 80,
                    left: MediaQuery.of(context).size.width * 0.15,
                    right: MediaQuery.of(context).size.width * 0.15,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedRambu!['nama'] ?? 'Rambu Lalu Lintas',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: _closeMarkerInfo,
                                  child: const Icon(Icons.close, size: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Lat: ${_selectedRambu!['original_lat']?.toStringAsFixed(5) ?? _selectedRambu!['lat'].toStringAsFixed(5)}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Lng: ${_selectedRambu!['original_lng']?.toStringAsFixed(5) ?? _selectedRambu!['lng'].toStringAsFixed(5)}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              height: 28,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetailRambuScreen(
                                        rambu: _selectedRambu!,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD6D588),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text(
                                  'Selengkapnya',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Zoom & Location Buttons
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'zoom_in',
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: _zoomIn,
                        child: const Icon(Icons.add, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        heroTag: 'zoom_out',
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: _zoomOut,
                        child: const Icon(Icons.remove, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 32,
                  child: FloatingActionButton(
                    heroTag: 'center_batam',
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: () {
                      _mapController.move(LatLng(1.0807, 104.0065), 13);
                    },
                    child: const Icon(Icons.my_location, color: Colors.black87),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}