import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/core/repo/notification_preferences_repo.dart';
import 'package:mindcoach/core/utils/context_l10n_extensions.dart';

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
        SnackBar(content: Text(context.l10n.notifSettingsSaveFailed)),
      );
    }
  }

  bool _boolOf(String key) => _prefs[key] == true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(l10n.menuItemNotificationSettings),
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
              ? Center(child: Text(l10n.notifSettingsLoadError))
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _sectionTitle(l10n.notifSettingsCategories),
                    _switchTile(
                      title: l10n.notifCatRealtime,
                      subtitle: l10n.notifCatRealtimeDesc,
                      value: _boolOf('realtime_enabled'),
                      onChanged: (v) => _update({'realtime_enabled': v}),
                    ),
                    _switchTile(
                      title: l10n.notifCatTherapy,
                      subtitle: l10n.notifCatTherapyDesc,
                      value: _boolOf('therapy_enabled'),
                      onChanged: (v) => _update({'therapy_enabled': v}),
                    ),
                    _switchTile(
                      title: l10n.notifCatAnalysis,
                      subtitle: l10n.notifCatAnalysisDesc,
                      value: _boolOf('analysis_enabled'),
                      onChanged: (v) => _update({'analysis_enabled': v}),
                    ),
                    _switchTile(
                      title: l10n.notifCatReengage,
                      subtitle: l10n.notifCatReengageDesc,
                      value: _boolOf('reengagement_enabled'),
                      onChanged: (v) => _update({'reengagement_enabled': v}),
                    ),
                    _switchTile(
                      title: l10n.notifCatSubscription,
                      subtitle: l10n.notifCatSubscriptionDesc,
                      value: _boolOf('subscription_enabled'),
                      onChanged: (v) => _update({'subscription_enabled': v}),
                    ),
                    _switchTile(
                      title: l10n.notifCatSystem,
                      subtitle: l10n.notifCatSystemDesc,
                      value: _boolOf('system_enabled'),
                      onChanged: (v) => _update({'system_enabled': v}),
                    ),
                    const SizedBox(height: 12),
                    _sectionTitle(l10n.notifQuietHoursSection),
                    _switchTile(
                      title: l10n.notifQuietHours,
                      subtitle: l10n.notifQuietHoursDesc,
                      value: _boolOf('quiet_hours_enabled'),
                      onChanged: (v) => _update({'quiet_hours_enabled': v}),
                    ),
                    if (_boolOf('quiet_hours_enabled')) ...[
                      _hourPickerTile(
                        label: l10n.notifQuietHoursStart,
                        value: (_prefs['quiet_hours_start'] as int?) ?? 22,
                        onChanged: (h) => _update({'quiet_hours_start': h}),
                      ),
                      _hourPickerTile(
                        label: l10n.notifQuietHoursEnd,
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF898989),
                  ),
                ),
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
              final hourLabel = '${h.toString().padLeft(2, '0')}:00';
              return DropdownMenuItem(value: h, child: Text(hourLabel));
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
