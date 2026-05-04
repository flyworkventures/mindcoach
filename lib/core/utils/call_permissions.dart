import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Gerçek cihazlarda mikrofon: önce [Permission.microphone] ile sistem diyaloğu
/// (iOS’ta [permission_handler] Podfile `PERMISSION_MICROPHONE=1` gerektirir).
/// [record] paketinin `hasPermission()` tek başına her zaman güvenilir değildir.
Future<bool> ensureMicrophonePermission() async {
  if (kIsWeb) return true;
  if (!(Platform.isIOS || Platform.isAndroid)) return true;

  var status = await Permission.microphone.status;
  if (status.isDenied || status.isRestricted || status.isLimited) {
    status = await Permission.microphone.request();
  }
  if (status.isPermanentlyDenied) {
    await openAppSettings();
    return false;
  }
  return status.isGranted;
}

/// Kamera önizlemesi (görüntülü görüşme). iOS’ta `PERMISSION_CAMERA=1` Podfile şart.
Future<bool> ensureCameraPermission() async {
  if (kIsWeb) return false;
  if (!(Platform.isIOS || Platform.isAndroid)) return true;

  var status = await Permission.camera.status;
  if (status.isDenied || status.isRestricted || status.isLimited) {
    status = await Permission.camera.request();
  }
  if (status.isPermanentlyDenied) {
    await openAppSettings();
    return false;
  }
  return status.isGranted;
}

/// Görüntülü arama: iOS ardışık iki diyalog için önce mikrofon, sonra kamera.
Future<bool> ensureVideoCallPermissions() async {
  if (kIsWeb) return false;
  if (!(Platform.isIOS || Platform.isAndroid)) return true;

  final micOk = await ensureMicrophonePermission();
  if (!micOk) return false;
  return ensureCameraPermission();
}
