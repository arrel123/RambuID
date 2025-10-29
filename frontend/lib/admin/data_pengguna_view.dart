import 'package:flutter/material.dart';

class DataPenggunaView extends StatelessWidget {
  const DataPenggunaView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text(
          'Halaman Data Pengguna akan tampil di sini. Anda bisa membuat tabel data pengguna seperti pada halaman Rambu.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, color: Colors.grey),
        ),
      ),
    );
  }
}