import 'package:flutter/material.dart';
import '../../helper/api.dart';
import 'adduser.dart';
import 'updateuser.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _loading = false;
  bool _initialized = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _loadUsers();
      _initialized = true;
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final users = await API.users.list();
      setState(() {
        _users = users;
        _filteredUsers = users; // simpan semua user untuk pencarian
      });
    } catch (e) {
      print("Gagal ambil users: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterUsers(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((u) {
        final nameMatch = u.name.toLowerCase().contains(lowerQuery);
        final emailMatch = (u.email ?? '').toLowerCase().contains(lowerQuery);
        return nameMatch || emailMatch;
      }).toList();
    });
  }

  Future<void> _deleteUser(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Yakin ingin menghapus user ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await API.users.delete(id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User berhasil dihapus")),
        );
        _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menghapus user: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Manajemen User"),
        backgroundColor: const Color(0xFF1E7D3E),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : Column(
              children: [
                // 🔍 Search Bar
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterUsers,
                    decoration: InputDecoration(
                      hintText: 'Cari user berdasarkan nama atau email...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: _filteredUsers.isEmpty
                        ? const Center(child: Text("Tidak ada user ditemukan"))
                        : ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final u = _filteredUsers[index];
                              return Card(
                                color: Colors.grey[200],
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                child: ListTile(
                                  title: Text(
                                    u.name,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                  subtitle: Text(
                                    "${u.email ?? '-'}\nDept: ${u.departmentName ?? '-'}\nRole: ${u.roles?.join(', ') ?? '-'}",
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                  isThreeLine: true,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditUserScreen(user: u),
                                            ),
                                          );
                                          if (result == true) _loadUsers();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteUser(u.id),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddUserScreen()),
          );
          if (result == true) _loadUsers();
        },
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
