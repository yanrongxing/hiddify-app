import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 启动画面 – 动态绘制 XLink "Asymmetrical Flying X" Logo
///
/// 动画阶段：
///   Phase 1 (0 → 1.5s)  : 描线动画 —— 隧道 + 极光飞羽依次绘出
///   Phase 2 (线条画完后)  : 呼吸光效循环 —— 缩放 + 透明度脉动
///   Phase 3 (同步)       : 粒子场 —— 沿飞羽路径散射微光粒子
///
/// [onFinished] 在描线动画完成时回调一次，可用于通知外部"可以切页了"。
class SplashLogoWidget extends StatefulWidget {
  const SplashLogoWidget({super.key, this.onFinished});

  /// 描线结束回调
  final VoidCallback? onFinished;

  @override
  State<SplashLogoWidget> createState() => _SplashLogoWidgetState();
}

class _SplashLogoWidgetState extends State<SplashLogoWidget>
    with TickerProviderStateMixin {
  // ──────────────── 动画控制器 ────────────────
  late AnimationController _drawController;
  late AnimationController _breatheController;
  late AnimationController _particleController;
  late AnimationController _glowPulseController;

  // ──────────────── 描线进度 ────────────────
  late Animation<double> _tunnelProgress;
  late Animation<double> _wingProgress;
  late Animation<double> _fadeIn; // 整体淡入

  // ──────────────── 呼吸 ────────────────
  late Animation<double> _breatheScale;
  late Animation<double> _breatheOpacity;

  // ──────────────── 光晕脉冲 ────────────────
  late Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();

    // ── Phase 1: 描线 (2s) ──
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // ── Phase 2: 呼吸 (3s 循环) ──
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // ── Phase 3: 粒子 (4s 循环) ──
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // ── 光晕脉冲 (2s 循环) ──
    _glowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // 整体淡入 0→0.3 区间
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _drawController,
        curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
      ),
    );

    // 隧道描线 0→0.55
    _tunnelProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _drawController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    // 飞羽描线 0.2→1.0 (稍晚启动)
    _wingProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _drawController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutQuart),
      ),
    );

    // 呼吸
    _breatheScale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
    _breatheOpacity = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    // 光晕脉冲
    _glowPulse = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowPulseController, curve: Curves.easeInOut),
    );

    // ── 启动链 ──
    _drawController.forward().then((_) {
      widget.onFinished?.call();
      _breatheController.repeat(reverse: true);
      _particleController.repeat();
      _glowPulseController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _drawController.dispose();
    _breatheController.dispose();
    _particleController.dispose();
    _glowPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF202020),
      child: Center(
        child: SizedBox(
          width: 180,
          height: 180,
          child: AnimatedBuilder(
            animation: Listenable.merge([
              _drawController,
              _breatheController,
              _particleController,
              _glowPulseController,
            ]),
            builder: (context, child) {
              return Opacity(
                opacity: _fadeIn.value,
                child: Transform.scale(
                  scale: _breatheScale.value,
                  child: Opacity(
                    opacity: _breatheOpacity.value,
                    child: CustomPaint(
                      painter: _LogoPainter(
                        tunnelProgress: _tunnelProgress.value,
                        wingProgress: _wingProgress.value,
                        particlePhase: _particleController.value,
                        glowPulse: _glowPulse.value,
                      ),
                      size: const Size(180, 180),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Custom Painter — 隧道 + 极光飞羽 + 粒子场
// ═══════════════════════════════════════════════════════════════════════
class _LogoPainter extends CustomPainter {
  final double tunnelProgress;
  final double wingProgress;
  final double particlePhase; // 0..1 循环
  final double glowPulse; // 0..1 光晕强度

  _LogoPainter({
    required this.tunnelProgress,
    required this.wingProgress,
    required this.particlePhase,
    required this.glowPulse,
  });

  // 沿路径均匀采样 N 个点
  static List<Offset> _samplePath(Path path, int count) {
    final metrics = path.computeMetrics().first;
    final len = metrics.length;
    final pts = <Offset>[];
    for (int i = 0; i < count; i++) {
      final t = i / (count - 1);
      final tangent = metrics.getTangentForOffset(t * len);
      if (tangent != null) pts.add(tangent.position);
    }
    return pts;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // 把 SVG viewBox (80,80,160,160) 映射到绘制区域
    canvas.translate(-80 + 37.5, -80 + 47.5);

    // ── 1. 隧道 (Tunnel) ──
    if (tunnelProgress > 0) {
      final tunnelPath = Path()
        ..moveTo(80, 70)
        ..lineTo(160, 150);

      final metrics = tunnelPath.computeMetrics().first;
      final visible =
          metrics.extractPath(0, metrics.length * tunnelProgress);

      // 底层柔光
      final tunnelGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 42
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFB8C3FF).withValues(alpha: 0.12 * glowPulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
      canvas.drawPath(visible, tunnelGlow);

      // 主体渐变笔划
      final tunnelPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 32
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          const Offset(80, 150),
          const Offset(160, 70),
          [
            const Color(0xFFB8C3FF).withValues(alpha: 0.45),
            const Color(0xFFD0BCFF).withValues(alpha: 0.45),
          ],
        );
      canvas.drawPath(visible, tunnelPaint);
    }

    // ── 2. 极光飞羽 (Kinetic Wing) ──
    final wingPath = Path()
      ..moveTo(75, 160)
      ..quadraticBezierTo(110, 100, 170, 65);

    if (wingProgress > 0) {
      final metrics = wingPath.computeMetrics().first;
      final visible =
          metrics.extractPath(0, metrics.length * wingProgress);

      // 氛围光 (Ambient Glow)
      final ambientGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 36
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF69D9C0).withValues(alpha: 0.35 * glowPulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
      canvas.drawPath(visible, ambientGlow);

      // 主体渐变
      final wingPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 28
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(
          const Offset(75, 65),
          const Offset(170, 160),
          [const Color(0xFF69D9C0), const Color(0xFF26A28B)],
        );
      canvas.drawPath(visible, wingPaint);
    }

    // ── 3. 微光粒子场 ──
    if (wingProgress >= 1.0) {
      _drawParticles(canvas, wingPath);
    }

    canvas.restore();
  }

  void _drawParticles(Canvas canvas, Path wingPath) {
    final rng = math.Random(42); // 固定种子 → 每帧位置一致，仅 alpha 变
    final points = _samplePath(wingPath, 12);

    for (int i = 0; i < points.length; i++) {
      final base = points[i];
      // 以 particlePhase 驱动散射距离 + 闪烁
      final angle = rng.nextDouble() * 2 * math.pi;
      final spread = 8 + 18 * math.sin(particlePhase * 2 * math.pi + i);
      final dx = math.cos(angle) * spread;
      final dy = math.sin(angle) * spread;

      // 闪烁 alpha
      final flicker =
          0.3 + 0.7 * ((math.sin(particlePhase * 2 * math.pi * 3 + i * 1.3) + 1) / 2);

      final paint = Paint()
        ..color = const Color(0xFF69D9C0).withValues(alpha: flicker * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(
        Offset(base.dx + dx, base.dy + dy),
        1.8 + rng.nextDouble() * 1.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) {
    return old.tunnelProgress != tunnelProgress ||
        old.wingProgress != wingProgress ||
        old.particlePhase != particlePhase ||
        old.glowPulse != glowPulse;
  }
}
