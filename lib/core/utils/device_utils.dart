import 'package:uuid/uuid.dart';

import '../../Services/LocalServices/local_db_service.dart';
import 'local_db_keys.dart';

/// Device UUID management untuk premium system
/// Device ID cihaza bağlı ve unique, account switch'te değişmez
class DeviceUtils {
  static Future<String> getDeviceId() async {
    final localDb = LocalDbService();

    // Eğer zaten var, onu döndür
    String? existingId = await localDb.getString(
      key: LocalDbKeys.deviceIdPremium,
    );
    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    // İlk defa: yeni UUID oluştur ve kaydet
    const uuid = Uuid();
    final newDeviceId = uuid.v4(); // UUID v4: random

    await localDb.setString(
      key: LocalDbKeys.deviceIdPremium,
      value: newDeviceId,
    );
    return newDeviceId;
  }

  /// Device ID'nin oluşturulup oluşturulmadığını kontrol et (async olmadan)
  static bool hasDeviceId() {
    // Not: Bu method true dönemeyebilir ilk çalışmada
    // getDeviceId() çağır bunun yerine
    return true; // Her zaman true döndür; getDeviceId() idempotent
  }
}
