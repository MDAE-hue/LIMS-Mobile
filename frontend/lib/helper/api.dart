import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';

// -------------------- Models --------------------
class User {
  int id;
  String name;
  List<String>? roles;
  String? email;
  int? departmentId;
  String? departmentName;
  List<int>? _roleIds; // simpan ID role jika tersedia dari API

  // --- tambahan field yang dibutuhkan oleh updateuser.dart ---
  int? npk;
  String? jobTitle;
  int? superiorId; // opsional: kalau backend mengirim superior_id

  User({
    required this.id,
    required this.name,
    this.roles,
    this.email,
    this.departmentId,
    this.departmentName,
    List<int>? roleIds,
    this.npk,
    this.jobTitle,
    this.superiorId,
  }) : _roleIds = roleIds;

  factory User.fromJson(Map<String, dynamic> json) {
    List<String>? parsedRoles;
    List<int>? parsedRoleIds;

    if (json['roles'] != null) {
      parsedRoles = (json['roles'] as List)
          .map((r) => r is String ? r : (r['name']?.toString() ?? ''))
          .toList();

      parsedRoleIds = (json['roles'] as List)
          .map((r) => r is Map && r['id'] != null ? r['id'] as int : null)
          .whereType<int>()
          .toList();
    }

    // Ambil nama departemen jika ada relasi "department"
    String? deptName;
    if (json['department'] != null) {
      if (json['department'] is Map && json['department']['name'] != null) {
        deptName = json['department']['name'];
      }
    }

    // parse npk (bisa int atau string)
    int? parsedNpk;
    if (json.containsKey('npk') && json['npk'] != null) {
      if (json['npk'] is int) parsedNpk = json['npk'] as int;
      else parsedNpk = int.tryParse(json['npk'].toString());
    }

    // parse job_title (beberapa API pakai job_title)
    String? parsedJobTitle = json['job_title'] ?? json['jobTitle'];

    // parse superior_id jika ada
    int? parsedSuperiorId;
    if (json.containsKey('superior_id') && json['superior_id'] != null) {
      if (json['superior_id'] is int) parsedSuperiorId = json['superior_id'] as int;
      else parsedSuperiorId = int.tryParse(json['superior_id'].toString());
    }

    return User(
      id: json['id'],
      name: json['name'],
      roles: parsedRoles,
      email: json['email'],
      departmentId: json['department_id'],
      departmentName: deptName,
      roleIds: parsedRoleIds,
      npk: parsedNpk,
      jobTitle: parsedJobTitle,
      superiorId: parsedSuperiorId,
    );
  }

  // ✅ Getter baru agar tidak error saat diakses
  List<int> get rolesIds => _roleIds ?? [];
}


class Report {
  int id;
  String noReport;
  String? remark;
  String? location;
  int? departmentId;
  Map<String, dynamic>? department; // ambil object department
  int? statusId;
  Map<String, dynamic>? status; // ambil object status
  Map<String, dynamic>? raw;
  DateTime? createdAt;

  Report({
    required this.id,
    required this.noReport,
    this.remark,
    this.location,
    this.departmentId,
    this.department,
    this.statusId,
    this.status,
    this.raw,
    this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) => Report(
    id: json['id'],
    noReport: json['no_report'] ?? "-",
    remark: json['remark'],
    location: json['location'],
    departmentId: json['department_id'],
    department: json['department'],
    statusId: json['status_id'], 
    status: json['status'],
    raw: json,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'])
        : null,
  );

  // Getter untuk nama departemen
  String get departmentName => department?['name'] ?? '-';

  // Getter untuk nama status
  String get statusName => status?['name'] ?? '-';

  String get requestedByName => raw?['requested_by_name'] ?? '-';
  String get samplerName => raw?['sampler_name'] ?? '-';
  String get analystName => raw?['analyst_name'] ?? '-';
}

class TestDetail {
  int? id;
  int? reportId;
  String? bahanPengujian;
  int? testTypeId;
  int? methodId;
  int? standardId;
  String? result;
  String? description;
  int? unitId;

  TestDetail.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        reportId = json['report_id'],
        bahanPengujian = json['bahan_pengujian'],
        testTypeId = json['test_type_id'],
        methodId = json['method_id'],
        standardId = json['standard_id'],
        result = json['result'],
        description = json['description'],
        unitId = json['unit_id'];
}

class LookupItem {
  int id;
  String name;

  LookupItem({required this.id, required this.name});

  factory LookupItem.fromJson(Map<String, dynamic> json) =>
      LookupItem(id: json['id'], name: json['name']);
}


// -------------------- Config --------------------
// const String BASE_URL = "http://10.249.103.190:8000/api";
const String BASE_URL = "http://10.0.2.2:8000/api";
// const String BASE_URL = "http://localhost:8000/api";
// const String BASE_URL = "http://10.222.80.190:8000/api";

// -------------------- Helper --------------------
Future<String> _getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("token") ?? "";
}

Future<Map<String, dynamic>> _apiFetchMap(
  String endpoint, {
  String method = "GET",
  Map<String, dynamic>? body,
  int retries = 2,
}) async {
  try {
    return await _apiFetchMapInternal(endpoint, method: method, body: body);
  } catch (e) {
    if (retries > 0) {
      print("Retrying $_apiFetchMap ($retries retries left) due to: $e");
      // Tunggu sebentar sebelum retry, misal 500ms
      await Future.delayed(Duration(milliseconds: 500));
      return _apiFetchMap(
        endpoint,
        method: method,
        body: body,
        retries: retries - 1,
      );
    }
    rethrow;
  }
}

Future<Map<String, dynamic>> _apiFetchMapInternal(
  String endpoint, {
  String method = "GET",
  Map<String, dynamic>? body,
}) async {
  final token = await _getToken();
  final headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  final url = Uri.parse(
    endpoint.startsWith("/") ? "$BASE_URL$endpoint" : "$BASE_URL/$endpoint",
  );

  late http.Response res;
  try {
    switch (method.toUpperCase()) {
      case "POST":
        res = await http.post(url, headers: headers, body: jsonEncode(body));
        break;
      case "PUT":
        res = await http.put(url, headers: headers, body: jsonEncode(body));
        break;
      case "DELETE":
        res = await http.delete(url, headers: headers);
        break;
      default:
        res = await http.get(url, headers: headers);
    }
  } catch (e) {
    throw Exception("Request gagal: $e");
  }

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception("Request gagal (${res.statusCode}): ${res.body}");
  }

  // --- Robust JSON decoding ---
  String raw = res.body.trim();

  if (raw.isEmpty) throw Exception("Response kosong");

  // Hapus karakter sebelum '[' atau '{'
  final jsonStart = raw.indexOf(RegExp(r'[\[\{]'));
  if (jsonStart < 0) throw Exception("Response bukan JSON valid: ${res.body}");
  raw = raw.substring(jsonStart);

  // Perbaiki typo common (misal 'nll' → null)
  raw = raw.replaceAll(RegExp(r'\bnll\b'), 'null');
  raw = raw.replaceAll(RegExp(r'\"(\w+)\"null'), r'"\1": null');

  dynamic decoded;
  try {
    decoded = jsonDecode(raw);
  } catch (e) {
    throw Exception("JSON decode error: $e\nResponse: $raw");
  }

  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is List) return {'data': decoded};

  throw Exception("Response bukan JSON valid: ${res.body}");
}

// -------------------- Normalize --------------------
List<T> fromJsonList<T>(
  dynamic payload,
  T Function(Map<String, dynamic>) fromJson,
) {
  final List<T> result = [];
  if (payload == null) return result;

  Iterable items;
  if (payload is List) {
    items = payload;
  } else if (payload is Map<String, dynamic>) {
    if (payload['data'] is List)
      items = payload['data'];
    else if (payload['users'] is List)
      items = payload['users'];
    else if (payload['reports'] is List)
      items = payload['reports'];
    else
      return [fromJson(payload)];
  } else {
    return [];
  }

  for (var e in items) {
    try {
      result.add(fromJson(e as Map<String, dynamic>));
    } catch (ex) {
      // Log saja tapi lanjutkan
      print("Gagal parse item: $ex\nItem: $e");
    }
  }
  return result;
}

// -------------------- Auth API --------------------
class AuthApi {
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _apiFetchMap(
      "/login",
      method: "POST",
      body: {"email": email, "password": password},
    );
  }

  Future<Map<String, dynamic>> me() async {
    return await _apiFetchMap("/me");
  }

  Future<void> logout() async {
    await _apiFetchMap("/logout", method: "POST");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }
}

// -------------------- USERS API --------------------
class UserApi {
  Future<List<User>> list() async {
    final data = await _apiFetchMap("/users");
    return fromJsonList(data, (json) => User.fromJson(json));
  }

 Future<User?> detail(int id) async {
    final data = await _apiFetchMap("/users/$id");
    final map = data['data'] ?? data;
    if (map is Map<String, dynamic>) {
      return User.fromJson(map);
    }
    return null;
  }

  Future<void> delete(int id) async {
    await _apiFetchMap("/users/$id", method: "DELETE");
  }

Future<Map<String, dynamic>> create(Map<String, dynamic> body) async {
  if (body["roles"] is List) {
    body["roles"] = (body["roles"] as List)
        .map((e) => e is int ? e : int.tryParse(e.toString()))
        .whereType<int>()
        .toList();
  }

  // Langsung return karena _apiFetchMap() sudah pasti Map<String, dynamic>
  return await _apiFetchMap("/users", method: "POST", body: body);
}




  Future<void> update(int id, Map<String, dynamic> body) async {
    if (body["roles"] is List) {
      body["roles"] = (body["roles"] as List)
          .map((e) => e is int ? e : int.tryParse(e.toString()))
          .whereType<int>()
          .toList();
    }

    // Hapus key yang nilainya null
    body.removeWhere((key, value) => value == null);

    await _apiFetchMap("/users/$id", method: "PUT", body: body);
  }
  
  
}

// -------------------- Reports API --------------------
class ReportApi {

  Future<List<Report>> list() async {
    final data = await _apiFetchMap("/laboratory/reports");
    return fromJsonList(data, (json) => Report.fromJson(json));
  }

  Future<Report?> detail(int id) async {
    final data = await _apiFetchMap("/laboratory/reports/$id");
    final map = data['report'] ?? data;
    return Report.fromJson(map);
  }

  
  Future<void> create(Map<String, dynamic> body) async {
    await _apiFetchMap("/laboratory/reports", method: "POST", body: body);
  }

  Future<Report> update(int id, Map<String, dynamic> body) async {
    final data = await _apiFetchMap("/laboratory/reports/$id", method: "PUT", body: body);
    final map = data['report'] ?? data;
    return Report.fromJson(map);
  }

  Future<void> previewCoA(int reportId) async {
  final token = await _getToken();
  final url = "$BASE_URL/laboratory/reports/$reportId/coa";
  final uri = Uri.parse(url);

  // Tambahkan token ke header agar tidak 401
  final headers = {
    'Authorization': 'Bearer $token',
    'Accept': 'application/pdf',
  };

  // Gunakan launchUrl dengan header authorization
  final pdfUrl = Uri.parse("$url?token=$token");

  if (await canLaunchUrl(pdfUrl)) {
    await launchUrl(pdfUrl, mode: LaunchMode.externalApplication);
  } else {
    throw Exception("Tidak bisa membuka CoA");
  }
}


    Future<String?> downloadCoAFile(int reportId) async {
    final token = await _getToken();
    final url = Uri.parse("$BASE_URL/laboratory/reports/$reportId/coa");
    
    try {
      final response = await http.get(url, headers: {
        'Accept': 'application/pdf',
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/coa_report_$reportId.pdf';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return filePath;
      } else {
        print('Gagal mengunduh laporan CoA (${response.statusCode})');
        return null;
      }
    } catch (e) {
      print('Error saat mengunduh CoA: $e');
      return null;
    }
  }


    // -------------------- Dashboard Stats --------------------
  Future<Map<String, dynamic>> getReportStats() async {
  final res = await _apiFetchMap("/laboratory/reports/stats");

  // cek apakah hasilnya bersarang di dalam "data"
  final data = res['data'] ?? res;

  return {
    'total': data['total'] ?? 0,
    'requested': data['requested'] ?? 0,
    'in_progress': data['in_progress'] ?? 0,
    'pending_review': data['pending_review'] ?? 0,
    'revision': data['revision'] ?? 0,
    'pending_acknowledge': data['pending_acknowledge'] ?? 0,
    'closed': data['closed'] ?? 0,
    'rejected': data['rejected'] ?? 0,
  };
}

  Future<Map<String, int>> getWeeklyAndMonthlyReportCounts() async {
    final reports = await list(); // Ambil semua laporan
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    int weeklyCount = 0;
    int monthlyCount = 0;

    for (var report in reports) {
      final createdAt = report.createdAt; // pastikan ada di model Report
      if (createdAt != null) {
        if (createdAt.isAfter(weekAgo)) weeklyCount++;
        if (createdAt.isAfter(monthAgo)) monthlyCount++;
      }
    }

    return {
      'weekly': weeklyCount,
      'monthly': monthlyCount,
    };
  }

  Future<bool> takeAction(int reportId, Map<String, dynamic> payload) async {
  final token = await _getToken();
  final url = Uri.parse("$BASE_URL/laboratory/reports/$reportId/take-action");

  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      print("Report $reportId berhasil di-take action: ${response.body}");
      return true;
    } else {
      print("Gagal take action (${response.statusCode}): ${response.body}");
      return false;
    }
  } catch (e) {
    print("Error take action: $e");
    return false;
  }
}

// -------------------- Submit Review --------------------
  Future<bool> submitReview(
  int reportId, {
  required String action, // 'approve' atau 'revision'
  String? comment,
}) async {
  final token = await _getToken();
  final url = Uri.parse("$BASE_URL/laboratory/reports/$reportId/submit-review");

  try {
    // 🟢 Kalau approve: tidak kirim comment maupun remark
    final Map<String, dynamic> body = {
      'action': action,
    };

    // 🟠 Kalau revision: kirim comment saja (remark tidak pernah dikirim)
    if (action == 'revision' && comment != null && comment.isNotEmpty) {
      body['comment'] = comment;
    }

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print("✅ Submit review berhasil untuk report $reportId");
      return true;
    } else {
      print("❌ Gagal submit review (${response.statusCode}): ${response.body}");
      return false;
    }
  } catch (e) {
    print("⚠️ Error saat submit review: $e");
    return false;
  }
}


 Future<bool> approveReport(int reportId) async {
  final token = await _getToken();
  final url = Uri.parse("$BASE_URL/laboratory/reports/$reportId/approve");

  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print("✅ Report $reportId berhasil di-approve");
      return true;
    } else {
      print("❌ Gagal approve report (${response.statusCode}): ${response.body}");
      return false;
    }
  } catch (e, stacktrace) {
    print("⚠️ Error saat approve report: $e");
    print(stacktrace);
    return false;
  }
}

}

// -------------------- Report Status API --------------------
class ReportStatusApi {
  Map<int, String> _statusMap = {};

  // Fetch semua status dari backend
  Future<void> fetchStatusMap() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$BASE_URL/report-statuses'), // <-- sesuaikan endpoint backend
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) throw Exception('Gagal ambil status');
    final list = jsonDecode(res.body) as List;
    _statusMap = {for (var e in list) e['id']: e['name']};
  }

  // Ambil nama status berdasarkan ID
  String getStatusName(int? id) => _statusMap[id] ?? '-';

  // Opsional: ambil seluruh map
  Map<int, String> get allStatus => _statusMap;
}


// -------------------- Test API --------------------
class TestApi {
  Future<List<TestDetail>> getByReport(int reportId) async {
    final data = await _apiFetchMap(
      "/laboratory/reports/$reportId/test-details",
    );
    if (data['data'] is List) {
      return (data['data'] as List).map((e) => TestDetail.fromJson(e)).toList();
    }
    return [];
  }

  Future<TestDetail?> create(Map<String, dynamic> payload) async {
    final data = await _apiFetchMap(
      "/test-details",
      method: "POST",
      body: payload,
    );
    return TestDetail.fromJson(data);
  }

  Future<TestDetail?> update(int id, Map<String, dynamic> payload) async {
    final data = await _apiFetchMap(
      "/test-details/$id",
      method: "PUT",
      body: payload,
    );
    return TestDetail.fromJson(data);
  }

}

// -------------------- Lookup API --------------------
class LookupApi {
  Future<List<LookupItem>> getMethods() async {
    final data = await _apiFetchMap("/methods");
    if (data['data'] is List) {
      return (data['data'] as List)
          .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<LookupItem>> getStandards() async {
    final data = await _apiFetchMap("/standards");
    if (data['data'] is List) {
      return (data['data'] as List)
          .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<LookupItem>> getUnits() async {
    final data = await _apiFetchMap("/units");
    if (data['data'] is List) {
      return (data['data'] as List)
          .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<LookupItem>> getTestTypes() async {
    final data = await _apiFetchMap("/test-types");
    if (data['data'] is List) {
      return (data['data'] as List)
          .map((e) => LookupItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}


// ------------------ DEPARTMENT API ------------------
class DepartmentApi {
  Future<List<LookupItem>> list() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$BASE_URL/departments'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal ambil departemen');
    }

    final data = jsonDecode(res.body);

    // Karena backend mengirim langsung array []
    final List list = data is List ? data : (data['data'] ?? []);
    return list.map((e) => LookupItem.fromJson(e)).toList();
  }
}



// ------------------ ROLE API ------------------
class RoleApi {
  Future<List<LookupItem>> list() async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse('$BASE_URL/roles'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal ambil role');
    }

    final data = jsonDecode(res.body);

    // Karena backend mengirim langsung array []
    final List list = data is List ? data : (data['data'] ?? []);
    return list.map((e) => LookupItem.fromJson(e)).toList();
  }
}

// -------------------- Tasks API --------------------
class TasksApi {
  // Ambil semua task berdasarkan roleId
  Future<List<Map<String, dynamic>>> listByRoleId(int roleId) async {
    final token = await _getToken();
    final res = await http.get(
      Uri.parse(
        '$BASE_URL/tasks?role_id=$roleId',
      ), // sesuaikan endpoint backend
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal ambil tasks untuk role $roleId');
    }

    final data = jsonDecode(res.body);
    if (data is List) return List<Map<String, dynamic>>.from(data);
    if (data['data'] is List)
      return List<Map<String, dynamic>>.from(data['data']);
    return [];
  }
}

// -------------------- Change Password API --------------------
class PasswordApi {
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await _getToken();
    final url = Uri.parse("$BASE_URL/change-password");

    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = jsonEncode({
      'oldPassword': currentPassword,
      'new_password': newPassword,
      'newPassword': newPassword,
    });

    try {
      final res = await http.post(url, headers: headers, body: body);

      // parsing hasil response
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        return data is Map<String, dynamic>
            ? data
            : {'message': 'Password berhasil diubah'};
      } else {
        final error = jsonDecode(res.body);
        return error is Map<String, dynamic>
            ? error
            : {'message': 'Gagal mengubah password'};
      }
    } catch (e) {
      return {'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }
}

  


// -------------------- API Singleton --------------------
class API {
  static final password = PasswordApi();
  static final auth = AuthApi();
  static final users = UserApi();
  static final reports = ReportApi();
  static final test = TestApi();
  static final departments = DepartmentApi();
  static final roles = RoleApi();
  static final reportStatus = ReportStatusApi();
  static final tasks = TasksApi(); // ✅ sudah masuk
}
