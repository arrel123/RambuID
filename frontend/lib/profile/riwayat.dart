import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class RiwayatItem {
  final String icon;
  final String title;
  final String month;
  final String date;
  final String id;

  RiwayatItem({
    required this.icon,
    required this.title,
    required this.month,
    required this.date,
    required this.id,
  });
}

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List<RiwayatItem> _historyItems = [
    RiwayatItem(
      icon: 'assets/images/dilarang_belok_kiri.png',
      title: 'Dilarang Belok Kiri',
      month: 'September',
      date: '18/09/2025',
      id: '1',
    ),
    RiwayatItem(
      icon: 'assets/images/jalan_tidak_rata.png',
      title: 'Hati-Hati Jalan Licin',
      month: 'September',
      date: '18/09/2025',
      id: '2',
    ),
    RiwayatItem(
      icon: 'assets/images/dilarang_parkir.png',
      title: 'Dilarang Parkir',
      month: 'September',
      date: '18/09/2025',
      id: '3',
    ),
    RiwayatItem(
      icon: 'assets/images/dilarang_putar_balik.png',
      title: 'Dilarang Putar Balik',
      month: 'September',
      date: '18/09/2025',
      id: '4',
    ),
    RiwayatItem(
      icon: 'assets/images/jalan_tidak_rata.png',
      title: 'Jalan Tidak Rata',
      month: 'September',
      date: '16/09/2025',
      id: '5',
    ),
    RiwayatItem(
      icon: 'assets/images/jalan_tidak_rata.png',
      title: 'Jalan Mananjak Landai',
      month: 'September',
      date: '16/09/2025',
      id: '6',
    ),
  ];

  void _deleteItem(String id) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _historyItems.removeWhere((item) => item.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.historyDeleted),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeleteConfirmation(String id, String title) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteHistory),
        content: Text('${l10n.deleteConfirm} "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllConfirmation() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAllHistory),
        content: Text(l10n.deleteAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _historyItems.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.allHistoryDeleted),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.deleteAll),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    // Group items by month and date
    Map<String, List<RiwayatItem>> groupedItems = {};
    for (var item in _historyItems) {
      final key = '${item.month}_${item.date}';
      if (!groupedItems.containsKey(key)) {
        groupedItems[key] = [];
      }
      groupedItems[key]!.add(item);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: Color(0xFFD6D588)),
              child: Row(
                children: [
                  // Back Button
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title
                  Expanded(
                    child: Text(
                      l10n.history,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Delete All Button
                  if (_historyItems.isNotEmpty)
                    IconButton(
                      onPressed: _showDeleteAllConfirmation,
                      icon: const Icon(Icons.delete_outline),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _historyItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 100,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noHistory,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (var entry in groupedItems.entries) ...[
                          _buildMonthHeader(
                            entry.value.first.month,
                            entry.value.first.date,
                          ),
                          const SizedBox(height: 12),
                          for (var item in entry.value) ...[
                            _buildHistoryItem(
                              icon: item.icon,
                              title: item.title,
                              id: item.id,
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(String month, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          month,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(date, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildHistoryItem({
    required String icon,
    required String title,
    required String id,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1.5),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(icon, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 16),
          // Title
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          // Delete Button
          IconButton(
            onPressed: () => _showDeleteConfirmation(id, title),
            icon: const Icon(Icons.delete_outline),
            color: Colors.red[400],
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}