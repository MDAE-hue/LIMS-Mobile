import 'package:flutter/material.dart';
import '../helper/api.dart';
import 'package:open_filex/open_filex.dart';


class ReportDetailScreen extends StatefulWidget {
  final int reportId;
  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool loading = true;
  Report? report;

  @override
  void initState() {
    super.initState();
    fetchReportDetail();
  }

  Future<void> fetchReportDetail() async {
    setState(() => loading = true);
    try {
      final data = await API.reports.detail(widget.reportId);
      setState(() => report = data);
    } catch (e) {
      print("Gagal ambil detail report: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memuat detail report")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Widget infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? '-')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detail Report")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : report == null
              ? const Center(child: Text("Report tidak ditemukan"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Card(
                        clipBehavior: Clip.hardEdge,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              infoRow("No Report", report!.noReport),
                              infoRow("Requester", report!.requestedByName),
                              infoRow("Department", report!.departmentName),
                              infoRow("Location", report!.location),
                              infoRow("Status", report!.statusName),
                              infoRow("Date Sampling", report!.raw?['date_sampling']),
                              infoRow("Date Analysis", report!.raw?['date_analysis']),
                              infoRow("Remark", report!.remark),
                              infoRow("Sampler", report!.samplerName),
                              infoRow("Analyst", report!.analystName),
                              infoRow("Reviewed By", report!.raw?['reviewed_by_name']),
                              infoRow("Notes", report!.raw?['notes']),
                              infoRow("Comment", report!.raw?['comment']),
                              infoRow("Reason", report!.raw?['reason']),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (report!.statusName != null && report!.statusName!.toLowerCase().contains("close"))
ElevatedButton.icon(
  icon: const Icon(Icons.download),
  label: const Text("Unduh Laporan CoA"),
  onPressed: () async {
    try {
      final filePath = await API.reports.downloadCoAFile(widget.reportId);
      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Laporan berhasil diunduh")),
        );
        await OpenFilex.open(filePath); // ✅ gunakan OpenFilex, bukan OpenFile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengunduh laporan CoA")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    }
  },
),

 const SizedBox(height: 10),

  // ✅ Tombol Print CoA -> direct ke detail_print.dart
  ElevatedButton.icon(
    icon: const Icon(Icons.print),
    label: const Text("Print Laporan CoA"),
    onPressed: () {
      Navigator.pushNamed(
        context,
        '/detail-print',   // route menuju detail_print.dart
        arguments: widget.reportId,
      );
    },
  ),

                    ],
                  ),
                ),
    );
  }
}
