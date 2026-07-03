import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/repo/notification_preferences_repo.dart';

/// Kategori bazlı bildirim opt-out + sessiz saat ayarları ekranı.
/// Değişiklikler anında backend'e (PUT /notifications/preferences) yazılır.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  static const Color _accent = Color(0xFF21BC87);

  Map<String, dynamic> _prefs = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool _isTr(BuildContext c) => Localizations.localeOf(c).languageCode == 'tr';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = NotificationPreferencesRepo(ref);
      final prefs = await repo.getPreferences();
      if (!mounted) return;
      setState(() {
        _prefs = prefs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _update(Map<String, dynamic> patch) async {
    // İyimser güncelleme
    setState(() {
      _prefs = {..._prefs, ...patch};
      _saving = true;
    });
    try {
      final repo = NotificationPreferencesRepo(ref);
      final updated = await repo.updatePreferences(patch);
      if (!mounted) return;
      setState(() {
        _prefs = updated;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isTr(context) ? 'Kaydedilemedi' : 'Save failed')),
      );
    }
  }

  bool _boolOf(String key) => _prefs[key] == true;

  @override
  Widget build(BuildContext context) {
    final tr = _isTr(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(tr ? 'Bildirim Ayarları' : 'Notification Settings'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(tr ? 'Bir hata oluştu' : 'Something went wrong'))
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _sectionTitle(tr ? 'Kategoriler' : 'Categories'),
                    _switchTile(
                      title: tr ? 'Anlık bildirimler' : 'Realtime',
                      subtitle: tr
                          ? 'Terapist mesajları ve seans hatırlatmaları'
                          : 'Therapist messages and session reminders',
                      value: _boolOf('realtime_enabled'),
                      onChanged: (v) => _update({'realtime_enabled': v}),
                    ),
                    _switchTile(
                      title: tr ? 'Terapi önerileri' : 'Therapy suggestions',
                      subtitle: tr
                          ? 'Terapist seçimi ve devam önerileri'
                          : 'Therapist selection and continue prompts',
                      value: _boolOf('therapy_enabled'),
                      onChanged: (v) => _update({'therapy_enabled': v}),
                    ),
                    _switchTile(
                      title: tr ? 'Psikolojik analiz' : 'Psychological analysis',
                      subtitle: tr
                          ? 'Analiz testi hatırlatmaları'
                          : 'Analysis test reminders',
                      value: _boolOf('analysis_enabled'),
                      onChanged: (v) => _update({'analysis_enabled': v}),
                    ),
                    _switchTile(
                      title: tr ? 'Hatırlatmalar' : 'Reminders',
                      subtitle: tr
                          ? 'Bir süredir gelmediğinde nazik hatırlatmalar'
                          : 'Gentle nudges when you have been away',
                      value: _boolOf('reengagement_enabled'),
                      onChanged: (v) => _update({'reengagement_enabled': v}),
                    ),
                    _switchTile(
                      title: tr ? 'Abonelik ve plan' : 'Subscription & plan',
                      subtitle: tr
                          ? 'Deneme, yenileme ve ödeme bilgileri'
                          : 'Trial, renewal and payment info',
                      value: _boolOf('subscription_enabled'),
                      onChanged: (v) => _update({'subscription_enabled': v}),
                    ),
                    _switchTile(
                      title: tr ? 'Sistem ve hesap' : 'System & account',
                      subtitle: tr
                          ? 'Güvenlik ve hesap bildirimleri'
                          : 'Security and account notifications',
                      value: _boolOf('system_enabled'),
                      onChanged: (v) => _update({'system_enabled': v}),
                    ),
                    const SizedBox(height: 12),
                    _sectionTitle(tr ? 'Sessiz Saatler' : 'Quiet Hours'),
                    _switchTile(
                      title: tr ? 'Sessiz saatler' : 'Quiet hours',
                      subtitle: tr
                          ? 'Belirtilen saatlerde sadece acil bildirimler'
                          : 'Only urgent notifications during these hours',
                      value: _boolOf('quiet_hours_enabled'),
                      onChanged: (v) => _update({'quiet_hours_enabled': v}),
                    ),
                    if (_boolOf('quiet_hours_enabled')) ...[
                      _hourPickerTile(
                        label: tr ? 'Başlangıç' : 'Start',
                        value: (_prefs['quiet_hours_start'] as int?) ?? 22,
                        onChanged: (h) => _update({'quiet_hours_start': h}),
                      ),
                      _hourPickerTile(
                        label: tr ? 'Bitiş' : 'End',
                        value: (_prefs['quiet_hours_end'] as int?) ?? 8,
                        onChanged: (h) => _update({'quiet_hours_end': h}),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF898989),
          ),
        ),
      );

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF898989))),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: _accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _hourPickerTile({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          DropdownButton<int>(
            value: value,
            underline: const SizedBox.shrink(),
            items: List.generate(24, (h) {
              final label = '${h.toString().padLeft(2, '0')}:00';
              return DropdownMenuItem(value: h, child: Text(label));
            }),
            onChanged: (h) {
              if (h != null) onChanged(h);
            },
          ),
        ],
      ),
    );
  }
}
