import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:mindcoach/core/utils/app_constants.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';
import 'package:mindcoach/http/http_service.dart';


class AuthRepository {
  // Google Sign-In instance with serverClientId for Android
  // Server Client ID from iOS Info.plist: 137535160742-let1k5rhqu6ecqmlpj91g7336gctc8mt.apps.googleusercontent.com
  // Android Client ID: 137535160742-pai7kjdb0nlr4lm9r1j4tc0o7ulpinli.apps.googleusercontent.com
  static bool _initialized = false;
  
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      if (Platform.isAndroid) {
        try {
          await GoogleSignIn.instance.initialize(
            clientId: "931696780726-vcrf18tiqf3kim8dr5s0g8qhnuvbpip0.apps.googleusercontent.com",
            serverClientId: "931696780726-3b9p8a9t0di2bkr7s3olir10oh00roba.apps.googleusercontent.com",
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

  Future checkToken() async{}

Future<dynamic> googleSignIn() async{
  try {
    debugPrint("🔵 [Google Sign-In] Starting Google Sign-In process...");
    debugPrint("🔵 [Google Sign-In] Platform: ${Platform.isAndroid ? 'Android' : 'iOS'}");
    
    await _ensureInitialized();

    // Clear any existing session to avoid reauth issues
    try {
      debugPrint("🔵 [Google Sign-In] Clearing any existing session...");
      await GoogleSignIn.instance.signOut();
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint("✅ [Google Sign-In] Session cleared");
    } catch (e) {
      debugPrint("ℹ️ [Google Sign-In] Sign out failed (this is OK if no session exists): $e");
    }

    // Use authenticate() method - with Credential Manager disabled, this should work better
    debugPrint("🔵 [Google Sign-In] Attempting to authenticate...");
    GoogleSignInAccount? account;
          account = await GoogleSignIn.instance.authenticate(
        scopeHint: ['email', 'profile'],
      );

    
    // authenticate() returns null if user cancels (otherwise throws exception)
    // If account is null, user cancelled - this is handled by the exception above
    debugPrint("✅ [Google Sign-In] Account obtained: ${account.email}");
    
    // Get authentication with ID token
    debugPrint("🔵 [Google Sign-In] Requesting authentication token...");
    GoogleSignInAuthentication auth = await account.authentication;
    debugPrint("✅ [Google Sign-In] Authentication obtained");
    debugPrint("✅ [Google Sign-In] ID Token: ${auth.idToken != null ? 'Yes (${auth.idToken!.length} chars)' : 'No'}");
    
    if (auth.idToken == null) {
      debugPrint("❌ [Google Sign-In] ID Token is null - requesting again...");
      // Try to get the token again - sometimes it needs a refresh
      auth = await account.authentication;
      if (auth.idToken == null) {
        debugPrint("❌ [Google Sign-In] ID Token is still null after retry");
        return false;
      }
    }
    
    debugPrint("✅ [Google Sign-In] ID Token obtained successfully");
    if (auth.idToken!.length > 50) {
      debugPrint("✅ [Google Sign-In] ID Token preview: ${auth.idToken!.substring(0, 50)}...");
    }
    
    // Call API to verify token
    bool apiSuccess = await googleAuthApiCall(auth.idToken!);
    if (apiSuccess) {
      debugPrint("✅ [Google Sign-In] API call successful");
      return auth.idToken!;
    } else {
      debugPrint("❌ [Google Sign-In] API call failed");
      return false;
    }
    
  } on GoogleSignInException catch (e) {
    debugPrint("❌ [Google Sign-In] Exception Code: ${e.code}");
    debugPrint("❌ [Google Sign-In] Exception String: $e");
    
    // Handle specific GoogleSignInException codes
    if (e.code == GoogleSignInExceptionCode.canceled) {
      final errorString = e.toString();
      
      // Check if it's Error 16 (Account reauth failed)
      if (errorString.contains('[16]') || errorString.contains('Account reauth') || errorString.contains('reauth')) {
        debugPrint("❌ [Google Sign-In] Error 16: Account reauth failed");
        debugPrint("❌ [Google Sign-In] ========================================");
        debugPrint("❌ [Google Sign-In] BU HATA ŞUNLARDAN KAYNAKLANABİLİR:");
        debugPrint("❌ [Google Sign-In] ========================================");
        debugPrint("❌ [Google Sign-In] 1. SHA-1 ve SHA-256 fingerprint'ler Google Cloud Console'a EKLENMEMİŞ");
        debugPrint("❌ [Google Sign-In] 2. Package name YANLIŞ (olması gereken: com.flywork.mindcoach)");
        debugPrint("❌ [Google Sign-In] 3. OAuth Client ID YANLIŞ veya EKSİK");
        debugPrint("❌ [Google Sign-In] 4. Credential Manager hala aktif (Android sistem hatası)");
        debugPrint("❌ [Google Sign-In] ========================================");
        debugPrint("❌ [Google Sign-In] YAPILMASI GEREKENLER:");
        debugPrint("❌ [Google Sign-In] ========================================");
        debugPrint("❌ [Google Sign-In] 1. Google Cloud Console'a gidin:");
        debugPrint("❌ [Google Sign-In]    https://console.cloud.google.com/apis/credentials");
        debugPrint("❌ [Google Sign-In] 2. OAuth Client ID'yi bulun:");
        debugPrint("❌ [Google Sign-In]    931696780726-9bg4g80lakc05sf5do9a3r3pdru90sj6");
        debugPrint("❌ [Google Sign-In] 3. Package name: com.flywork.mindcoach (TAM OLARAK)");
        debugPrint("❌ [Google Sign-In] 4. Aşağıdaki SHA key'leri EKLEYİN:");
        debugPrint("❌ [Google Sign-In]    DEBUG SHA-1:   C7:A6:48:26:D6:91:7C:31:B6:3E:0E:A9:3D:0A:44:90:EE:9A:5F:FA");
        debugPrint("❌ [Google Sign-In]    DEBUG SHA-256: 2C:A9:D3:C7:E1:47:E3:D8:88:E3:FC:70:8B:79:71:10:97:FE:EE:18:F3:FC:84:8B:CC:DE:BC:B4:7F:EB:6F:C0");
        debugPrint("❌ [Google Sign-In]    RELEASE SHA-1:   79:7E:06:14:86:C9:64:89:87:5F:29:1E:25:81:4A:04:F6:50:70:2A");
        debugPrint("❌ [Google Sign-In]    RELEASE SHA-256: 51:A4:50:FE:A0:AB:58:DA:E5:E8:15:B6:E4:79:09:1A:D2:E5:BF:44:FA:3D:28:8F:8A:8D:46:C4:F5:50:BC:D5");
        debugPrint("❌ [Google Sign-In] 5. 10-15 dakika bekleyin");
        debugPrint("❌ [Google Sign-In] 6. Uygulamayı tamamen kapatıp yeniden açın");
        debugPrint("❌ [Google Sign-In] ========================================");
        debugPrint("❌ [Google Sign-In] Detaylı talimatlar: android/SHA_KEYS_TO_ADD.md");
        debugPrint("❌ [Google Sign-In] ========================================");
      } else {
        debugPrint("⚠️ [Google Sign-In] Sign-in was CANCELED by user");
      }
      return false;
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
        debugPrint("❌ [Google Sign-In] Check OAuth Client ID, package name, and SHA fingerprints");
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
  } catch (e, stackTrace) {
    debugPrint("❌ [Google Sign-In] Unexpected error: $e");
    debugPrint("❌ [Google Sign-In] Stack trace: $stackTrace");
    log("❌ [Google Sign-In] Unexpected error in googleSignIn method. Error: $e, StackTrace: $stackTrace");
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