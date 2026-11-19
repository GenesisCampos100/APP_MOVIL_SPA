import 'package:flutter/material.dart';

import '../../../core/i18n/textos.dart';
import '../../../core/routes/app_routes.dart';
import '../../auth/auth_state.dart';
import '../../../data/services/notificacionesPush_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _errorConexion = false;

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
    _iniciarAplicacion();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _iniciarAplicacion() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    await _comprobarSesion();
  }

  Future<void> _comprobarSesion() async {
    try {
      await AuthState.instance.restaurarSesion();

      if (!mounted) return;

      if (AuthState.instance.errorConexion) {
        setState(() {
          _errorConexion = true;
        });
        return;
      }

      _entrarAplicacion();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorConexion = true;
      });
    }
  }

  void _entrarAplicacion() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificacionesPushService.instance.procesarMensajePendiente();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7FA),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFDF7FA),
                  Color(0xFFF8EAF1),
                  Color(0xFFF4DCE8),
                ],
              ),
            ),
          ),

          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFFF3C7DA).withOpacity(0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: -100,
            left: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: const Color(0xFFE98DB4).withOpacity(0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 145,
                          height: 145,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.55),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD85C93).withOpacity(0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/icon_app.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Aura Spa',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C1F26),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tu bienestar, más cerca de ti',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: const Color(0xFF7A5967).withOpacity(0.95),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 26),
                      Container(
                        width: 110,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE98DB4).withOpacity(0.55),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_errorConexion)
            Align(
              alignment: const Alignment(0, 0.93),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFF0D5E1),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Color(0xFFD85C93),
                        size: 30,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.t('splash.error_titulo'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF2C1F26),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.t('splash.error_msg'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF6F5A64),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _errorConexion = false;
                            });
                            _comprobarSesion();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD85C93),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(context.t('comun.reintentar')),
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