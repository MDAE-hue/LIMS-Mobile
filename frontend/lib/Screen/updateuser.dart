import 'package:flutter/material.dart';
import '../helper/api.dart'; // sesuaikan path

class EditUserScreen extends StatefulWidget {
  final User user;
  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _npkCtrl = TextEditingController();
  final TextEditingController _jobCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();

  int? _selectedDepartment;
  List<int> _selectedRoleIds = [];

  List<LookupItem> _departments = [];
  List<LookupItem> _roles = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Set nilai awal dari user
      _nameCtrl.text = widget.user.name;
      _emailCtrl.text = widget.user.email ?? '';
      _npkCtrl.text = widget.user.npk?.toString() ?? '';
      _jobCtrl.text = widget.user.jobTitle ?? '';

      _selectedDepartment = widget.user.departmentId;
      _selectedRoleIds = List<int>.from(widget.user.rolesIds);

      // Ambil dropdown data
      final depts = await API.departments.list();
      final roles = await API.roles.list();

      setState(() {
        _departments = depts;
        _roles = roles;
        loading = false;
      });
    } catch (e) {
      print("Gagal load data: $e");
      setState(() => loading = false);
    }
  }

Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  final body = {
  'name': _nameCtrl.text.trim(),
  'email': _emailCtrl.text.trim(),
  'npk': _npkCtrl.text.trim(), // jadikan string aja biar aman
  'job_title': _jobCtrl.text.trim(),
  'department_id': _selectedDepartment.toString(),
  'roles': _selectedRoleIds, // kirim array tetap array
};

  // kalau ada password, baru kirim
  if (_passwordCtrl.text.isNotEmpty) {
  body['password'] = _passwordCtrl.text.trim();
}


  print("=== BODY UPDATE USER ===");
  print(body); // <--- cek apa yang dikirim ke API

  try {
    await API.users.update(widget.user.id, body);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User berhasil diperbarui"))
    );
    Navigator.pop(context, true);
  } catch (e) {
    print("Gagal update user: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gagal memperbarui user"))
    );
  }
}


  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit User")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: "Nama"),
                validator: (v) => v == null || v.isEmpty ? "Nama wajib diisi" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: "Email"),
                validator: (v) => v == null || v.isEmpty ? "Email wajib diisi" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _npkCtrl,
                decoration: const InputDecoration(labelText: "NPK"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _jobCtrl,
                decoration: const InputDecoration(labelText: "Job Title"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(
                    labelText: "Password (kosongkan jika tidak diubah)"),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedDepartment,
                decoration: const InputDecoration(labelText: "Department"),
                items: _departments
                    .map((d) => DropdownMenuItem<int>(
                          value: d.id,
                          child: Text(d.name),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedDepartment = v),
              ),
              const SizedBox(height: 16),
              const Text("Roles", style: TextStyle(fontWeight: FontWeight.bold)),
              ..._roles.map((role) {
                final selected = _selectedRoleIds.contains(role.id);
                return CheckboxListTile(
                  title: Text(role.name),
                  value: selected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedRoleIds.add(role.id);
                      } else {
                        _selectedRoleIds.remove(role.id);
                      }
                    });
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Simpan Perubahan"),
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
