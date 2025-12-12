import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'detailrambu.dart';

// Conditional imports - hanya di-load sesuai platform
import 'dart:ui_web' as ui_web show platformViewRegistry;
import 'dart:html' as html show window, IFrameElement;

class JelajahiMapsEmbedPage extends StatefulWidget {
  const JelajahiMapsEmbedPage({super.key});

  @override
  State<JelajahiMapsEmbedPage> createState() => _JelajahiMapsEmbedPageState();
}

class _JelajahiMapsEmbedPageState extends State<JelajahiMapsEmbedPage> {
  bool _isMapRegistered = false;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      _setupWebMap();
    }
  }

  void _setupWebMap() {
    // Listen untuk pesan dari iframe
    html.window.onMessage.listen((event) {
      try {
        final data = jsonDecode(event.data);
        
        if (data['action'] == 'detail') {
          _navigateToDetail(data);
        }
      } catch (e) {
        print('Error parsing message: $e');
        print('Received data: ${event.data}');
      }
    });

    // Register view factory hanya sekali
    if (!_isMapRegistered) {
      ui_web.platformViewRegistry.registerViewFactory(
        'leaflet-map',
        (int viewId) {
          final iframe = html.IFrameElement()
            ..src = 'assets/map/rambu_map.html'
            ..style.border = '0'
            ..style.width = '100%'
            ..style.height = '100%';
          return iframe;
        },
      );
      _isMapRegistered = true;
    }
  }

  void _navigateToDetail(Map<String, dynamic> data) {
    if (!mounted) return;
    
    final rambu = {
      'nama': data['nama'] ?? 'Tanpa Nama',
      'kategori': data['kategori'] ?? '-',
      'deskripsi': data['deskripsi'] ?? 'Tidak ada deskripsi',
      'gambar_url': data['gambar_url'] ?? '',
      'lat': data['lat'],
      'lng': data['lng'],
    };

    print('Navigating to detail with data: $rambu');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailRambuScreen(rambu: rambu),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD6D588),
        title: const Text(
          "Jelajahi Peta Rambu Batam",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: kIsWeb
            ? const SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: HtmlElementView(viewType: 'leaflet-map'),
              )
            : const Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Fitur peta hanya tersedia di Flutter Web.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Silakan buka aplikasi ini melalui browser untuk mengakses peta interaktif.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}