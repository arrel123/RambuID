import 'dart:convert';
import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> rambuData = [];
  bool _mapReady = false;
  Map<String, dynamic>? _selectedRambu;
  
  final LatLng _defaultLocation = const LatLng(1.1295, 104.0538); 

  @override
  void initState() {
    super.initState();
    loadRambuData();
  }

  Future<void> loadRambuData() async {
    try {
      final result = await ApiService.getJelajahiPoints();
      
      if (result['success']) {
        final List<dynamic> apiData = result['data'];
        Map<String, int> coordCount = {};

        setState(() {
          rambuData = apiData.asMap().entries.map<Map<String, dynamic>>((entry) {
            var e = entry.value;
            String kategori = (e['kategori'] ?? '').toString().toLowerCase();
            String colorName = 'grey';
            
            // FIX: Menggunakan kurung kurawal {} agar rapi
            if (kategori.contains('larangan')) {
              colorName = 'red';
            } else if (kategori.contains('peringatan')) {
              colorName = 'orange';
            } else if (kategori.contains('perintah')) {
              colorName = 'blue';
            } else if (kategori.contains('petunjuk')) {
              colorName = 'green';
            }

            double lat = (e['latitude'] is String) ? double.parse(e['latitude']) : (e['latitude'] ?? 0.0);
            double lng = (e['longitude'] is String) ? double.parse(e['longitude']) : (e['longitude'] ?? 0.0);

            String coordKey = '$lat,$lng';
            if (!coordCount.containsKey(coordKey)) {
              coordCount[coordKey] = 0;
            } else {
              coordCount[coordKey] = coordCount[coordKey]! + 1;
            }

            int duplicateCount = coordCount[coordKey]!;
            double offsetLat = lat;
            double offsetLng = lng;
            
            if (duplicateCount > 0) {
              double angle = (duplicateCount * 360 / 8) * (3.14159 / 180);
              double distance = 0.00008 * duplicateCount;
              offsetLat += distance * _cos(angle);
              offsetLng += distance * _sin(angle);
            }

            String rawUrl = e['gambar_url'] ?? '';
            String fullImageUrl = '';
            if (rawUrl.isNotEmpty) {
              fullImageUrl = rawUrl.startsWith('http') ? rawUrl : '${ApiService.baseUrl}$rawUrl';
            }

            return {
              'id': e['id'],
              'nama': e['nama'] ?? 'Rambu Tanpa Nama',
              'nama_en': e['nama_en'], 
              'deskripsi': e['deskripsi'] ?? 'Tidak ada deskripsi',
              'deskripsi_en': e['deskripsi_en'],
              'kategori': e['kategori'],
              'gambar_url': fullImageUrl,
              'colorName': colorName,
              'original_lat': lat,
              'original_lng': lng,
              'lat': offsetLat,
              'lng': offsetLng,
            };
          }).toList();
          
          _mapReady = true;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (rambuData.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 800), () {
              _fitBoundsToMarkers();
            });
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading Data Maps: $e');
    }
  }

  double _cos(double radians) {
    return (radians * radians * radians * radians / 24 - radians * radians / 2 + 1);
  }
  double _sin(double radians) {
    return radians - (radians * radians * radians) / 6;
  }

  void _showMarkerInfo(Map<String, dynamic> rambu) {
    setState(() => _selectedRambu = rambu);
  }

  void _closeMarkerInfo() => setState(() => _selectedRambu = null);

  void _fitBoundsToMarkers() {
    if (rambuData.isEmpty) return;
    double minLat = rambuData[0]['lat'];
    double maxLat = rambuData[0]['lat'];
    double minLng = rambuData[0]['lng'];
    double maxLng = rambuData[0]['lng'];
    
    for (var rambu in rambuData) {
      if (rambu['lat'] < minLat) { minLat = rambu['lat']; }
      if (rambu['lat'] > maxLat) { maxLat = rambu['lat']; }
      if (rambu['lng'] < minLng) { minLng = rambu['lng']; }
      if (rambu['lng'] > maxLng) { maxLng = rambu['lng']; }
    }
    
    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'orange': return Colors.orange;
      case 'green': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (context) => SearchBottomSheet(
        onLocationSelected: (location) {
          _mapController.move(LatLng(location['lat'], location['lng']), 15);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Scaffold(
      body: _mapReady
          ? Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _defaultLocation,
                    initialZoom: 12,
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
                              width: 25, height: 41,
                              errorBuilder: (context, error, stackTrace) => Icon(Icons.location_on, color: _getColorFromName(rambu['colorName']), size: 40),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),

                Positioned(
                  right: 16, bottom: 230,
                  child: Column(
                    children: [
                      _buildFloatingButton(icon: Icons.add, onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
                      const SizedBox(height: 12),
                      _buildFloatingButton(icon: Icons.remove, onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
                      const SizedBox(height: 12),
                      _buildFloatingButton(icon: Icons.my_location, onPressed: _fitBoundsToMarkers),
                    ],
                  ),
                ),

                if (_selectedRambu != null)
                  Positioned(
                    left: 0, right: 0, bottom: 85,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -4))]),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: const Color(0xFFD6D588).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                                child: Icon(Icons.location_on, color: _getColorFromName(_selectedRambu!['colorName']), size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(isEnglish ? 'Traffic Sign Location' : 'Lokasi Rambu', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(
                                      isEnglish 
                                          ? (_selectedRambu!['nama_en'] ?? _selectedRambu!['nama']) 
                                          : _selectedRambu!['nama'],
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      _selectedRambu!['kategori'] ?? '-',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.close), onPressed: _closeMarkerInfo),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity, height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => DetailRambuScreen(rambu: _selectedRambu!)));
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD6D588), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                              child: Text(
                                isEnglish ? 'View Sign Details' : 'Lihat Detail Rambu',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_selectedRambu == null)
                  Positioned(
                    left: 16, right: 16, bottom: 100,
                    child: GestureDetector(
                      onTap: _showSearchBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -4))]),
                        child: Row(
                          children: [
                            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFD6D588).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.search, size: 24)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isEnglish ? 'Search location' : 'Cari lokasi', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(isEnglish ? 'Find signs in Batam' : 'Temukan titik rambu di Batam', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)]),
      child: IconButton(icon: Icon(icon), onPressed: onPressed, color: Colors.black87),
    );
  }
}

// --- SEARCH BOTTOM SHEET ---
class SearchBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onLocationSelected;
  const SearchBottomSheet({super.key, required this.onLocationSelected});

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredLocations = [];
  bool _isSearching = false;

  // --- DATA LOKASI UPDATE: SUDAH ADA 'nama_en' ---
  final List<Map<String, dynamic>> batamLocations = [
    {
      'nama': 'Batam Centre', 
      'nama_en': 'Batam Centre', 
      'kecamatan': 'Batam Kota', 
      'lat': 1.1295, 
      'lng': 104.0538, 
      'type': 'pusat'
    },
    {
      'nama': 'Nagoya Hill', 
      'nama_en': 'Nagoya Hill', 
      'kecamatan': 'Lubuk Baja', 
      'lat': 1.1458, 
      'lng': 104.0135, 
      'type': 'mall'
    },
    {
      'nama': 'Bandara Hang Nadim', 
      'nama_en': 'Hang Nadim Airport', 
      'kecamatan': 'Nongsa', 
      'lat': 1.1205, 
      'lng': 104.1185, 
      'type': 'bandara'
    },
    {
      'nama': 'Jembatan Barelang', 
      'nama_en': 'Barelang Bridge', 
      'kecamatan': 'Galang', 
      'lat': 0.9825, 
      'lng': 104.0410, 
      'type': 'wisata'
    },
    {
      'nama': 'Harbour Bay', 
      'nama_en': 'Harbour Bay', 
      'kecamatan': 'Batu Ampar', 
      'lat': 1.1540, 
      'lng': 103.9980, 
      'type': 'pelabuhan'
    },
  ];

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  void _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() { filteredLocations = batamLocations; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    try {
      final localResults = batamLocations.where((location) {
        // Logika pencarian juga bisa dua bahasa kalau mau, tapi ini cukup default
        final nama = location['nama'].toString().toLowerCase();
        final namaEn = (location['nama_en'] ?? '').toString().toLowerCase();
        final kecamatan = location['kecamatan'].toString().toLowerCase();
        final q = query.toLowerCase();
        
        return nama.contains(q) || namaEn.contains(q) || kecamatan.contains(q);
      }).toList();

      final nominatimUrl = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent('$query Batam')}&format=json&limit=5&countrycodes=id');
      final response = await http.get(nominatimUrl, headers: {'User-Agent': 'BatamRambuApp/1.0'});

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        final nominatimResults = results.map((place) {
          return {
            'nama': place['display_name'].toString().split(',')[0],
            'nama_en': place['display_name'].toString().split(',')[0], // Default sama
            'alamat': place['display_name'],
            'lat': double.parse(place['lat']),
            'lng': double.parse(place['lon']),
            'type': 'search',
          };
        }).toList();
        setState(() { filteredLocations = [...localResults, ...nominatimResults]; _isSearching = false; });
      } else {
        setState(() { filteredLocations = localResults; _isSearching = false; });
      }
    } catch (e) {
      setState(() { filteredLocations = batamLocations; _isSearching = false; });
    }
  }

  @override
  void initState() { super.initState(); filteredLocations = batamLocations; }

  @override
  Widget build(BuildContext context) {
    // MENERAPKAN LOGIKA BAHASA INGGRIS
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              decoration: InputDecoration(
                // LOGIKA BAHASA UNTUK HINT TEXT
                hintText: isEnglish 
                    ? 'Search location (e.g. Nagoya, Airport)...' 
                    : 'Cari lokasi (cth: Nagoya, Bandara)...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true, fillColor: Colors.grey[100],
              ),
              onChanged: _searchLocation,
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredLocations.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final location = filteredLocations[index];
                      final type = location['type'];
                      IconData iconData = Icons.place;
                      Color iconColor = Colors.grey;

                      if (type == 'pusat') { iconData = Icons.business; iconColor = Colors.blue; }
                      else if (type == 'mall') { iconData = Icons.shopping_bag; iconColor = Colors.purple; }
                      else if (type == 'bandara') { iconData = Icons.flight; iconColor = Colors.orange; }
                      else if (type == 'wisata') { iconData = Icons.camera_alt; iconColor = Colors.green; }
                      else if (type == 'pelabuhan') { iconData = Icons.directions_boat; iconColor = Colors.blueAccent; }

                      String subtitleText = '';
                      if (location['type'] == 'search') {
                        subtitleText = location['alamat'] ?? '';
                      } else {
                        // LOGIKA BAHASA UNTUK KECAMATAN
                        String kecPrefix = isEnglish ? 'Dist. ' : 'Kec. ';
                        subtitleText = '$kecPrefix${location['kecamatan']}';
                      }

                      // LOGIKA BAHASA UNTUK NAMA LOKASI
                      String displayName = location['nama'];
                      if (isEnglish && location['nama_en'] != null) {
                        displayName = location['nama_en'];
                      }

                      return ListTile(
                        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFD6D588).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: Icon(iconData, color: iconColor)),
                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(subtitleText, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => widget.onLocationSelected(location),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}