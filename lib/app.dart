import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/dashboard/presentation/pages/dashboard_screen.dart';

class CastFlowApp extends StatelessWidget {
  const CastFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CastFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}
