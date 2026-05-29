import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'lab_task/lab_task_tab.dart';
import 'user.dart';
import './report.dart';
import 'settings.dart';
import 'dashboard.dart';
import '../auth/login.dart';
import '../core/theme/app_theme.dart';

class TabsScreen extends StatefulWidget {
  final int
  roleId; // 1: Sampler, 2: Analyst, 3: Superintendent, 4: Admin, 5: User, 6: Manager

  const TabsScreen({super.key, required this.roleId});

  @override
  _TabsScreenState createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> with TickerProviderStateMixin {
  int _currentIndex = 2;
  late final List<Widget> _allTabs;
  Timer? _logoutTimer;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.roleId == 5 ? 1 : 2;
    _allTabs = [
      const ReportScreen(),
      LabTaskTab(roleId: widget.roleId),
      const DashboardTab(),
      const UsersTabPlaceholder(),
      const SettingsScreen(),
    ];

    _startLogoutTimer();
  }

  /// Memulai timer auto logout selama 60 menit
  void _startLogoutTimer() {
    _logoutTimer?.cancel();
    _logoutTimer = Timer(const Duration(minutes: 60), _autoLogout);
  }

  /// Fungsi logout otomatis
  void _autoLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false, // tidak bisa klik di luar
        builder: (_) => WillPopScope(
          onWillPop: () async => false, // tombol back dinonaktifkan
          child: AlertDialog(
            title: const Text("Session Berakhir"),
            content: const Text(
              "Waktu login Anda telah habis. Silakan login kembali.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // tutup dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text("OK"),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoutTimer?.cancel();
    super.dispose();
  }

  // ------------------ Role-based tabs ------------------
  List<Widget> get _tabsForRole {
    switch (widget.roleId) {
      case 1: // Sampler
      case 2: // Analyst
      case 3: // Superintendent
      case 6: // Manager
        return [_allTabs[0], _allTabs[1], _allTabs[2], _allTabs[4]];
      case 4: // Admin
        return _allTabs;
      case 5: // User biasa
      default:
        return [_allTabs[0], _allTabs[2], _allTabs[4]];
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    switch (widget.roleId) {
      case 1:
      case 2:
      case 3:
      case 6:
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Reports',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.science),
            label: 'Lab Task',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ];
      case 4: // Admin
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Reports',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.science),
            label: 'Lab Task',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ];
      case 5:
      default:
        return [
          const BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Reports',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget currentTab = _tabsForRole[_currentIndex];

    // Khusus Admin: tab ke-3 adalah UserScreen
    if (widget.roleId == 4 && _currentIndex == 3) {
      currentTab = const UserScreen();
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: currentTab,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 68,
            selectedIndex: _currentIndex,
            backgroundColor: Colors.white,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: _navItems.map((item) {
              return NavigationDestination(
                icon: item.icon,
                selectedIcon: Icon(
                  (item.icon as Icon).icon,
                  color: AppColors.primary,
                ),
                label: item.label ?? '',
              );
            }).toList(),
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
              _startLogoutTimer(); // reset timer setiap kali navigasi
            },
          ),
        ),
      ),
    );
  }
}

// -------------------- Tabs lain --------------------
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}

class UsersTabPlaceholder extends StatelessWidget {
  const UsersTabPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Settings Tab'));
  }
}
