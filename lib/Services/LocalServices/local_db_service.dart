import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/local_db_keys.dart';

class LocalDbService {
  
  Future<String?> getString({required String key})async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? value = sharedPreferences.getString(key);
    return value;
  }


  Future<bool> setString({required String key,required String value})async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
   bool success = await sharedPreferences.setString(key,value);
    return success;
  }

  Future<bool> deleteString({required String key})async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    bool success = await sharedPreferences.remove(key);
    return success;
  }

  Future<bool?> getBool({required String key}) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getBool(key);
  }

  Future<bool> setBool({required String key, required bool value}) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setBool(key, value);
  }

  Future<int?> getInt({required String key}) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return sharedPreferences.getInt(key);
  }

  Future<bool> setInt({required String key, required int value}) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setInt(key, value);
  }

  // ========== PREMIUM SYSTEM METHODS ==========

  /// Premium son kullanma tarihini ayarla (ISO 8601)
  Future<bool> setPremiumExpiryDate(DateTime expiryDate) async {
    return setString(
      key: LocalDbKeys.premiumExpiryDate,
      value: expiryDate.toIso8601String(),
    );
  }

  /// Premium son kullanma tarihini al
  Future<DateTime?> getPremiumExpiryDate() async {
    final dateString = await getString(key: LocalDbKeys.premiumExpiryDate);
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return null;
    }
  }

  /// Premium aktif mi (tarih kontrolü)
  Future<bool> isPremiumActive() async {
    final expiryDate = await getPremiumExpiryDate();
    if (expiryDate == null) return false;
    return DateTime.now().isBefore(expiryDate);
  }

  /// Premium başlangıç tarihini ayarla
  Future<bool> setPremiumStartDate(DateTime startDate) async {
    return setString(
      key: LocalDbKeys.premiumStartDate,
      value: startDate.toIso8601String(),
    );
  }

  /// Premium başlangıç tarihini al
  Future<DateTime?> getPremiumStartDate() async {
    final dateString = await getString(key: LocalDbKeys.premiumStartDate);
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return null;
    }
  }

  /// Premium satın alındı mı (trial değil) (Boolean)
  Future<bool> getIsPremiumPurchased() async {
    return await getBool(key: LocalDbKeys.isPremiumPurchased) ?? false;
  }

  /// Premium satın alındı statusunu ayarla
  Future<bool> setIsPremiumPurchased(bool isPurchased) async {
    return setBool(
      key: LocalDbKeys.isPremiumPurchased,
      value: isPurchased,
    );
  }

  /// Premium durumunu sil (trial sona erdi).
  /// NOT: hasUsedTrial flag'ine DOKUNMAZ — trial bittikten sonra tekrar verilmesini engellemek için.
  Future<bool> clearPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool success = true;
    success &= await prefs.remove(LocalDbKeys.premiumExpiryDate);
    success &= await prefs.remove(LocalDbKeys.premiumStartDate);
    success &= await prefs.remove(LocalDbKeys.isPremiumPurchased);
    return success;
  }

  /// Bu cihazda daha önce 3 günlük trial verildi mi.
  Future<bool> getHasUsedTrial() async {
    return await getBool(key: LocalDbKeys.hasUsedTrial) ?? false;
  }

  /// "Trial daha önce verildi" flag'ini set et (tekrar trial verilmesini engeller).
  Future<bool> setHasUsedTrial(bool value) async {
    return setBool(key: LocalDbKeys.hasUsedTrial, value: value);
  }

}