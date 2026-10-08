import 'package:flutter/foundation.dart';
import '../core/api_client.dart';

class ReportProvider extends ChangeNotifier {
  final ApiClient _api;
  ReportProvider(this._api);

  Future<void> createReport({
    required String targetType,   // 'POST' | 'CHANNEL'
    required String targetId,
    required String reason,       // SPAM | INAPPROPRIATE | ...
    String? details,
  }) async {
    await _api.dio.post('/api/reports', data: {
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      if (details != null && details.isNotEmpty) 'details': details,
    });
  }
}