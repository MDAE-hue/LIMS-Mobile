import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../helper/api.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool loading = true;

  Map<String, dynamic> stats = {};
  List<Report> reports = [];

  final List<String> statusLabels = const [
    'Requested',
    'In Progress',
    'Pending Review',
    'Revision',
    'Pending Acknowledge',
    'Closed',
    'Rejected',
  ];

  final List<Color> baseColors = const [
    AppColors.info,
    AppColors.accent,
    AppColors.success,
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFF64748B),
    AppColors.danger,
  ];

  List<double> pieData = [];
  List<List<double>> weeklyData = [];
  List<List<double>> monthlyData = [];

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() => loading = true);
    try {
      final reportStats = await API.reports.getReportStats();
      final reportList = await API.reports.list();

      stats = reportStats;
      reports = reportList;

      pieData = [
        (stats['requested'] ?? 0).toDouble(),
        (stats['in_progress'] ?? 0).toDouble(),
        (stats['pending_review'] ?? 0).toDouble(),
        (stats['revision'] ?? 0).toDouble(),
        (stats['pending_acknowledge'] ?? 0).toDouble(),
        (stats['closed'] ?? 0).toDouble(),
        (stats['rejected'] ?? 0).toDouble(),
      ];

      weeklyData = _calculateWeeklyData();
      monthlyData = _calculateMonthlyData();

      setState(() => loading = false);
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
      setState(() => loading = false);
    }
  }

  List<List<double>> _calculateWeeklyData() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 6));
    final weekDays = List.generate(7, (i) => weekAgo.add(Duration(days: i)));
    final weekly = List.generate(
      statusLabels.length,
      (_) => List.filled(7, 0.0),
    );

    for (final report in reports) {
      if (report.createdAt == null) continue;
      for (var i = 0; i < 7; i++) {
        if (_isSameDay(report.createdAt!, weekDays[i])) {
          final idx = _getStatusIndex(report.statusName.toLowerCase());
          if (idx != -1) weekly[idx][i]++;
        }
      }
    }
    return weekly;
  }

  List<List<double>> _calculateMonthlyData() {
    final year = DateTime.now().year;
    final monthly = List.generate(
      statusLabels.length,
      (_) => List.filled(12, 0.0),
    );

    for (final report in reports) {
      if (report.createdAt == null || report.createdAt!.year != year) continue;
      final idx = _getStatusIndex(report.statusName.toLowerCase());
      if (idx != -1) monthly[idx][report.createdAt!.month - 1]++;
    }

    return monthly;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _getStatusIndex(String statusName) {
    for (var i = 0; i < statusLabels.length; i++) {
      if (statusLabels[i].toLowerCase().replaceAll(' ', '_') ==
          statusName.replaceAll(' ', '_')) {
        return i;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: fetchDashboardData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader()),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverList.list(
                        children: [
                          _buildStatusCards(stats),
                          const SizedBox(height: 16),
                          _buildPieChartCard(statusLabels, baseColors, pieData),
                          const SizedBox(height: 16),
                          _buildLineChartCard(
                            title: 'Perkembangan Mingguan',
                            labels: const [
                              'Sen',
                              'Sel',
                              'Rab',
                              'Kam',
                              'Jum',
                              'Sab',
                              'Min',
                            ],
                            data: weeklyData,
                            baseColors: baseColors,
                            statusLabels: statusLabels,
                          ),
                          const SizedBox(height: 16),
                          _buildLineChartCard(
                            title: 'Perkembangan Bulanan',
                            labels: const [
                              'Jan',
                              'Feb',
                              'Mar',
                              'Apr',
                              'Mei',
                              'Jun',
                              'Jul',
                              'Agu',
                              'Sep',
                              'Okt',
                              'Nov',
                              'Des',
                            ],
                            data: monthlyData,
                            baseColors: baseColors,
                            statusLabels: statusLabels,
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.biotech_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ringkasan aktivitas LIMS',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: fetchDashboardData,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${stats['total'] ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total report tercatat',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards(Map<String, dynamic> stats) {
    final items = [
      _StatusItem(
        'Requested',
        stats['requested'] ?? 0,
        AppColors.info,
        Icons.outbox_rounded,
      ),
      _StatusItem(
        'In Progress',
        stats['in_progress'] ?? 0,
        AppColors.accent,
        Icons.hourglass_top_rounded,
      ),
      _StatusItem(
        'Review',
        stats['pending_review'] ?? 0,
        AppColors.success,
        Icons.fact_check_outlined,
      ),
      _StatusItem(
        'Revision',
        stats['revision'] ?? 0,
        const Color(0xFF7C3AED),
        Icons.edit_note_rounded,
      ),
      _StatusItem(
        'Pending Ack.',
        stats['pending_acknowledge'] ?? 0,
        const Color(0xFF0891B2),
        Icons.mark_email_unread_outlined,
      ),
      _StatusItem(
        'Closed',
        stats['closed'] ?? 0,
        const Color(0xFF64748B),
        Icons.task_alt_rounded,
      ),
      _StatusItem(
        'Rejected',
        stats['rejected'] ?? 0,
        AppColors.danger,
        Icons.block_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 620;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 3 : 2,
            childAspectRatio: isWide ? 2.7 : 2.05,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _StatusCard(item: items[index]),
        );
      },
    );
  }

  Widget _buildPieChartCard(
    List<String> labels,
    List<Color> colors,
    List<double> values,
  ) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = values.fold(0.0, (sum, item) => sum + item);

    return _ChartPanel(
      title: 'Distribusi Status',
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 52,
                borderData: FlBorderData(show: false),
                sections: List.generate(labels.length, (i) {
                  final percent = total == 0 ? 0 : values[i] / total * 100;
                  return PieChartSectionData(
                    value: values[i],
                    color: colors[i],
                    title: total == 0 || percent < 5
                        ? ''
                        : '${percent.toStringAsFixed(0)}%',
                    radius: 58,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Legend(labels: labels, colors: colors),
        ],
      ),
    );
  }

  Widget _buildLineChartCard({
    required String title,
    required List<String> labels,
    required List<List<double>> data,
    required List<Color> baseColors,
    required List<String> statusLabels,
  }) {
    if (data.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxLen = data.fold<int>(0, (prev, el) => max(prev, el.length));
    final maxY = data.expand((series) => series).fold<double>(0, max);
    final yInterval = maxY <= 5 ? 1.0 : (maxY / 4).ceilToDouble();

    final allSpots = List.generate(statusLabels.length, (i) {
      return List.generate(maxLen, (j) {
        final y = j < data[i].length ? data[i][j] : 0.0;
        return FlSpot(j.toDouble(), y);
      });
    });

    return _ChartPanel(
      title: title,
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY == 0 ? 5 : maxY + yInterval,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.line, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: yInterval,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[index],
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: const LineTouchData(enabled: true),
                lineBarsData: List.generate(statusLabels.length, (i) {
                  final color = baseColors[i];
                  return LineChartBarData(
                    isCurved: true,
                    preventCurveOverShooting: true,
                    color: color,
                    barWidth: 2.8,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.08),
                    ),
                    spots: allSpots[i],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _Legend(labels: statusLabels, colors: baseColors),
        ],
      ),
    );
  }
}

class _StatusItem {
  const _StatusItem(this.label, this.value, this.color, this.icon);

  final String label;
  final dynamic value;
  final Color color;
  final IconData icon;
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.item});

  final _StatusItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.value.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.labels, required this.colors});

  final List<String> labels;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: List.generate(labels.length, (i) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: colors[i],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              labels[i],
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }),
    );
  }
}
