class ReportModel {
  final int id;
  final String noReport;
  final String? location;
  final int? statusId;

  const ReportModel({
    required this.id,
    required this.noReport,
    this.location,
    this.statusId,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] as int,
      noReport: json['no_report']?.toString() ?? '-',
      location: json['location']?.toString(),
      statusId: json['status_id'] is int
          ? json['status_id'] as int
          : int.tryParse(json['status_id']?.toString() ?? ''),
    );
  }
}
