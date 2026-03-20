import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/connection_config.dart';
import 'providers/settings_provider.dart';
import 'screens/connect_screen.dart';
import 'screens/session_list_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/ws_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  final settings = SettingsProvider();
  await settings.load();

  final savedConfig = await AuthService().loadConfig();
  runApp(NomadTermApp(savedConfig: savedConfig, settings: settings));
}

class NomadTermApp extends StatelessWidget {
  final ConnectionConfig? savedConfig;
  final SettingsProvider settings;
  const NomadTermApp({super.key, this.savedConfig, required this.settings});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
        value: settings,
        child: MaterialApp(
          title: 'NomadTerm',
          debugShowCheckedModeBanner: false,
          theme: T.materialTheme,
          home: savedConfig != null
              ? ChangeNotifierProvider(
                  create: (_) => WsService(savedConfig!)..connect(),
                  child: const SessionListScreen(),
                )
              : const ConnectScreen(),
        ),
      );
}
