
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import '../../auth/screens/login_admin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _textoFade;
  late final Animation<double> _detallesFade;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // El logo aparece primero.
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.0,
        0.5,
        curve: Curves.easeOut,
      ),
    );

    // El nombre aparece después del logo.
    _textoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.25,
        0.75,
        curve: Curves.easeOut,
      ),
    );

    // El subtítulo y los puntos aparecen al final.
    _detallesFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.55,
        1.0,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();

    // Conservar la navegación actual hacia el Login.
    _navigationTimer = Timer(
      const Duration(milliseconds: 2600),
      () {
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const LoginAdminScreen(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ondas decorativas del fondo.
          const CustomPaint(
            painter: _SplashBackgroundPainter(),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Plantita original del Login.
                    FadeTransition(
                      opacity: _logoFade,
                      child: Container(
                        width: 156,
                        height: 156,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryPinkSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.spa_outlined,
                          size: 85,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ),

                    const SizedBox(height: 27),

                    // Nombre de Aura Spa.
                    FadeTransition(
                      opacity: _textoFade,
                      child: Text(
                        'Aura Spa',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displayBlack.copyWith(
                          fontSize: 40,
                          color: AppColors.textDark,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),

                    const SizedBox(height: 11),

                    FadeTransition(
                      opacity: _detallesFade,
                      child: const Text(
                        'PANEL ADMINISTRATIVO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.8,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ),

                    const SizedBox(height: 45),

                    // Indicador visual de carga.
                    FadeTransition(
                      opacity: _detallesFade,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SplashDot(
                            color: AppColors.primaryPink,
                          ),
                          SizedBox(width: 13),
                          _SplashDot(
                            color: Color(0xFFF2CCD8),
                          ),
                          SizedBox(width: 13),
                          _SplashDot(
                            color: Color(0xFFF2CCD8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Puntos decorativos de carga.
class _SplashDot extends StatelessWidget {
  final Color color;

  const _SplashDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// Fondo con ondas suaves, sin imágenes externas.
class _SplashBackgroundPainter extends CustomPainter {
  const _SplashBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fondoRosa = Paint()
      ..color = const Color(0xFFFCECF0);

    final lineaRosa = Paint()
      ..color = const Color(0xFFECC8D3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    // Onda superior.
    final superior = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.65, 0)
      ..cubicTo(
        w * 0.58, h * 0.09,
        w * 0.27, h * 0.05,
        0, h * 0.21,
      )
      ..close();

    canvas.drawPath(superior, fondoRosa);

    final bordeSuperior = Path()
      ..moveTo(w * 0.65, 0)
      ..cubicTo(
        w * 0.58, h * 0.09,
        w * 0.27, h * 0.05,
        0, h * 0.21,
      );

    canvas.drawPath(bordeSuperior, lineaRosa);

    // Onda inferior.
    final inferior = Path()
      ..moveTo(w, h * 0.74)
      ..cubicTo(
        w * 0.70, h * 0.77,
        w * 0.77, h * 0.93,
        w * 0.36, h * 0.94,
      )
      ..quadraticBezierTo(
        w * 0.10,
        h * 0.96,
        0,
        h,
      )
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(inferior, fondoRosa);

    final bordeInferior = Path()
      ..moveTo(w, h * 0.87)
      ..cubicTo(
        w * 0.73, h * 0.97,
        w * 0.46, h * 0.93,
        w * 0.30, h,
      );

    canvas.drawPath(bordeInferior, lineaRosa);
  }

  @override
  bool shouldRepaint(
    covariant _SplashBackgroundPainter oldDelegate,
  ) {
    return false;
  }
}
