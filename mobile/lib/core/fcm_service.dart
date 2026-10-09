import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'local_notifications.dart';

/// Callback global para navegar a un canal desde una notificacion.
/// Lo setea `NotiuamApp` para no acoplar el servicio al Navigator.
typedef OnNotificationTap = void Function(String channelId, String? postId);

class FcmService {
  final ApiClient _api;
  FcmService(this._api);

  OnNotificationTap? onNotificationTap;

  Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('FCM: plataforma no soportada, ignorando');
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

      final token = await messaging.getToken();
      if (token == null) {
        debugPrint('FCM: sin token');
        return;
      }

      debugPrint('FCM token: ${token.substring(0, 20)}...');
      await _registerWithBackend(token);

      messaging.onTokenRefresh.listen(_registerWithBackend);

      // 1. App en foreground
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // 2. App en background, usuario toca la notificacion
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

      // 3. App cerrada, usuario toca la notificacion al abrir
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _onMessageOpened(initial);
        });
      }
    } catch (e) {
      debugPrint('FCM error: $e');
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
    } catch (e) {
      debugPrint('FCM: error desregistrando: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    if (n != null) {
      debugPrint('FCM foreground: ${n.title} - ${n.body}');
      // Mostrar notificacion local para que el usuario la vea en foreground
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