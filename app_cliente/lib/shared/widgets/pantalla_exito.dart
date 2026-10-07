import 'package:flutter/material.dart';

/// Pantalla de éxito con palomita verde animada. Se usa para: cuenta creada,
/// teléfono registrado, cita confirmada. Continúa sola tras unos segundos.
class PantallaExito extends StatefulWidget {
  final String titulo;
  final String mensaje;
  final String textoBoton;
  final void Function(BuildContext context) onContinuar;
  final int segundosAuto;

  const PantallaExito({
    super.key,
    required this.titulo,
    required this.mensaje,
    required this.textoBoton,
    required this.onContinuar,
    this.segundosAuto = 3,
  });

  @override
  State<PantallaExito> createState() => _PantallaExitoState();
}

class _PantallaExitoState extends State<PantallaExito>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..forward();

  bool _hecho = false;

  void _continuar() {
    if (_hecho || !mounted) return;
    _hecho = true;
    widget.onContinuar(context);
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: widget.segundosAuto), _continuar);
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
                  opacity: CurvedAnimation(parent: _anim, curve: const Interval(0.6, 1.0)),
                  child: Column(
                    children: [
                      Text(
                        widget.titulo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.mensaje,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _continuar,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(widget.textoBoton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Círculo verde que crece y, después, una palomita que se traza.
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
