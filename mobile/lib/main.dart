import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/fcm_background.dart';
import 'core/fcm_service.dart';
import 'core/local_notifications.dart';
import 'core/theme.dart';
import 'core/token_storage.dart';
import 'state/admin_provider.dart';
import 'state/auth_provider.dart';
import 'state/channel_provider.dart';
import 'state/post_provider.dart';
import 'state/report_provider.dart';
import 'state/unread_provider.dart';
import 'screens/channel_detail_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await LocalNotifications.initialize();
  } catch (e) {
    debugPrint('Firebase no inicializado: $e');
  }

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
          create: (context) {
            final fcm = FcmService(context.read<ApiClient>());
            _wireFcm(fcm);
            return AuthProvider(
              context.read<ApiClient>(),
              context.read<TokenStorage>(),
              fcm,
            )..bootstrap();
          },
          update: (_, api, previous) =>
              previous ??
              AuthProvider(api, context.read<TokenStorage>(), FcmService(api)),
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
        navigatorKey: navigatorKey,
        theme: NotiuamTheme.light(),
        home: const _RootNavigator(),
      ),
    );
  }

  void _wireFcm(FcmService fcm) {
    fcm.onNotificationTap = (channelId, postId) {
      final nav = navigatorKey.currentState;
      if (nav == null) return;
      nav.push(MaterialPageRoute(
        builder: (_) => ChannelDetailScreen(channelId: channelId),
      ));
    };
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