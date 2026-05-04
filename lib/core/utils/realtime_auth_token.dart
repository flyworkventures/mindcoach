import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Riverpod/Providers/all_providers.dart';
import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/View/auth/domain/social_login_provider.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';

/// Görüntülü/sesli gerçek zamanlı arama için JWT gerekir. Onboarding sırasında
/// henüz giriş yapılmamışsa misafir oturumu açılır.
Future<String> ensureRealtimeAuthToken(WidgetRef ref) async {
  var token = await LocalDbService().getString(key: LocalDbKeys.token);
  if (token != null && token.isNotEmpty) return token;

  final fromProvider = ref.read(AllProviders.userProvider)?.token;
  if (fromProvider != null && fromProvider.isNotEmpty) {
    await LocalDbService().setString(
      key: LocalDbKeys.token,
      value: fromProvider,
    );
    return fromProvider;
  }

  final userModel =
      await ref.read(AllProviders.authProvider.notifier).login(
            SocialLoginProvider.guest,
          );
  final t = userModel?.token;
  if (t != null && t.isNotEmpty) return t;

  throw StateError('Kimlik doğrulanamadı');
}
