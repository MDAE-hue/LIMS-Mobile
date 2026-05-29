import 'package:flutter/material.dart';

class DetailPrintScreen extends StatelessWidget {
  final int reportId;
  const DetailPrintScreen({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pilih Printer")),
      body: const Center(
        child: Text("Daftar printer & fungsi print akan di sini"),
      ),
    );
  }
}
