import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/api.dart';

class ReportReviewScreen extends StatefulWidget {
  final Report report;
  const ReportReviewScreen({super.key, required this.report});

  @override
  State<ReportReviewScreen> createState() => _ReportReviewScreenState();
}

class _ReportReviewScreenState extends State<ReportReviewScreen> {
  bool _saving = false;
  bool _loading = false;
  List<User> _samplers = [];
  List<User> _analysts = [];
  User? _selectedSampler;
  User? _selectedAnalyst;
  int? _departmentId; // id departemen user login

  @override
  void initState() {
    super.initState();
    _loadDepartmentAndUsers();
  }

  Future<void> _loadDepartmentAndUsers() async {
    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      _departmentId = prefs.getInt("departmentId"); // ambil dari login

      final users = await API.users.list();

      setState(() {
        _samplers = users
            .where((u) =>
                (u.roles?.contains("Sampler") ?? false) &&
                u.departmentId == _departmentId)
            .toList();

        _analysts = users
            .where((u) =>
                (u.roles?.contains("Analyst") ?? false) &&
                u.departmentId == _departmentId)
            .toList();
      });
    } catch (e) {
      print("Gagal load user: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _submitReview() async {
    if (_selectedSampler == null || _selectedAnalyst == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih Sampler dan Analyst terlebih dahulu")),
      );
      return;
    }

    setState(() => _saving = true);

    final payload = {
      "sampler_id": _selectedSampler!.id,
      "analyst_id": _selectedAnalyst!.id,
      "remark": "Reviewed and assigned",
      "notes": "Report diterima dan sedang diproses"
    };

    print("Submitting review (take-action): $payload");

    try {
      final success = await API.reports.takeAction(widget.report.id, payload);

      if (!mounted) return;

      if (success) {
        setState(() {
          widget.report.raw?['sampler_name'] = _selectedSampler!.name;
          widget.report.raw?['analyst_name'] = _selectedAnalyst!.name;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report berhasil direview dan di-assign")),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal menyimpan review")),
        );
      }
    } catch (e) {
      print("Error take action: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan saat menyimpan")),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Review ${widget.report.noReport ?? ''}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<User>(
              value: _selectedSampler,
              items: _samplers
                  .map((u) => DropdownMenuItem(
                        value: u,
                        child: Text(u.name ?? "Tanpa nama"),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedSampler = val),
              decoration: const InputDecoration(labelText: "Pilih Sampler"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<User>(
              value: _selectedAnalyst,
              items: _analysts
                  .map((u) => DropdownMenuItem(
                        value: u,
                        child: Text(u.name ?? "Tanpa nama"),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedAnalyst = val),
              decoration: const InputDecoration(labelText: "Pilih Analyst"),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _submitReview,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Simpan Review"),
            )
          ],
        ),
      ),
    );
  }
}
