import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Screen/tabs.dart';
import '../core/theme/app_theme.dart';
import '../helper/api.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty && password.isEmpty) {
      _showErrorDialog('Isi email dan password dulu!');
      return;
    } else if (email.isEmpty) {
      _showErrorDialog('Isi email dulu!');
      return;
    } else if (password.isEmpty) {
      _showErrorDialog('Isi password dulu!');
      return;
    }

    final emailValid = RegExp(
      r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email);
    if (!emailValid) {
      _showErrorDialog('Format email tidak valid!');
      return;
    }

    if (password.length < 6) {
      _showErrorDialog('Password minimal 6 karakter!');
      return;
    }

    setState(() => loading = true);

    try {
      final response = await API.auth.login(email, password);
      final statusCode = response['status'] ?? 200;

      if (statusCode == 422 || statusCode == 404) {
        _showErrorDialog('Email atau password salah!');
        return;
      }

      if (statusCode == 401) {
        _showErrorDialog('Terjadi kesalahan pada server.');
        return;
      }

      final token = response['token'];
      final user = response['user'];

      if (token == null || user == null) {
        _showErrorDialog('Email atau password salah!');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user', jsonEncode(user));
      await prefs.setInt('userId', user['id']);
      await prefs.setString('name', user['name']);

      final deptId = user['department_id'] ?? 0;
      final deptName = user['department_name'] ?? 'Tanpa Departemen';
      await prefs.setInt('departmentId', deptId);
      await prefs.setString('departmentName', deptName);

      final roles = user['roles'] is List
          ? List<String>.from(user['roles'])
          : <String>[];
      var roleId = 5;
      if (roles.contains('Admin')) {
        roleId = 4;
      } else if (roles.contains('Manager')) {
        roleId = 6;
      } else if (roles.contains('Superintendent')) {
        roleId = 3;
      } else if (roles.contains('Sampler')) {
        roleId = 1;
      } else if (roles.contains('Analyst')) {
        roleId = 2;
      }

      await prefs.setInt('roleId', roleId);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TabsScreen(roleId: roleId)),
      );
    } catch (e) {
      debugPrint('Login error: $e');
      _showErrorDialog('Email atau password salah!');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 8),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.biotech_outlined,
                        color: AppColors.primary,
                        size: 34,
                      ),
                    ),
                  ),
                  const Text(
                    'LIMS',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Masuk untuk melanjutkan',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
                    child: Column(
                      children: [
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: loading ? null : handleLogin,
                            child: loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Login'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
