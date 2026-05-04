import 'package:flutter/material.dart';

/// Uzun sürebilecek bir [action] tamamlanana kadar kapatılamayan modal gösterir;
/// işlem bitince (veya hata olunca) otomatik kapanır.
///
/// Örnek:
/// ```dart
/// await context.runWithProgressDialog(
///   () => ref.read(authControllerProvider.notifier).deleteAccount(),
///   message: context.l10n.pleaseWait,
/// );
/// ```
Future<T> showFutureProgressDialog<T>({
  required BuildContext context,
  required Future<T> Function() action,
  String? message,
  bool useRootNavigator = true,
}) async {
  if (!context.mounted) {
    return action();
  }

  final NavigatorState navigator = Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  );
  final Route<void> progressRoute = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.30),
    builder: (ctx) => const PopScope(
      canPop: false,
      child: Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    ),
  );
  navigator.push(progressRoute);

  try {
    final T result = await action();
    _dismissProgressRouteSafely(navigator, progressRoute);
    return result;
  } catch (e) {
    _dismissProgressRouteSafely(navigator, progressRoute);
    rethrow;
  }
}

void _dismissProgressRouteSafely(
  NavigatorState navigator,
  Route<void> progressRoute,
) {
  if (!navigator.mounted) return;
  // Login gibi akışlarda işlem sırasında route değiştiriliyor (pushNamedAndRemoveUntil).
  // Kör `pop()` yeni sayfayı kapatabiliyor; yalnızca gerçekten bizim dialog route
  // hâlâ navigator'a bağlıysa onu kaldır.
  if (progressRoute.navigator != navigator) return;
  navigator.removeRoute(progressRoute);
}

extension FutureProgressDialogExtension on BuildContext {
  Future<T> runWithProgressDialog<T>(
    Future<T> Function() action, {
    String? message,
    bool useRootNavigator = true,
  }) =>
      showFutureProgressDialog<T>(
        context: this,
        action: action,
        message: message,
        useRootNavigator: useRootNavigator,
      );
}
