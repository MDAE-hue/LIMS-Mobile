import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../helper/api.dart';

class LabTaskDetailScreen extends StatefulWidget {
  final String role;
  final int reportId;
  const LabTaskDetailScreen({super.key, required this.role, required this.reportId});

  @override
  State<LabTaskDetailScreen> createState() => _LabTaskDetailScreenState();
}

class _LabTaskDetailScreenState extends State<LabTaskDetailScreen> {
  final TextEditingController samplingDate = TextEditingController();
  final TextEditingController analysisDate = TextEditingController();

  bool loading = false;
  List<Map<String, dynamic>> rows = [];

  List<LookupItem> methods = [];
  List<LookupItem> standards = [];
  List<LookupItem> units = [];
  List<LookupItem> testTypes = [];

  int _statusId = 2; // default in progress
  String? noReport;

  @override
  void initState() {
    super.initState();
    debugPrint("🧭 Role masuk ke detail: ${widget.role}");
    _initData();
  }

  Future<void> _initData() async {
    setState(() => loading = true);
    try {
      methods = await LookupApi().getMethods();
      standards = await LookupApi().getStandards();
      units = await LookupApi().getUnits();
      testTypes = await LookupApi().getTestTypes();
      await _fetchReportDetails();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Gagal load lookup: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _fetchReportDetails() async {
    try {
      setState(() => loading = true);
      final report = await ReportApi().detail(widget.reportId);
      if (report != null) {
        samplingDate.text = report.raw?['date_sampling'] ?? '';
        analysisDate.text = report.raw?['date_analysis'] ?? '';
        _statusId = report.raw?['status_id'] ?? 2;
        noReport = report.raw?['no_report'];
      }

      final tests = await TestApi().getByReport(widget.reportId);
      rows = tests.map((t) {
        return {
          "id": t.id,
          "bahan": t.bahanPengujian ?? '',
          "jenis": testTypes.firstWhere((e) => e.id == t.testTypeId, orElse: () => LookupItem(id: 0, name: '')).name ?? '',
          "metode": methods.firstWhere((e) => e.id == t.methodId, orElse: () => LookupItem(id: 0, name: '')).name ?? '',
          "standar": standards.firstWhere((e) => e.id == t.standardId, orElse: () => LookupItem(id: 0, name: '')).name ?? '',
          "deskripsi": t.description ?? '',
          "hasil": t.result ?? '',
          "unit": units.firstWhere((e) => e.id == t.unitId, orElse: () => LookupItem(id: 0, name: '')).name ?? '',
        };
      }).toList();

      if (rows.isEmpty) addRow();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Gagal load data: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  void addRow() {
    setState(() {
      rows.add({
        "bahan": "",
        "jenis": "",
        "metode": "",
        "standar": "",
        "deskripsi": "",
        "hasil": "",
        "unit": "",
      });
    });
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  bool _isReadOnly() => _statusId == 5 || _statusId == 6 || _statusId == 3;

  Widget _buildTextField(String label, Function(String) onChanged,
      {TextEditingController? controller, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        readOnly: _isReadOnly(),
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: _isReadOnly() ? null : onChanged,
      ),
    );
  }

  Future<void> _saveDraft() async {
  if (_isReadOnly()) return;
  if (samplingDate.text.isEmpty || analysisDate.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Harap isi tanggal sampling & analisis")));
    return;
  }

  try {
    setState(() => loading = true);

    // Hanya menyimpan data tanpa mengubah status
    await ReportApi().update(widget.reportId, {
      "date_sampling": samplingDate.text,
      "date_analysis": analysisDate.text,
      // status_id tidak diubah
    });

    for (var row in rows) {
      if ((row["bahan"] ?? '').isEmpty) continue;

      final jenisId = testTypes.firstWhere((e) => e.name == row["jenis"], orElse: () => LookupItem(id: 0, name: '')).id;
      final metodeId = methods.firstWhere((e) => e.name == row["metode"], orElse: () => LookupItem(id: 0, name: '')).id;
      final standarId = standards.firstWhere((e) => e.name == row["standar"], orElse: () => LookupItem(id: 0, name: '')).id;
      final unitId = units.firstWhere((e) => e.name == row["unit"], orElse: () => LookupItem(id: 0, name: '')).id;

      if (row["id"] != null) {
        await TestApi().update(row["id"], {
          "report_id": widget.reportId,
          "bahan_pengujian": row["bahan"],
          "test_type_id": jenisId != 0 ? jenisId : null,
          "method_id": metodeId != 0 ? metodeId : null,
          "standard_id": standarId != 0 ? standarId : null,
          "description": row["deskripsi"],
          "result": row["hasil"],
          "unit_id": unitId != 0 ? unitId : null,
        });
      } else {
        await TestApi().create({
          "report_id": widget.reportId,
          "bahan_pengujian": row["bahan"],
          "test_type_id": jenisId != 0 ? jenisId : null,
          "method_id": metodeId != 0 ? metodeId : null,
          "standard_id": standarId != 0 ? standarId : null,
          "description": row["deskripsi"],
          "result": row["hasil"],
          "unit_id": unitId != 0 ? unitId : null,
        });
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("💾 Data berhasil disimpan")));
    setState(() {});
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("❌ Gagal menyimpan draft: $e")));
  } finally {
    setState(() => loading = false);
  }
}


  /// Sampler & Analyst -> Simpan & kirim ke Pending Review
  Future<void> _saveData() async {
    if (_isReadOnly()) return;
    if (samplingDate.text.isEmpty || analysisDate.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Harap isi tanggal sampling & analisis")));
      return;
    }

    try {
      setState(() => loading = true);

      await ReportApi().update(widget.reportId, {
        "date_sampling": samplingDate.text,
        "date_analysis": analysisDate.text,
        "status_id": 3,
      });

      for (var row in rows) {
        if ((row["bahan"] ?? '').isEmpty) continue;

        final jenisId = testTypes.firstWhere((e) => e.name == row["jenis"], orElse: () => LookupItem(id: 0, name: '')).id;
        final metodeId = methods.firstWhere((e) => e.name == row["metode"], orElse: () => LookupItem(id: 0, name: '')).id;
        final standarId = standards.firstWhere((e) => e.name == row["standar"], orElse: () => LookupItem(id: 0, name: '')).id;
        final unitId = units.firstWhere((e) => e.name == row["unit"], orElse: () => LookupItem(id: 0, name: '')).id;

        if (row["id"] != null) {
          await TestApi().update(row["id"], {
            "report_id": widget.reportId,
            "bahan_pengujian": row["bahan"],
            "test_type_id": jenisId != 0 ? jenisId : null,
            "method_id": metodeId != 0 ? metodeId : null,
            "standard_id": standarId != 0 ? standarId : null,
            "description": row["deskripsi"],
            "result": row["hasil"],
            "unit_id": unitId != 0 ? unitId : null,
          });
        } else {
          await TestApi().create({
            "report_id": widget.reportId,
            "bahan_pengujian": row["bahan"],
            "test_type_id": jenisId != 0 ? jenisId : null,
            "method_id": metodeId != 0 ? metodeId : null,
            "standard_id": standarId != 0 ? standarId : null,
            "description": row["deskripsi"],
            "result": row["hasil"],
            "unit_id": unitId != 0 ? unitId : null,
          });
        }
      }

      _statusId = 3;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Berhasil di finalize & masuk Pending Review")));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Gagal simpan data: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  /// Update status langsung (untuk Manager/Admin)
  Future<void> _updateStatus(int statusId) async {
    try {
      setState(() => loading = true);
      await ReportApi().update(widget.reportId, {"status_id": statusId});
      setState(() => _statusId = statusId);

      String msg = switch (statusId) {
        6 => "✅ Laporan berhasil di-approve dan ditutup",
        _ => "",
      };

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (statusId == 6) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Gagal update status: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  /// Tombol aksi berdasarkan peran
  Widget _buildActionButtons() {
    List<Widget> buttons = [];
    final role = widget.role.trim();

    // 🔹 Superintendent/Admin -> Review pakai endpoint submit-review
// 🔹 Superintendent/Admin -> Review pakai endpoint submit-review
if (_statusId == 3 && (role == "Admin" || role == "Superintendent")) {
  buttons.addAll([
    ElevatedButton.icon(
      onPressed: () async {
        try {
          setState(() => loading = true);
          await API.reports.submitReview(
            widget.reportId,
            action: 'revision',
            comment: 'Revision requested by Superintendent',
          );
          setState(() => _statusId = 4);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('📝 Laporan dikembalikan untuk revisi')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Gagal kirim revisi: $e')),
          );
        } finally {
          setState(() => loading = false);
        }
      },
      icon: const Icon(Icons.edit),
      label: const Text("Revisi"),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
    ),
    ElevatedButton.icon(
      onPressed: () async {
        try {
          setState(() => loading = true);
          await API.reports.submitReview(
            widget.reportId,
            action: 'approve',
          );
          setState(() => _statusId = 5);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Laporan berhasil direview (Pending Acknowledge)')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Gagal submit review: $e')),
          );
        } finally {
          setState(() => loading = false);
        }
      },
      icon: const Icon(Icons.verified),
      label: const Text("Approve"),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
    ),
  ]);
}


    // 🔹 Manager/Admin -> Approve & Close
    if (_statusId == 5 && (role == "Admin" || role == "Manager")) {
  buttons.add(
    ElevatedButton.icon(
      onPressed: () async {
        try {
          setState(() => loading = true);

          // ✅ Panggil endpoint approveReport dari backend
          await API.reports.approveReport(widget.reportId);

          setState(() => _statusId = 6);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Laporan berhasil di-approve dan ditutup")),
          );
          Navigator.pop(context, true);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Gagal approve report: $e")),
          );
        } finally {
          setState(() => loading = false);
        }
      },
      icon: const Icon(Icons.check_circle),
      label: const Text("Approve & Close"),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
    ),
  );
}

    // 🔹 Sampler/Analyst -> Finalisasi
    // 🔹 Sampler/Analyst -> Finalisasi & Simpan Sementara
if (_statusId == 2 || _statusId == 4) {
  buttons.addAll([
    ElevatedButton.icon(
      onPressed: _saveDraft,
      icon: const Icon(Icons.save_outlined),
      label: const Text("Simpan"),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
    ),
    ElevatedButton.icon(
      onPressed: _saveData,
      icon: const Icon(Icons.save),
      label: const Text("Finalisasi"),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[600]),
    ),
  ]);
}


    if (buttons.isEmpty) {
      String info = switch (_statusId) {
        3 => "Menunggu review oleh Superintendent",
        5 => "Menunggu Manager untuk Approve",
        6 => "Laporan telah di-approve dan ditutup",
        _ => "",
      };
      return Text(info, style: const TextStyle(color: Colors.grey));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: buttons
          .map((b) => Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: b))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff2f6f9),
      appBar: AppBar(
        title: Text(
          noReport == null
              ? "Loading Report..."
              : "$noReport - ${widget.role}",
          ),
        backgroundColor: Colors.teal[600],
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🧪 Sampling Section",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                  _buildTextField("Tanggal Sampling", (v) {}, controller: samplingDate,
                      onTap: () => _selectDate(context, samplingDate)),
                  const SizedBox(height: 20),
                  const Text("🔬 Analysis Section",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                  _buildTextField("Tanggal Analisis", (v) {}, controller: analysisDate,
                      onTap: () => _selectDate(context, analysisDate)),
                  const SizedBox(height: 20),
                  const Text("📋 Data Hasil Analisis",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 10),
                  Column(
                    children: [
                      for (int i = 0; i < rows.length; i++)
                        Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Sample #${i + 1}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                _buildTextField("Bahan", (val) => rows[i]["bahan"] = val,
                                    controller: TextEditingController(text: rows[i]["bahan"])),
                                const SizedBox(height: 12),
                                _buildDropdown("Jenis", rows[i], "jenis", testTypes),
                                const SizedBox(height: 12),
                                _buildDropdown("Metode", rows[i], "metode", methods),
                                const SizedBox(height: 12),
                                _buildDropdown("Standar", rows[i], "standar", standards),
                                const SizedBox(height: 12),
                                _buildTextField("Deskripsi", (val) => rows[i]["deskripsi"] = val,
                                    controller: TextEditingController(text: rows[i]["deskripsi"])),
                                const SizedBox(height: 12),
                                _buildTextField("Hasil", (val) => rows[i]["hasil"] = val,
                                    controller: TextEditingController(text: rows[i]["hasil"])),
                                const SizedBox(height: 12),
                                _buildDropdown("Unit", rows[i], "unit", units),
                              ],
                            ),
                          ),
                        ),
                      if (!_isReadOnly())
                        OutlinedButton.icon(
                          onPressed: addRow,
                          icon: const Icon(Icons.add, color: Colors.teal),
                          label: const Text("Tambah Baris", style: TextStyle(color: Colors.teal)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.teal),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Center(child: _buildActionButtons()),
                ],
              ),
            ),
    );
  }

  Widget _buildDropdown(
  String label,
  Map<String, dynamic> row,
  String key,
  List<LookupItem> items,
) {
  return DropdownButtonFormField<String>(
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    value: row[key].isNotEmpty ? row[key] : null,
    isExpanded: true, // ✅ Biar dropdown menyesuaikan lebar parent
    items: items
        .map(
          (e) => DropdownMenuItem(
            value: e.name,
            child: Text(
              e.name,
              overflow: TextOverflow.ellipsis, // ✅ Potong teks panjang dengan "..."
              maxLines: 1,
            ),
          ),
        )
        .toList(),
    onChanged: _isReadOnly() ? null : (val) => setState(() => row[key] = val ?? ""),
  );
}

}
