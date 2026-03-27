import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hyperlocal Marketplace',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.root,
      routes: Routes.routes,
    );
  }
}
