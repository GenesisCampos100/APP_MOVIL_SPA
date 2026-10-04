import 'package:flutter/material.dart';
import '../auth_flow.dart';
import '../widgets/auth_widgets.dart';

/// Registro completado: palomita verde animada y regreso a la app.
class AuthSuccessScreen extends StatefulWidget {
  const AuthSuccessScreen({super.key});

  @override
  State<AuthSuccessScreen> createState() => _AuthSuccessScreenState();
}

class _AuthSuccessScreenState extends State<AuthSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  @override
  void initState() {
    super.initState();
    // Continúa solo después de unos segundos.
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) AuthFlow.terminar(context);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) => CustomPaint(
                    size: const Size(120, 120),
                    painter: _CheckPainter(_anim.value),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _anim,
                    curve: const Interval(0.6, 1.0),
                  ),
                  child: const Column(
                    children: [
                      Text('¡Cuenta creada!',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text(
                        'Tu registro se completó correctamente.\nYa puedes reservar tus servicios.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                AuthBoton(texto: 'Continuar', onPressed: () => AuthFlow.terminar(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dibuja un círculo verde que crece y, después, una palomita que se traza.
class _CheckPainter extends CustomPainter {
  final double progreso; // 0 a 1
  _CheckPainter(this.progreso);

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);

    final tCirculo = (progreso / 0.5).clamp(0.0, 1.0);
    final radio = size.width / 2 * Curves.easeOutBack.transform(tCirculo);
    canvas.drawCircle(centro, radio < 0 ? 0 : radio, Paint()..color = const Color(0xFF4CAF50));

    final tCheck = ((progreso - 0.5) / 0.5).clamp(0.0, 1.0);
    if (tCheck <= 0) return;
    final ruta = Path()
      ..moveTo(size.width * 0.28, size.height * 0.52)
      ..lineTo(size.width * 0.44, size.height * 0.68)
      ..lineTo(size.width * 0.74, size.height * 0.36);
    final metrica = ruta.computeMetrics().first;
    canvas.drawPath(
      metrica.extractPath(0, metrica.length * tCheck),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter viejo) => viejo.progreso != progreso;
}
