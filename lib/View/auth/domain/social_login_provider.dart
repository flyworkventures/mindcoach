/// Social login seçeneklerini temsil eder.
/// UI ve data katmanı bu enum üzerinden konuşur.
///
/// ⚠️ Backend (N8N / Firebase / vs) değişse bile
/// UI tarafında bu enum değişmez.
library;

enum SocialLoginProvider {
  google,
  apple,
  facebook,
  guest,
}