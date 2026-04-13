import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';

/// Tek bir ses kaydını temsil eder (player'a aktarılacak).
class SoundPlayerItem {
  final String title;
  final String subtitle;
  final String imagePath;
  final String audioPath;
  final String categoryLabel;

  const SoundPlayerItem({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.audioPath,
    required this.categoryLabel,
  });
}

class SoundPlayerScreen extends StatefulWidget {
  /// Oynatılacak ses listesi (aynı kategorideki tüm sesler).
  final List<SoundPlayerItem> playlist;

  /// Başlangıçta çalınacak ses'in playlist içindeki index'i.
  final int initialIndex;

  const SoundPlayerScreen({
    super.key,
    required this.playlist,
    required this.initialIndex,
  });

  @override
  State<SoundPlayerScreen> createState() => _SoundPlayerScreenState();
}

class _SoundPlayerScreenState extends State<SoundPlayerScreen> {
  late AudioPlayer _player;
  late int _currentIndex;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _player = AudioPlayer();
    _setupListeners();
    // İlk açıldığında çalmasın diye autoPlay: false gönderiyoruz.
    _loadAudio(_currentIndex, autoPlay: false);
  }

  void _setupListeners() {
    _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);

      // --- DEĞİŞTİRİLEN KISIM BURASI ---
      // Ses bittiğinde sıradaki şarkıya geçmek yerine başa sarıp durdurur.
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        _player.pause();
      }
    });
  }

  Future<void> _loadAudio(int index, {bool autoPlay = true}) async {
    final item = widget.playlist[index];
    try {
      await _player.setAsset(item.audioPath);
      // Sadece autoPlay true ise çalmaya başla
      if (autoPlay) {
        await _player.play();
      }
    } catch (e) {
      debugPrint('Audio load error: $e');
    }
  }

  void _togglePlay() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _next() {
    if (_currentIndex < widget.playlist.length - 1) {
      setState(() => _currentIndex++);
    } else {
      setState(() => _currentIndex = 0); // Başa dön
    }
    // Sonraki şarkıya geçildiğinde doğrudan çalmasını istiyorsak autoPlay: true (varsayılan)
    _loadAudio(_currentIndex, autoPlay: true);
  }

  void _previous() {
    // 3 saniyeden fazla çaldıysa başa sar, değilse önceki şarkıya geç
    if (_position.inSeconds > 3) {
      _player.seek(Duration.zero);
      return;
    }
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    } else {
      setState(() => _currentIndex = widget.playlist.length - 1);
    }
    // Önceki şarkıya geçildiğinde doğrudan çalması için autoPlay: true (varsayılan)
    _loadAudio(_currentIndex, autoPlay: true);
  }

  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.playlist[_currentIndex];
    final totalMs = _duration.inMilliseconds;
    final progress = totalMs > 0 ? _position.inMilliseconds / totalMs : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background Image ──
          Image.asset(
            item.imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A3A5C), Color(0xFF0D1B2A)],
                ),
              ),
            ),
          ),

          // ── Dark overlay ──
          Container(color: Colors.black.withValues(alpha: 0.35)),

          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── Circular Progress ──
                SizedBox(
                  width: 280,
                  height: 280,
                  child: CustomPaint(
                    painter: _CircularProgressPainter(progress: progress),
                    child: Center(
                      child: Text(
                        item.categoryLabel,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Timer ──
                Text(
                  _formatTime(_duration - _position),
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Title ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      item.subtitle,
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const Spacer(flex: 2),

                // ── Controls ──
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Previous
                      GestureDetector(
                        onTap: _previous,
                        child: SvgPicture.asset(
                          "assets/icons/ic_forward_left.svg",
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Play / Pause
                      GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          // DIŞ ÇEMBER (Hale Efekti)
                          width: 88, // Görseldeki dış çember genişliği
                          height: 88,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              alpha: 0.2,
                            ), // Daha şeffaf dış katman
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            // İÇ ÇEMBER (Ana Buton Zemin)
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: 0.45,
                              ), // Biraz daha koyu iç katman
                              shape: BoxShape.circle,
                            ),
                            alignment:
                                Alignment.center, // İkonu tam ortaya hizalar
                            child: SvgPicture.asset(
                              _isPlaying
                                  ? "assets/icons/ic_pause.svg" // Çalıyorsa Pause ikonu gelsin
                                  : "assets/icons/ic_play.svg", // Duruyorsa Play ikonu gelsin
                              width: 32,
                              height: 32,
                              // İkonun rengini görseldeki gibi açık gri/beyaz tonda zorlamak istersen bunu kullanabilirsin:
                              colorFilter: const ColorFilter.mode(
                                Color.fromARGB(
                                  255,
                                  255,
                                  255,
                                  255,
                                ), // Görseldeki kırık beyaz/açık gri tonu
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Next
                      GestureDetector(
                        onTap: _next,
                        child: SvgPicture.asset(
                          "assets/icons/ic_forward_right.svg",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom circular progress ring matching Figma design.
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  _CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0) {
      final sweepAngle = 2 * pi * progress;
      const startAngle = -pi / 2;

      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: const [
            Color(0xFF3E2B6D),
            Color(0xFF3E2B6D),
            Color(0xFF8B5CF6),
          ],
          transform: const GradientRotation(-pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
