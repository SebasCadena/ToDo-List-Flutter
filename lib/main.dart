import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do_list/router/app_router.dart';
import 'package:to_do_list/themes/light_theme.dart';
import 'package:to_do_list/providers/sync_provider.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SyncProvider()..initConnectivityListener(),
      child: MaterialApp.router(
        theme: lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
