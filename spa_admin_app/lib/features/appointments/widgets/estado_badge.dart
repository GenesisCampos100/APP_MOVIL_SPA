import 'package:flutter/material.dart';

/// Muestra el estado devuelto por la API sin modificarlo.
/// Los colores se adaptan a los distintos estados, sin depender de mayúsculas.
class EstadoBadge extends StatelessWidget {
  final String estado;

  const EstadoBadge({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final normalizado = estado.trim().toLowerCase();
    final (Color fondo, Color texto, IconData icono) = switch (normalizado) {
      'confirmada' => (
          const Color(0xFFE7F4EC),
          const Color(0xFF216A45),
          Icons.check_circle_outline,
        ),
      'pendiente' => (
          const Color(0xFFFFF1DB),
          const Color(0xFF885817),
          Icons.schedule_outlined,
        ),
      'completada' => (
          const Color(0xFFEDE7F6),
          const Color(0xFF62408A),
          Icons.task_alt_outlined,
        ),
      'cancelada' => (
          const Color(0xFFFFE7E7),
          const Color(0xFF9F3D45),
          Icons.cancel_outlined,
        ),
      'en proceso' => (
          const Color(0xFFE6F1FC),
          const Color(0xFF2F6392),
          Icons.timelapse_outlined,
        ),
      _ => (
          const Color(0xFFF0EDF0),
          const Color(0xFF5E5660),
          Icons.info_outline,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: texto),
          const SizedBox(width: 5),
          Text(
            estado,
            style: TextStyle(
              color: texto,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
