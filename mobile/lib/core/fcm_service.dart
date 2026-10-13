import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'local_notifications.dart';

typedef OnNotificationTap = void Function(String channelId, String? postId);

class FcmService {
  final ApiClient _api;
  FcmService(this._api);

  OnNotificationTap? onNotificationTap;

  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;

  Future<void> initialize() async {
    // Guard: solo inicializa una vez por instancia.
    if (_initialized) {
      debugPrint('FCM: ya inicializado, ignorando llamada');
      return;
    }
    _initialized = true;

    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('FCM: plataforma no soportada');
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: permiso denegado');
        return;
      }

      // Cancelar listeners previos por si acaso (idempotente).
      await _tokenRefreshSub?.cancel();
      await _onMessageSub?.cancel();
      await _onOpenedSub?.cancel();

      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('FCM token: ${token.substring(0, 20)}...');
        await _registerWithBackend(token);
      }

      _tokenRefreshSub = messaging.onTokenRefresh.listen(_registerWithBackend);
      _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      _onOpenedSub =
          FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _onMessageOpened(initial);
        });
      }
    } catch (e) {
      debugPrint('FCM error: $e');
      // Permitir reintentar si fallo.
      _initialized = false;
    }
  }

  Future<void> _registerWithBackend(String token) async {
    try {
      final platform = Platform.isAndroid ? 'ANDROID' : 'IOS';
      await _api.dio.post('/api/me/device', data: {
        'token': token,
        'platform': platform,
      });
      debugPrint('FCM: token registrado en el backend');
    } catch (e) {
      debugPrint('FCM: error registrando token: $e');
    }
  }

  Future<void> unregister() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _api.dio.delete('/api/me/device',
          queryParameters: {'token': token});
      await FirebaseMessaging.instance.deleteToken();
      _initialized = false;
    } catch (e) {
      debugPrint('FCM: error desregistrando: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    if (n != null) {
      debugPrint('FCM foreground: ${n.title} - ${n.body}');
      LocalNotifications.show(
        title: n.title ?? 'NotiUAM',
        body: n.body ?? '',
      );
    }
  }

  void _onMessageOpened(RemoteMessage message) {
    final channelId = message.data['channelId'];
    final postId = message.data['postId'];
    debugPrint('FCM tap: channelId=$channelId postId=$postId');

    if (channelId != null && channelId.isNotEmpty) {
      onNotificationTap?.call(channelId, postId);
    }
  }
}