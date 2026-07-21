import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/locale/native_lang_sync.dart';
import 'package:mindcoach/Services/NotificationsService/periodic_notification_scheduler.dart';
import 'package:mindcoach/core/locale/locale_provider.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  late String _selectedCode;

  static const List<_LanguageItem> _languages = [
    _LanguageItem(flag: '🇹🇷', name: 'Turkish', code: 'tr'),
    _LanguageItem(flag: '🇬🇧', name: 'English', code: 'en'),
    _LanguageItem(flag: '🇩🇪', name: 'German', code: 'de'),
    _LanguageItem(flag: '🇮🇹', name: 'Italian', code: 'it'),
    _LanguageItem(flag: '🇫🇷', name: 'French', code: 'fr'),
    _LanguageItem(flag: '🇯🇵', name: 'Japanese', code: 'ja'),
    _LanguageItem(flag: '🇪🇸', name: 'Spanish', code: 'es'),
    _LanguageItem(flag: '🇷🇺', name: 'Russian', code: 'ru'),
    _LanguageItem(flag: '🇰🇷', name: 'Korean', code: 'ko'),
    _LanguageItem(flag: '🇮🇳', name: 'Hindi', code: 'hi'),
    _LanguageItem(flag: '🇵🇹', name: 'Portuguese', code: 'pt'),
    _LanguageItem(flag: '🇨🇳', name: 'Chinese', code: 'zh'),
  ];

  @override
  void initState() {
    super.initState();
    // localeProvider ilk açılışta async yüklenirken null olabilir.
    // Bu durumda sistem locale'i göster; aksi halde ayarlar ekranı yanlışlıkla
    // "English" seçili açılıyordu.
    _selectedCode = ref.read(localeProvider.notifier).getLanguageCode();
  }

  Future<void> _save() async {
    await ref.read(localeProvider.notifier).setLocale(Locale(_selectedCode));
    // Backend push bildirimleri için nativeLang senkronu (setLocale de yapar; burada da garanti)
    unawaited(NativeLangSync.syncToBackend(_selectedCode));
    unawaited(PeriodicNotificationScheduler().updateSchedule());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(
            Icons.chevron_left,
            color: Color(0xFF1A1A1A),
            size: 28,
          ),
        ),
        title: Text(
          context.l10n.appLanguage,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF1A1A1A),
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _languages.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _languages[index];
                final isSelected = _selectedCode == item.code;
                return _LanguageTile(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedCode = item.code),
                );
              },
            ),
          ),
          _SaveButton(onPressed: _save),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language tile
// ---------------------------------------------------------------------------

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _LanguageItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF21BC87);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? green.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? green : const Color(0xFFE2E2E2),
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Text(item.flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Text(
              item.name,
              style: TextStyle(
                fontFamily: 'Geist',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: isSelected ? green : const Color(0xFF6B6B6B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Save button
// ---------------------------------------------------------------------------

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF21BC87),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          icon: const Icon(Icons.bookmark_outlined, size: 22),
          label: Text(
            context.l10n.save,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _LanguageItem {
  const _LanguageItem({
    required this.flag,
    required this.name,
    required this.code,
  });

  final String flag;
  final String name;
  final String code;
}
