import 'package:flutter/material.dart';

/// Uygulamanın o an gösterdiği route'u global olarak takip eder.
/// Bildirim foreground suppression'ı (kullanıcı ilgili ekrandayken push
/// banner'ını bastırma) için kullanılır.
class CurrentRouteObserver extends NavigatorObserver {
  static String? currentRouteName;

  static final CurrentRouteObserver instance = CurrentRouteObserver._();
  CurrentRouteObserver._();

  void _update(Route<dynamic>? route) {
    currentRouteName = route?.settings.name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(previousRoute);
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _update(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(previousRoute);
    super.didRemove(route, previousRoute);
  }
}
