import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/api.dart';
import './tambahreport.dart';
import './detailreport.dart';
import './reviewreport.dart';
import '../core/theme/app_theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool loading = true;
  List<Report> reports = [];
  List<Report> filteredReports = [];
  List<String> userRoles = [];
  List<int>? selectedStatusIds; // null = semua

  // Mapping status ID sesuai database kamu
  final statusIds = {
    "proses": [1, 2, 3, 4, 5],
    "selesai": [6],
    "ditolak": [7],
  };

  bool hasRole(String role) => userRoles.contains(role);

  @override
  void initState() {
    super.initState();
    loadUserRoles();
    fetchReports();
  }

  Future<void> loadUserRoles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final userMap = jsonDecode(userString);
      final roles = userMap['roles'];
      if (roles != null && roles is List) {
        userRoles = roles.map((e) => e.toString()).toList();
      }
    }
    setState(() {});
  }

  Future<void> fetchReports() async {
    setState(() => loading = true);
    try {
      final data = await API.reports.list();
      print("=== Data dari API ===");
      print(data); // 🧩 tambahkan ini
      setState(() {
        reports = data.cast<Report>();
        filterReports();
      });
    } catch (e) {
      print("Gagal ambil data report: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal memuat data report")));
    } finally {
      setState(() => loading = false);
    }
  }

  void filterReports() {
    if (selectedStatusIds == null) {
      filteredReports = List.from(reports);
    } else {
      filteredReports = reports.where((r) {
        int? id;

        // Debug: lihat isi statusId setiap report
        print("Status ID mentah: ${r.statusId} (${r.statusId.runtimeType})");

        if (r.statusId is String) {
          id = int.tryParse(r.statusId as String);
        } else if (r.statusId is int) {
          id = r.statusId;
        }

        // Debug: cek apakah lolos filter
        final match = id != null && selectedStatusIds!.contains(id);
        print("Report ${r.noReport} => id=$id, match=$match");

        return match;
      }).toList();
    }

    print("=== Filter selesai, jumlah data: ${filteredReports.length} ===");
    setState(() {});
  }

  Future<void> updateReportStatus(int reportId, int statusId) async {
    try {
      await API.reports.update(reportId, {"status_id": statusId});
      await fetchReports();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Status report berhasil diperbarui")),
      );
    } catch (e) {
      print("Gagal update status report: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal memperbarui status report")),
      );
    }
  }

  Widget buildFilterButtons() {
    final filters = [
      {"label": "Semua", "status": null},
      {"label": "Proses", "ids": statusIds["proses"]},
      {"label": "Selesai", "ids": statusIds["selesai"]},
      {"label": "Ditolak", "ids": statusIds["ditolak"]},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: AppColors.canvas,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final ids = f["ids"] as List<int>?;
            final isActive =
                selectedStatusIds == ids ||
                (selectedStatusIds == null && ids == null);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ChoiceChip(
                label: Text(f["label"] as String),
                selected: isActive,
                labelStyle: TextStyle(
                  color: isActive ? Colors.white : AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
                onSelected: (_) {
                  setState(() {
                    selectedStatusIds = ids;
                  });
                  filterReports();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget reportCard(Report report) {
    final statusColor = _statusColor(report.statusName);
    final canReview =
        report.statusName.toLowerCase() == 'requested' &&
        (hasRole('Admin') || hasRole('Superintendent'));

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailScreen(reportId: report.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.description_outlined, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.noReport,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.requestedByName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(label: report.statusName, color: statusColor),
                ],
              ),
              const SizedBox(height: 14),
              _InfoRow(
                icon: Icons.place_outlined,
                text: report.location ?? '-',
              ),
              const SizedBox(height: 8),
              _InfoRow(icon: Icons.notes_rounded, text: report.remark ?? '-'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PersonChip(
                    icon: Icons.science_outlined,
                    label: 'Sampler',
                    value: report.samplerName,
                  ),
                  _PersonChip(
                    icon: Icons.analytics_outlined,
                    label: 'Analyst',
                    value: report.analystName,
                  ),
                ],
              ),
              if (canReview)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Konfirmasi Penolakan'),
                              content: const Text(
                                'Apakah Anda yakin ingin menolak report ini?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Ya, Tolak'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await updateReportStatus(report.id, 7);
                          }
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ReportReviewScreen(report: report),
                            ),
                          );
                          if (result == true) {
                            fetchReports();
                          }
                        },
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: const Text('Review'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'in progress':
        return AppColors.accent;
      case 'closed':
        return const Color(0xFF64748B);
      case 'rejected':
        return AppColors.danger;
      case 'requested':
        return AppColors.success;
      case 'pending review':
        return AppColors.info;
      case 'revision':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF0891B2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report")),
      body: Column(
        children: [
          buildFilterButtons(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredReports.isEmpty
                ? const Center(child: Text("Tidak ada report"))
                : RefreshIndicator(
                    onRefresh: fetchReports,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 92),
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) =>
                          reportCard(filteredReports[index]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportAddScreen()),
          );
          if (result == true) {
            fetchReports();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.muted, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
