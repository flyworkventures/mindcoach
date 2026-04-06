import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/Http/http_service.dart';
import 'package:mindcoach/models/notification_model.dart';

class NotificationRepo {
  final Ref? ref;

  NotificationRepo(this.ref);

  /// Kullanıcının tüm bildirimlerini getir
  Future<List<NotificationModel>> getUserNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    HttpService httpService = HttpService(ref: ref);
    var res = await httpService.get(
      path: '${AppConstants.getNotificationsURL}?limit=$limit&offset=$offset',
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to get notifications: ${res.statusCode}');
    }

    var json = jsonDecode(res.body);
    if (json['success'] != true || json['data'] == null) {
      throw Exception('Invalid response format');
    }

    List jsonList = json['data']['notifications'] ?? [];
    List<NotificationModel> notifications =
        jsonList.map((e) => NotificationModel.fromMap(e)).toList();
    return notifications;
  }

  /// Belirli bir bildirimi getir
  Future<NotificationModel?> getNotificationById(int id) async {
    HttpService httpService = HttpService(ref: ref);
    var res = await httpService.get(
      path: AppConstants.getNotificationByIdURL(id),
    );

    if (res.statusCode != 200) {
      if (res.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to get notification: ${res.statusCode}');
    }

    var json = jsonDecode(res.body);
    if (json['success'] != true || json['data'] == null) {
      throw Exception('Invalid response format');
    }

    return NotificationModel.fromMap(json['data']['notification']);
  }

  /// Bildirimi sil
  /// DELETE /notifications/:id
  /// Response 200: { "success": true, "message": "Notification deleted successfully" }
  /// Response 404: { "success": false, "error": "Notification not found" }
  Future<bool> deleteNotification(int id) async {
    HttpService httpService = HttpService(ref: ref);
    var res = await httpService.delete(
      path: AppConstants.deleteNotificationURL(id),
    );

    var json = jsonDecode(res.body);
    
    if (res.statusCode == 200) {
      return json['success'] == true;
    } else if (res.statusCode == 404) {
      throw Exception(json['error'] ?? 'Notification not found');
    } else {
      throw Exception('Failed to delete notification: ${res.statusCode}');
    }
  }

  /// Tüm bildirimleri sil
  /// DELETE /notifications
  Future<bool> deleteAllNotifications() async {
    HttpService httpService = HttpService(ref: ref);
    var res = await httpService.delete(
      path: AppConstants.deleteAllNotificationsURL,
    );

    var json = jsonDecode(res.body);
    
    if (res.statusCode == 200) {
      return json['success'] == true;
    } else {
      throw Exception(json['error'] ?? 'Failed to delete all notifications');
    }
  }
}

