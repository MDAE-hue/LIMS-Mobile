import 'package:flutter/material.dart';
import '../../helper/api.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController npkController = TextEditingController();
  final TextEditingController jobTitleController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  List<dynamic> departments = [];
  List<dynamic> roles = [];
  List<dynamic> superiors = [];

  int? selectedDepartment;
  int? selectedSuperior;
  List<int> selectedRoles = [];

  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchDropdownData();
  }

 Future<void> fetchDropdownData() async {
  try {
    final depRes = await API.departments.list();
    final roleRes = await API.roles.list();
    final usersRes = await API.users.list(); // -> List<User>

    // Filter user dengan role "Superintendent"
    final filteredSuperiors = usersRes.where((user) {
      final roles = user.roles ?? [];
      return roles.contains("Superintendent");
    }).toList();

    setState(() {
      departments = depRes;
      roles = roleRes;
      superiors = filteredSuperiors;
    });
  } catch (e) {
    print("Error fetching dropdown data: $e");
  }
}



  Future<void> createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final data = {
        "name": nameController.text,
        "email": emailController.text,
        "superior": selectedSuperior,
        "npk": npkController.text,
        "job_title": jobTitleController.text,
        "password": passwordController.text,
        "department_id": selectedDepartment,
        "roles": selectedRoles,
      };

      final res = await API.users.create(data);

if (res != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("User created successfully")),
  );
  Navigator.pop(context, true);
}

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to create user: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add User")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Name"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: "Email"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    DropdownButtonFormField<int>(
                      value: selectedSuperior,
                      decoration: const InputDecoration(labelText: "Superior (optional)"),
items: superiors.map<DropdownMenuItem<int>>((u) {
  return DropdownMenuItem(
    value: u.id, // ✅ pakai properti dari class User
    child: Text(u.name),
  );
}).toList(),


                      onChanged: (value) => setState(() => selectedSuperior = value),
                    ),
                    TextFormField(
                      controller: npkController,
                      decoration: const InputDecoration(labelText: "NPK"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      controller: jobTitleController,
                      decoration: const InputDecoration(labelText: "Job Title"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: "Password"),
                      obscureText: true,
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    DropdownButtonFormField<int>(
                      value: selectedDepartment,
                      decoration: const InputDecoration(labelText: "Department"),
                      items: departments.map<DropdownMenuItem<int>>((d) {
                        return DropdownMenuItem(
                          value: d.id,
                          child: Text(d.name),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedDepartment = value),
                      validator: (v) => v == null ? "Select a department" : null,
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Roles", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    ...roles.map((role) {
                      return CheckboxListTile(
                        title: Text(role.name),
                        value: selectedRoles.contains(role.id),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              selectedRoles.add(role.id);
                            } else {
                              selectedRoles.remove(role.id);
                            }
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 20),
                    Center(
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green, // hijau
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    onPressed: loading ? null : createUser,
    child: const Text(
      "Create User",
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
),

                  ],
                ),
              ),
            ),
    );
  }
}
