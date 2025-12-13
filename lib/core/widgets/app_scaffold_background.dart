import 'package:flutter/material.dart';
import '../theme/app_gradients.dart';

class AppScaffoldBackground extends StatelessWidget {
  final Widget child;

  const AppScaffoldBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppGradients.background),
      child: child,
    );
  }
}
