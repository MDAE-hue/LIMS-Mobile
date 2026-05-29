import 'package:flutter/material.dart';
import '../helper/api.dart';

class ReportAddScreen extends StatefulWidget {
  const ReportAddScreen({super.key});

  @override
  State<ReportAddScreen> createState() => _ReportAddScreenState();
}

class _ReportAddScreenState extends State<ReportAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _remarkCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _saveReport() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _saving = true);
  try {
    final payload = {
      "location": _locationCtrl.text.trim(),
      "remark": _remarkCtrl.text.trim(),
      "note": _noteCtrl.text.trim(),
    };

    // ✅ gunakan API wrapper yang benar
    await API.reports.create(payload);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Report berhasil disimpan")),
    );
    Navigator.pop(context, true);
  } catch (e) {
    print("Gagal simpan report: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gagal menyimpan report")),
    );
  } finally {
    setState(() => _saving = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Report")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(labelText: "Lokasi"),
                validator: (v) => v!.isEmpty ? "Lokasi wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _remarkCtrl,
                decoration: const InputDecoration(labelText: "Remark"),
                validator: (v) => v!.isEmpty ? "Remark wajib diisi" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: "Note"),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context, false),
                      child: const Text("Batal"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveReport,
                      child: _saving
                          ? const SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Simpan"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}