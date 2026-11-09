
import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../auth/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _errorConexion = false;

  @override
  void initState() {
    super.initState();
    _iniciarAplicacion();
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
  Navigator.of(context).pushReplacementNamed(
    AppRoutes.shell,
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/splash_bg.jpg',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black54,
                ],
              ),
            ),
          ),
          const Align(
            alignment: Alignment(0, 0.75),
            child: Text(
              'Aura Spa',
              style: TextStyle(
                fontFamily: 'serif',
                fontStyle: FontStyle.italic,
                fontSize: 44,
                color: Colors.white,
              ),
            ),
          ),

          if (_errorConexion)
            Align(
              alignment: const Alignment(0, 0.95),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No pudimos conectar con AuraSpa',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Comprueba tu conexión a Internet e inténtalo nuevamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorConexion = false;
                        });
                        _comprobarSesion();
                      },
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
