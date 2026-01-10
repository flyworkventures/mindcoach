import 'package:shared_preferences/shared_preferences.dart';

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

}