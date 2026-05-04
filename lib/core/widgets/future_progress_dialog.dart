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

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.30),
    useRootNavigator: useRootNavigator,
    builder: (ctx) => const PopScope(
      canPop: false,
      child: Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    ),
  );

  try {
    final T result = await action();
    if (context.mounted) {
      Navigator.of(context, rootNavigator: useRootNavigator).pop();
    }
    return result;
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: useRootNavigator).pop();
    }
    rethrow;
  }
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
