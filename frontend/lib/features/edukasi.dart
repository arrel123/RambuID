import 'package:flutter/material.dart';
import 'detailrambu.dart';

class EdukasiPage extends StatefulWidget {
  final String? initialCategory;

  const EdukasiPage({super.key, this.initialCategory});

  @override
  State<EdukasiPage> createState() => _EdukasiPageState();
}

class _EdukasiPageState extends State<EdukasiPage> {
  String selectedTab = 'Semua';
  String searchQuery = '';

  final List<String> tabs = [
    'Semua',
    'Peringatan',
    'Larangan',
    'Petunjuk',
    'Perintah'
  ];

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialCategory ?? 'Semua'; 
  }

  final List<Map<String, dynamic>> rambuData = [
    {
      'image': 'assets/images/penyeberangan_pejalan_kaki.png',
      'title': 'Penyeberangan\npejalan\nkaki',
      'category': 'Peringatan',
      'description': 'Memberi peringatan bahwa di depan ada penyeberangan pejalan kaki.',
    },
    {
      'image': 'assets/images/jalan_tidak_rata.png',
      'title': 'Jalan tidak\nrata',
      'category': 'Peringatan',
      'description': 'Memberi peringatan bahwa di depan ada jalan yang tidak rata.',
    },
    {
      'image': 'assets/images/penyeberangan_pejalan_kaki.png',
      'title': 'Penyeberangan\npejalan\nkaki',
      'category': 'Peringatan',
      'description': 'Memberi peringatan bahwa di depan ada penyeberangan pejalan kaki.',
    },
    {
      'image': 'assets/images/dilarang_belok_kiri.png',
      'title': 'Dilarang belok\nkiri',
      'category': 'Larangan',
      'description': 'Melarang kendaraan untuk belok kiri di area tersebut.',
    },
    {
      'image': 'assets/images/dilarang_parkir.png',
      'title': 'Dilarang Parkir',
      'category': 'Larangan',
      'description': 'Melarang Kendaraan Parkir Di Area Tertentu Untuk Menjaga Kelancaran Lalu Lintas.',
    },
    {
      'image': 'assets/images/dilarang_putar_balik.png',
      'title': 'Dilarang putar\nbalik',
      'category': 'Larangan',
      'description': 'Melarang kendaraan untuk putar balik di area tersebut.',
    },
  ];

  List<Map<String, dynamic>> getFilteredData() {
    List<Map<String, dynamic>> filtered = rambuData;

    if (selectedTab != 'Semua') {
      filtered =
          filtered.where((item) => item['category'] == selectedTab).toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((item) =>
              item['title'].toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  void _navigateToDetail(BuildContext context, Map<String, dynamic> rambu) {
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD6D588),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Daftar Rambu',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // 🔹 Tab Bar
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: tabs.map((tab) {
                  bool isSelected = selectedTab == tab;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedTab = tab;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color:
                                isSelected ? Colors.black : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // 🔹 Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Cari Nama Rambu',
                hintStyle: const TextStyle(color: Colors.black),
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                filled: true,
                fillColor: const Color(0xFFD6D588),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 🔹 Grid View
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: getFilteredData().length,
              itemBuilder: (context, index) {
                final item = getFilteredData()[index];
                return GestureDetector(
                  onTap: () => _navigateToDetail(context, item),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Image.asset(
                              item['image'],
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            item['title'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}