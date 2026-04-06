enum Mood {
  calm,
  happy,
  neutral,
  tired,
  stressed;

  String get key => switch (this) {
    Mood.calm => 'calm',
    Mood.happy => 'happy',
    Mood.neutral => 'neutral',
    Mood.tired => 'tired',
    Mood.stressed => 'stressed',
  };

  static Mood? fromKey(String? key) {
    if (key == null) return null;
    for (final m in Mood.values) {
      if (m.key == key) return m;
    }
    return null;
  }
}
