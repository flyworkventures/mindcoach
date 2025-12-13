import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_status_notifier.dart';
import '../../auth_di.dart';
import '../../domain/social_login_provider.dart';
import '../../domain/auth_repository.dart';

/// AuthController
/// ----------------
/// - UI ile domain/data katmanı arasında köprü görevi görür
/// - UI, auth işlemlerini **doğrudan repository veya datasource üzerinden yapmaz**
/// - AsyncValue kullanarak loading / error / success durumlarını yönetir
///
/// ⚠️ ÖNEMLİ:
/// - Bu controller, **auth’un nasıl yapıldığını bilmez**
/// - Google / Apple / Fake / N8N farkı burada yoktur
/// - Yarın N8NAuthDataSource geldiğinde:
///     → Sadece data layer değişir
///     → Controller ve UI birebir aynı kalır
class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    // Başlangıçta herhangi bir işlem yok
    // UI bu state’i dinleyerek loading/error gösterebilir
    return const AsyncData(null);
  }

  /// Repository erişimi
  /// Controller, concrete implementation bilmez
  /// (Fake mi, N8N mi → auth_di karar verir)
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Sosyal login işlemi
  ///
  /// Akış:
  /// 1) UI login çağırır
  /// 2) Repository → DataSource
  /// 3) Başarılıysa AppStatus authenticated olur
  ///
  /// UI tarafı sadece state ve AppStatus değişimini izler
  Future<void> login(SocialLoginProvider provider) async {
    state = const AsyncLoading();
    try {
      await _repo.loginWithSocial(provider);

      // Login başarılıysa app içi akışa geç
      ref.read(appStatusProvider.notifier).goToAuthenticated();

      state = const AsyncData(null);
    } catch (e, st) {
      // Error state → UI toast / dialog gösterebilir
      state = AsyncError(e, st);

      // İleride istersen:
      // ref.read(appStatusProvider.notifier).goToUnauthenticated();
    }
  }

  /// Logout işlemi
  ///
  /// - Session temizlenir
  /// - AppStatus unauthenticated yapılır
  /// - UI otomatik olarak login / onboarding akışına döner
  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _repo.logout();

      ref.read(appStatusProvider.notifier).goToUnauthenticated();

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

/// Provider
/// --------
/// UI katmanı bu provider üzerinden controller’a erişir
/// Controller singleton mantığında çalışır
final authControllerProvider =
NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
