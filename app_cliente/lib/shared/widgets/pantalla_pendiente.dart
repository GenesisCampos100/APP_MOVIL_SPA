import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla provisional: título + descripción de lo que irá ahí.
class PantallaPendiente extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final List<Widget> acciones;

  const PantallaPendiente({
    super.key,
    required this.titulo,
    required this.descripcion,
    this.icono = Icons.construction,
    this.acciones = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icono, size: 56, color: AppColors.rosaFuerte),
              const SizedBox(height: 12),
              Text(titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(descripcion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.gris)),
              const SizedBox(height: 16),
              ...acciones,
            ],
          ),
        ),
      ),
    );
  }
}
