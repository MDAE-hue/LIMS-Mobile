import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'Screen/splash.dart';
import 'Screen/detail_print.dart'; // import screen detail print

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LIMS',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/detail-print': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is int) {
            return DetailPrintScreen(reportId: args);
          } else {
            return const Scaffold(
              body: Center(child: Text('No report ID provided')),
            );
          }
        },
      },
    );
  }
}
