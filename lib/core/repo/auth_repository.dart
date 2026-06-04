import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:mindcoach/core/config/google_oauth_config.dart';


class AuthRepository {
  static bool _initialized = false;
  
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      if (Platform.isAndroid) {
        try {
          await GoogleSignIn.instance.initialize(
            serverClientId: GoogleOAuthConfig.webClientId,
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

  Future checkToken() async {}

  Future<dynamic> googleSignIn() async {
    try {
      debugPrint("🔵 [Google Sign-In] Starting Google Sign-In process...");
      debugPrint(
        "🔵 [Google Sign-In] Platform: ${Platform.isAndroid ? 'Android' : 'iOS'}",
      );

      await _ensureInitialized();

      try {
        debugPrint("🔵 [Google Sign-In] Clearing any existing session...");
        await GoogleSignIn.instance.signOut();
        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint("✅ [Google Sign-In] Session cleared");
      } catch (e) {
        debugPrint(
          "ℹ️ [Google Sign-In] Sign out failed (this is OK if no session exists): $e",
        );
      }

      debugPrint("🔵 [Google Sign-In] Attempting to authenticate...");
      final account = await GoogleSignIn.instance.authenticate(
        scopeHint: ['email', 'profile'],
      );

      debugPrint("✅ [Google Sign-In] Account obtained: ${account.email}");

      debugPrint("🔵 [Google Sign-In] Requesting authentication token...");
      GoogleSignInAuthentication auth = await account.authentication;
      debugPrint("✅ [Google Sign-In] Authentication obtained");
      debugPrint(
        "✅ [Google Sign-In] ID Token: ${auth.idToken != null ? 'Yes (${auth.idToken!.length} chars)' : 'No'}",
      );

      if (auth.idToken == null) {
        debugPrint("❌ [Google Sign-In] ID Token is null - requesting again...");
        auth = await account.authentication;
        if (auth.idToken == null) {
          debugPrint("❌ [Google Sign-In] ID Token is still null after retry");
          return false;
        }
      }

      debugPrint("✅ [Google Sign-In] ID Token obtained successfully");
      return auth.idToken!;
    } on GoogleSignInException catch (e) {
      debugPrint("❌ [Google Sign-In] Exception Code: ${e.code}");
      debugPrint("❌ [Google Sign-In] Exception String: $e");

      if (e.code == GoogleSignInExceptionCode.canceled) {
        final errorString = e.toString();

        if (errorString.contains('[16]') ||
            errorString.contains('Account reauth') ||
            errorString.contains('reauth')) {
          debugPrint("❌ [Google Sign-In] Error 16: Account reauth failed");
          debugPrint("❌ [Google Sign-In] Play Store SHA-1 (Firebase):");
          debugPrint("❌ [Google Sign-In]    ${GoogleOAuthConfig.playAppSigningSha1}");
          debugPrint("❌ [Google Sign-In] Yeni AAB yayınlayın: android/GOOGLE_SIGNIN_ANDROID.md");
        } else {
          debugPrint("⚠️ [Google Sign-In] Sign-in was CANCELED by user");
        }
      } else {
        debugPrint("❌ [Google Sign-In] Error code: ${e.code}");
      }

      log(
        "❌ [Google Sign-In] GoogleSignInException. Code: ${e.code}, Error: $e",
      );
      return false;
    } on PlatformException catch (e) {
      debugPrint("❌ [Google Sign-In] Platform Exception: ${e.code} — ${e.message}");
      return false;
    } catch (e, stackTrace) {
      debugPrint("❌ [Google Sign-In] Unexpected error: $e");
      log("❌ [Google Sign-In] Unexpected error: $e\n$stackTrace");
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