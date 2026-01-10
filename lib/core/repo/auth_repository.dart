import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';
import 'package:mindcoach/http/http_service.dart';
import 'package:mindcoach/models/user_model.dart';


class AuthRepository {
  // Google Sign-In instance with serverClientId for Android
  // Server Client ID from iOS Info.plist: 137535160742-let1k5rhqu6ecqmlpj91g7336gctc8mt.apps.googleusercontent.com
  // Android Client ID: 137535160742-pai7kjdb0nlr4lm9r1j4tc0o7ulpinli.apps.googleusercontent.com
  static bool _initialized = false;

  Future checkToken() async{}
  
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      if (Platform.isAndroid) {
        debugPrint("🔵 [Google Sign-In] Initializing for Android");
        debugPrint("🔵 [Google Sign-In] Client ID: 137535160742-pai7kjdb0nlr4lm9r1j4tc0o7ulpinli.apps.googleusercontent.com");
        debugPrint("🔵 [Google Sign-In] Server Client ID: 137535160742-let1k5rhqu6ecqmlpj91g7336gctc8mt.apps.googleusercontent.com");
        try {
          // attokmak değişecek
          await GoogleSignIn.instance.initialize(
            clientId: "137535160742-pai7kjdb0nlr4lm9r1j4tc0o7ulpinli.apps.googleusercontent.com",
            serverClientId: "137535160742-let1k5rhqu6ecqmlpj91g7336gctc8mt.apps.googleusercontent.com",
          );
          debugPrint("✅ [Google Sign-In] Android initialization successful");
        } catch (e) {
          debugPrint("❌ [Google Sign-In] Android initialization failed: $e");
          rethrow;
        }
      } else {
        debugPrint("🍎 [Google Sign-In] Initializing for iOS");
        try {
          await GoogleSignIn.instance.initialize();
          debugPrint("✅ [Google Sign-In] iOS initialization successful");
        } catch (e) {
          debugPrint("❌ [Google Sign-In] iOS initialization failed: $e");
          rethrow;
        }
      }
      _initialized = true;
    }
  }

Future<dynamic> googleSignIn() async{
  try {
    debugPrint("🔵 [Google Sign-In] Starting Google Sign-In process...");
    debugPrint("🔵 [Google Sign-In] Platform: ${Platform.isAndroid ? 'Android' : 'iOS'}");
    
  
    await _ensureInitialized();

   // Start the sign-in flow using authenticate() method
       GoogleSignInAccount?  account = await GoogleSignIn.instance.authenticate(
          scopeHint: ['email', 'profile'],
        );
      
      // Account null kontrolü
      if (account == null) {
        debugPrint("❌ [Google Sign-In] Account is null - user cancelled or error occurred");
        return false;
      }
      
         GoogleSignInAuthentication auth = account.authentication;
      debugPrint("✅ [Google Sign-In] Authentication obtained");
      debugPrint("✅ [Google Sign-In] ID Token: ${auth.idToken != null ? 'Yes (${auth.idToken!.length} chars)' : 'No'}");
      if (auth.idToken != null) {
        debugPrint("✅ [Google Sign-In] ID Token preview: ${auth.idToken!.substring(0, auth.idToken!.length > 50 ? 50 : auth.idToken!.length)}...");
        // token devamı
      bool apiSuccess = await googleAuthApiCall(auth.idToken!);
      if (apiSuccess) {
        return auth.idToken!;
      } else {
             return false;
      }
      }else{
        debugPrint("❌ [Google Sign-In] ID Token is null");
        return false;
      }
    
  } on GoogleSignInException catch (e) {
    debugPrint("❌ [Google Sign-In] Exception Code: ${e.code}");
    debugPrint("❌ [Google Sign-In] Exception String: $e");
    
    // Handle specific GoogleSignInException codes
    if (e.code == GoogleSignInExceptionCode.canceled) {
      debugPrint("⚠️ [Google Sign-In] Sign-in was CANCELED");
      final errorString = e.toString();
      if (errorString.contains('reauth') || errorString.contains('Account reauth')) {
        debugPrint("❌ [Google Sign-In] Account reauth failed detected!");
      }
    } else {
      debugPrint("❌ [Google Sign-In] Error code: ${e.code}");
    }
    
    log("❌ [Google Sign-In] GoogleSignInException in googleSignIn method. Code: ${e.code}, Error: $e");
    return false;
  } on PlatformException catch (e) {
    debugPrint("❌ [Google Sign-In] Platform Exception occurred");
    debugPrint("❌ [Google Sign-In] Error Code: ${e.code}");
    debugPrint("❌ [Google Sign-In] Error Message: ${e.message}");
    debugPrint("❌ [Google Sign-In] Error Details: ${e.details}");
    
    // Common error codes and their meanings
    switch (e.code) {
      case 'sign_in_canceled':
        debugPrint("⚠️ [Google Sign-In] User cancelled the sign-in");
        break;
      case 'sign_in_failed':
        debugPrint("❌ [Google Sign-In] Sign-in failed - check configuration");
        break;
      case 'network_error':
        debugPrint("❌ [Google Sign-In] Network error - check internet connection");
        break;
      case 'sign_in_required':
        debugPrint("⚠️ [Google Sign-In] Sign-in required");
        break;
      case 'DEVELOPER_ERROR':
        debugPrint("❌ [Google Sign-In] DEVELOPER_ERROR - Configuration issue");
        break;
      case '10':
        debugPrint("❌ [Google Sign-In] Error 10 - OAuth configuration issue");
        debugPrint("❌ [Google Sign-In] Check OAuth Client ID and package name");
        break;
      case '12500':
        debugPrint("❌ [Google Sign-In] Error 12500 - Sign-in cancelled or network issue");
        break;
      default:
        debugPrint("❌ [Google Sign-In] Unknown error code: ${e.code}");
    }
    
    log("❌ [Google Sign-In] Platform Exception in googleSignIn method. Code: ${e.code}, Message: ${e.message}, Details: ${e.details}");
    return false;
  } 
}

Future<bool> googleAuthApiCall(String idToken)async{
  LocalDbService localDbService = LocalDbService();
    HttpService httpService = HttpService();
      var response = await httpService.post(
          path: AppConstants.googleAuth,
          body:{
            "idToken": idToken
          } );
       
       if (response.statusCode == 200) {
         var json = jsonDecode(response.body);
         String token = json["data"]["token"];
        await localDbService.setString(key: LocalDbKeys.token, value: token);
        
        return true;
       } else {
         return false;
       }

      
}

Future<UserModel?> verifyUserByToken(String token) async {
  try {
    debugPrint('🔄 [AUTH-REPO] verifyUserByToken başlatılıyor...');
    
    HttpService httpService = HttpService();
    debugPrint('🔄 [AUTH-REPO] HttpService oluşturuldu, /auth/verify endpoint\'ine istek gönderiliyor...');
    
    var res = await httpService.get(
      path: AppConstants.verifyTokenURL,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json"
      }
    );
    
    debugPrint('✅ [AUTH-REPO] /auth/verify response alındı, statusCode: ${res.statusCode}');
    
    if (res.statusCode == 200) {
      var json = jsonDecode(res.body);
      debugPrint('✅ [AUTH-REPO] Response JSON parse edildi');
      
      if (json["success"] == true && json["data"] != null) {
        // Yeni API formatı: {"success": true, "data": {"valid": true, "user": {...}}}
        if (json["data"]["valid"] == true && json["data"]["user"] != null) {
          debugPrint('✅ [AUTH-REPO] Token geçerli, user model oluşturuluyor...');
          UserModel userModel = UserModel.fromMap(json["data"]["user"]);
          debugPrint('✅ [AUTH-REPO] UserModel oluşturuldu: ${userModel.id}');
          return userModel;
        } else {
          debugPrint('❌ [AUTH-REPO] Token validation error: valid=false veya user=null');
          return null;
        }
      } else {
        debugPrint('❌ [AUTH-REPO] Response format hatası: success=false veya data=null');
        return null;
      }
    } else {
      debugPrint('❌ [AUTH-REPO] Request to validation error: statusCode=${res.statusCode}');
      debugPrint('❌ [AUTH-REPO] Response body: ${res.body}');
      return null;
    }
  } catch (e, stackTrace) {
    debugPrint('❌ [AUTH-REPO] verifyUserByToken hatası: $e');
    debugPrint('❌ [AUTH-REPO] Stack trace: $stackTrace');
    return null;
  }
}


Future<bool> completeProfile(String username,String gender,List<String> avaibleDays,String avaibleHours,String area,String speakingStyle,Ref ref)async{
   HttpService httpService = HttpService(ref: ref);
  
  // Username boşsa veya sadece boşluklardan oluşuyorsa "MindCoach User" olarak ayarla
  final finalUsername = (username.trim().isEmpty) ? 'MindCoach User' : username.trim();
  
  debugPrint('📝 [AUTH-REPO] Profil tamamlanıyor: username="$finalUsername" (orijinal: "$username")');
  
  var body = {
  "username": finalUsername,
  "nativeLang": "tr",
  "gender": gender,
  "answerData": {
    "avaibleDays": avaibleDays,
    "avaibleHours": avaibleHours,
    "supportArea": area,
    "agentSpeakStyle": speakingStyle
  }
};

  var response = await httpService.put(path: AppConstants.completeProfileURL,
  body: body
  );
  if (response.statusCode == 200) {
    debugPrint("✅ Profile Completed successfully");
    return true;
  } else {
    debugPrint("❌ Profile completion failed: ${response.statusCode}");
    debugPrint("Response body: ${response.body}");
    return false;
  }
}







  Future<Map<String, dynamic>?> facebookSignIn() async {
    try {
      debugPrint("🔷 Starting Facebook login...");
      debugPrint("🔷 Platform: ${Platform.isAndroid ? 'Android' : 'iOS'}");
      
      // Check if user is already logged in
      final AccessToken? accessToken = await FacebookAuth.instance.accessToken;
      if (accessToken != null) {
        debugPrint("🔷 Found existing access token, logging out first...");
        await FacebookAuth.instance.logOut();
      }
      
      // For Android, try Facebook login
      LoginResult result;
      if (Platform.isAndroid) {
        debugPrint("🔷 Android detected - attempting Facebook login");
        result = await FacebookAuth.instance.login(
          permissions: ['email', 'public_profile'],
        );
        debugPrint("🔷 Login result status: ${result.status}");
      } else {
        // iOS
        result = await FacebookAuth.instance.login(
          permissions: ['email', 'public_profile'],
        );
      }

      debugPrint("🔷 Facebook login result status: ${result.status}");
      debugPrint("🔷 Facebook login result message: ${result.message}");
      
      if (result.message != null) {
        debugPrint("🔷 Facebook login message details: ${result.message}");
      }

      if (result.status == LoginStatus.success) {
        debugPrint("✅ Facebook login SUCCESS");
        
        // Get access token
        final token = result.accessToken;
        // AccessToken.token is the property name in flutter_facebook_auth
        final tokenString = token != null ? (token as dynamic).token : null;
        debugPrint("✅ Facebook Auth token exists: ${token != null}");
        if (token != null && tokenString != null) {
          final preview = tokenString.toString().substring(0, tokenString.toString().length > 20 ? 20 : tokenString.toString().length);
          debugPrint("✅ Facebook Auth token: $preview...");
        }
        
        // Get user data
        try {
          final userData = await FacebookAuth.instance.getUserData();
          debugPrint("✅ Facebook Auth userData: $userData");
          
          return {
            'userData': userData,
            'accessToken': tokenString?.toString(),
          };
        } catch (userDataError) {
          debugPrint("⚠️ Could not fetch user data, but login succeeded: $userDataError");
          // Return with access token even if user data fetch fails
          return {
            'userData': {'email': null, 'name': null},
            'accessToken': tokenString?.toString(),
          };
        }
      } else if (result.status == LoginStatus.cancelled) {
        debugPrint("⚠️ Facebook login CANCELLED by user");
        return null;
      } else if (result.status == LoginStatus.failed) {
        debugPrint("❌ Facebook login FAILED: ${result.message}");
        debugPrint("❌ Error code: ${result.message}");
        
        // Provide more helpful error message
        if (result.message?.contains('feature') ?? false || 
            result.message!.contains('unavailable') ) {
          debugPrint("❌ 'Feature Unavailable' error detected!");
          debugPrint("❌ This usually means:");
          debugPrint("   1. Facebook App is in Development mode (should be Live)");
          debugPrint("   2. Key Hash is missing from Facebook Developer Console");
          debugPrint("   3. Package name mismatch (current: com.flywork.friendify)");
          debugPrint("   4. Facebook Login feature not approved");
        }
        
        return null;
      } else {
        debugPrint("⚠️ Facebook login status: ${result.status}");
        debugPrint("⚠️ Unknown status, returning null");
        return null;
      }
    } catch (e, stackTrace) {
      log("❌ Error in AuthRepo on facebookSignIn method. Error: $e");
      debugPrint("📍 StackTrace: $stackTrace");
      debugPrint("❌ Error type: ${e.runtimeType}");
      if (e.toString().contains('feature') || e.toString().contains('unavailable')) {
        debugPrint("❌ This is a 'Feature Unavailable' error!");
        debugPrint("❌ Please check:");
        debugPrint("   1. Facebook Developer Console > Settings > Basic");
        debugPrint("   2. Add Android platform with package: com.flywork.friendify");
        debugPrint("   3. Add Key Hashes (debug and release)");
        debugPrint("   4. Ensure app is in 'Live' mode, not 'Development'");
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> appleSignIn() async{
    try {
      debugPrint("🍎 Starting Apple login...");
      
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint("❌ [Apple Sign-In] Timeout after 30 seconds");
          throw TimeoutException('Apple sign-in timeout', const Duration(seconds: 30));
        },
      );
      
      debugPrint("✅ Apple Auth credential received");
      debugPrint("📧 Email: ${credential.email}");
      debugPrint("👤 Name: ${credential.givenName} ${credential.familyName}");
      debugPrint("🆔 UserIdentifier: ${credential.userIdentifier}");

      String? email = credential.email;
      String? fullName = credential.givenName != null && credential.familyName != null
          ? "${credential.givenName} ${credential.familyName}"
          : credential.givenName ?? credential.familyName;
      
      return {
        'userIdentifier': credential.userIdentifier, // Unique Apple user ID
        'email': email,
        'fullName': fullName,
        'identityToken': credential.identityToken, // JWT token
        'authorizationCode': credential.authorizationCode,
      };
    } catch (e, stackTrace) {
      if (e.toString().contains('canceled')) {
        debugPrint("⚠️ Apple login CANCELLED by user");
      } else {
        log("❌ Error in AuthRepo on appleSignIn method. Error: $e");
        debugPrint("📍 StackTrace: $stackTrace");
      }
      return null;
    }
  }


}