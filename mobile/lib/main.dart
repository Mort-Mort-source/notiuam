import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/token_storage.dart';
import 'core/theme.dart';
import 'state/auth_provider.dart';
import 'state/channel_provider.dart';
import 'state/post_provider.dart';
import 'state/unread_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'state/admin_provider.dart';
import 'state/report_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  runApp(const NotiuamApp());
}

class NotiuamApp extends StatelessWidget {
  const NotiuamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TokenStorage>(create: (_) => TokenStorage()),
        ProxyProvider<TokenStorage, ApiClient>(
          update: (_, storage, __) => ApiClient(storage),
        ),
        ChangeNotifierProxyProvider<ApiClient, AuthProvider>(
          create: (context) => AuthProvider(
            context.read<ApiClient>(),
            context.read<TokenStorage>(),
          )..bootstrap(),
          update: (_, api, previous) =>
              previous ?? AuthProvider(api, context.read<TokenStorage>()),
        ),
        ChangeNotifierProxyProvider<ApiClient, ChannelProvider>(
          create: (context) => ChannelProvider(context.read<ApiClient>()),
          update: (_, api, previous) => previous ?? ChannelProvider(api),
        ),
        ChangeNotifierProxyProvider<ApiClient, PostProvider>(
          create: (context) => PostProvider(context.read<ApiClient>()),
          update: (_, api, previous) => previous ?? PostProvider(api),
        ),
        ChangeNotifierProxyProvider<ApiClient, UnreadProvider>(
          create: (context) => UnreadProvider(context.read<ApiClient>()),
          update: (_, api, previous) => previous ?? UnreadProvider(api),
        ),
        ChangeNotifierProxyProvider<ApiClient, AdminProvider>(
  create: (context) => AdminProvider(context.read<ApiClient>()),
  update: (_, api, previous) => previous ?? AdminProvider(api),
),
ChangeNotifierProxyProvider<ApiClient, ReportProvider>(
  create: (context) => ReportProvider(context.read<ApiClient>()),
  update: (_, api, previous) => previous ?? ReportProvider(api),
),
      ],
      child: MaterialApp(
        title: 'NotiUAM',
        debugShowCheckedModeBanner: false,
        theme: NotiuamTheme.light(),
        home: const _RootNavigator(),
      ),
    );
  }
}

class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    switch (auth.status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.authenticated:
        return const HomeShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}