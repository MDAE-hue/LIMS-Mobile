// lib/Screen/lab_task/lab_task_tab.dart
import 'package:flutter/material.dart';
import 'lab_task_detail.dart';
import '../../helper/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LabTaskTab extends StatefulWidget {
  final int roleId; // 1: Sampler, 2: Analyst, 3: Superintendent, 4: Admin, 5: User, 6: Manager

  const LabTaskTab({super.key, required this.roleId});

  @override
  State<LabTaskTab> createState() => _LabTaskTabState();
}

class _LabTaskTabState extends State<LabTaskTab> {
  bool loading = false;
  List<Report> samplerReports = [];
  List<Report> analystReports = [];
  String? currentUserRoleName;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserName = prefs.getString('name') ?? '';

      final allReports = await API.reports.list();

      currentUserRoleName = _getRoleNameForDetail();
      debugPrint("🧭 Role login: $currentUserRoleName");

      samplerReports = [];
      analystReports = [];

      if (widget.roleId == 4 || widget.roleId == 3 || widget.roleId == 6) {
        final filteredReports = allReports.where((r) =>
            (r.samplerName != '-' && r.samplerName.trim().isNotEmpty) &&
            (r.analystName != '-' && r.analystName.trim().isNotEmpty)
        ).toList();

        samplerReports = filteredReports;
        analystReports = filteredReports;
      } else {
        for (var report in allReports) {
          if (report.samplerName == currentUserName ||
              report.analystName == currentUserName) {
            samplerReports.add(report);
            analystReports.add(report);
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetch reports: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade600;
      case 'in progress':
        return Colors.orange.shade600;
      case 'rejected':
        return Colors.red.shade600;
      case 'pending':
      default:
        return Colors.grey.shade500;
    }
  }

  Widget _buildStatusChip(String status) {
    return Chip(
      label: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: _getStatusColor(status),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildCard(String title, List<Report> reports) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: ExpansionTile(
          initiallyExpanded: true,
          collapsedBackgroundColor: Colors.grey.shade100,
          iconColor: Colors.blueGrey.shade700,
          collapsedIconColor: Colors.blueGrey.shade500,
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          children: [
            if (reports.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Tidak ada laporan yang tersedia.'),
              )
            else
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final r = reports[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        debugPrint("📄 Membuka detail report ID: ${r.id}, Role: $currentUserRoleName");
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LabTaskDetailScreen(
                              reportId: r.id,
                              role: currentUserRoleName ?? 'User',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.assignment, size: 18, color: Colors.blueGrey),
                                const SizedBox(width: 6),
                                Text(
                                  r.noReport,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  "Sampler: ${r.samplerName}",
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  "Analyst: ${r.analystName}",
                                  style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.label_important, size: 15, color: Colors.grey),
                                const SizedBox(width: 6),
                                const Text(
                                  "Status:",
                                  style: TextStyle(color: Colors.black54, fontSize: 12),
                                ),
                                const SizedBox(width: 6),
                                _buildStatusChip(r.statusName),
                              ],
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
      ),
    );
  }

  String _getRoleNameForDetail() {
    switch (widget.roleId) {
      case 1:
        return "Sampler";
      case 2:
        return "Analyst";
      case 3:
        return "Superintendent";
      case 4:
        return "Admin";
      case 5:
        return "User";
      case 6:
        return "Manager";
      default:
        return "User";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E7D3E), // warna logo Kaltim Parna Industri
        title: const Text(
          'Lab Task',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey.shade50,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReports,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildCard("Sampler Task", samplerReports),
                    _buildCard("Analyst Task", analystReports),
                  ],
                ),
              ),
            ),
    );
  }
}
