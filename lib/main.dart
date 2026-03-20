import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/connection_config.dart';
import 'screens/connect_screen.dart';
import 'screens/session_list_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/ws_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  // Load saved connection config (if any).
  final savedConfig = await AuthService().loadConfig();

  runApp(NomadTermApp(savedConfig: savedConfig));
}

class NomadTermApp extends StatelessWidget {
  final ConnectionConfig? savedConfig;
  const NomadTermApp({super.key, this.savedConfig});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NomadTerm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6C63FF),
          surface: const Color(0xFF16213e),
        ),
      ),
      home: savedConfig != null
          ? ChangeNotifierProvider(
              create: (_) => WsService(savedConfig!)..connect(),
              child: const SessionListScreen(),
            )
          : const ConnectScreen(),
    );
  }
}
