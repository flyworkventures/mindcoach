import 'package:flutter/material.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';

/// Backend'den gelen role key'lerini (ör: "male", "female") lokalize edilmiş
/// string'lere çevirir.
class RoleConvert {
  final String value;
  final BuildContext context;

  RoleConvert(this.value, this.context);

  String call() {
    final l10n = context.l10n;
    switch (value.toLowerCase()) {
      case 'male':
        return l10n.roleMale;
      case 'female':
        return l10n.roleFemale;
      default:
        return value;
    }
  }
}
