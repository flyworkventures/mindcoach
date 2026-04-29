import 'package:rive/rive.dart' as rive;

/// Rive dosyalarını arka planda indirip cache'leyen singleton.
///
/// ConversationScreen açıldığında [preload] çağrılır → dosya indirilmeye başlar.
/// VideoCallRealtimeScreen açıldığında [getLoader] / [obtainOrCreateLoader] ile
/// hazır (veya yüklenmekte olan) FileLoader alınır.
///
/// Cache anahtarı her zaman [normalizeRiveUrl] ile üretilir (`domain/x` ve
/// `https://domain/x` aynı kayıt).
///
/// FileLoader'ların dispose edilmemesi gerekmekte: bunlar uygulama ömrü
/// boyunca cache'de tutulur (her danışman için tek bir rive.File nesnesi).
class RivePreloadService {
  RivePreloadService._();
  static final RivePreloadService instance = RivePreloadService._();

  final Map<String, rive.FileLoader> _cache = {};

  /// Şema yoksa `https://` eklenir; trim uygulanır.
  static String? normalizeRiveUrl(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.isEmpty) return null;
    final lower = t.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) return t;
    return 'https://$t';
  }

  /// [rawUrl] için arka planda ön yükleme başlatır.
  /// Daha önce aynı normalize edilmiş URL ile çağrıldıysa hiçbir şey yapmaz.
  void preload(String? rawUrl) {
    final url = normalizeRiveUrl(rawUrl);
    if (url == null) return;
    if (_cache.containsKey(url)) return;

    final loader = rive.FileLoader.fromUrl(url, riveFactory: rive.Factory.rive);
    _cache[url] = loader;

    // file() çağrısı indirmeyi başlatır; Future'ı burada beklemiyoruz —
    // arka planda sessizce tamamlanır.
    loader.file().then((_) {}).catchError((Object _) {
      _cache.remove(url);
      return null;
    });
  }

  /// Cache'de yoksa oluşturur, indirmeyi başlatır ve loader'ı döndürür.
  /// Geçersiz URL ise null.
  rive.FileLoader? obtainOrCreateLoader(String? rawUrl) {
    final url = normalizeRiveUrl(rawUrl);
    if (url == null) return null;
    if (_cache.containsKey(url)) return _cache[url]!;
    preload(rawUrl);
    return _cache[url]!;
  }

  /// [rawUrl] için cache'deki [FileLoader]'ı döndürür.
  /// Henüz preload/obtain çağrılmadıysa null döner.
  rive.FileLoader? getLoader(String? rawUrl) {
    final url = normalizeRiveUrl(rawUrl);
    if (url == null) return null;
    return _cache[url];
  }

  /// Önceden yüklenmiş bir loader mevcut mu?
  bool isCached(String? rawUrl) {
    final url = normalizeRiveUrl(rawUrl);
    if (url == null) return false;
    return _cache.containsKey(url);
  }
}
