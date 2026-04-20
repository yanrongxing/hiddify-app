import 'package:flutter/material.dart';
import 'package:hiddify/features/common/splash_logo_widget.dart';

/// 应用启动动画包装器
///
/// 在应用初始化完成后，在最上层叠加一个动态 Logo 启动画面。
/// 当 Logo 描线动画完成后，自动淡出并移除自身，露出下方真正的页面。
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.child});

  final Widget child;

  /// 全局控制：外部调用此方法来触发启动画面的消失
  static void dismiss() {
    _SplashOverlayState._shouldDismiss.value = true;
  }

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  /// 跨实例共享的 dismiss 信号
  static final ValueNotifier<bool> _shouldDismiss = ValueNotifier(false);

  late AnimationController _fadeOutController;
  late Animation<double> _fadeOut;

  bool _logoDrawFinished = false;
  bool _removed = false;

  @override
  void initState() {
    super.initState();

    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeInOut),
    );

    _fadeOutController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _removed = true);
      }
    });

    // 监听外部 dismiss 信号
    _shouldDismiss.addListener(_onDismissSignal);
  }

  void _onDismissSignal() {
    _tryFadeOut();
  }

  /// Logo 描线动画完成
  void _onLogoFinished() {
    _logoDrawFinished = true;
    // 描线结束后等 600ms 再开始淡出，让用户看到完整的呼吸效果
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _tryFadeOut();
    });
  }

  void _tryFadeOut() {
    if (_logoDrawFinished && _shouldDismiss.value && !_removed) {
      _fadeOutController.forward();
    }
  }

  @override
  void dispose() {
    _shouldDismiss.removeListener(_onDismissSignal);
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
      children: [
        widget.child,
        if (!_removed)
          AnimatedBuilder(
            animation: _fadeOut,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeOut.value,
                child: child,
              );
            },
            child: SplashLogoWidget(onFinished: _onLogoFinished),
          ),
      ],
      ),
    );
  }
}
