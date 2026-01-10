import 'package:flutter/widgets.dart';
import '../../../core/utils/context_l10n_extensions.dart';

class ChatStrings {
  ChatStrings._();

  static String greeting(BuildContext c, String name) =>
      c.l10n.chatScreenGreeting(name);

  static String screenTitle(BuildContext c) => c.l10n.chatScreenTitle;

  static String youPrefix(BuildContext c) => c.l10n.chatLastFromYouPrefix;

  static String deleteToast(BuildContext c, String name) =>
      c.l10n.chatDeleteToast(name);
}
