enum Mood {
  terrible,
  bad,
  neutral,
  good,
  great;

  String get key => switch (this) {
    Mood.terrible => 'terrible',
    Mood.bad => 'bad',
    Mood.neutral => 'neutral',
    Mood.good => 'good',
    Mood.great => 'great',
  };

  static Mood? fromKey(String? key) {
    if (key == null) return null;
    for (final m in Mood.values) {
      if (m.key == key) return m;
    }
    return null;
  }
}
