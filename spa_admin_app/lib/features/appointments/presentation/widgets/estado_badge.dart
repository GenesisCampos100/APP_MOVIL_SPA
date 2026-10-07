import 'package:flutter/material.dart';

class EstadoBadge extends StatelessWidget {
  final String estado; // 'Confirmada', 'En proceso', 'Pendiente', 'Completada', 'Cancelada'

  const EstadoBadge({
    super.key,
    required this.estado,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor = Colors.white;

    switch (estado) {
      case 'Confirmada':
        bgColor = const Color(0xFF4CAF50); // Verde
        break;
      case 'En proceso':
        bgColor = const Color(0xFFFF9800); // Naranja
        break;
      case 'Pendiente':
        bgColor = const Color(0xFF9E9E9E); // Gris
        break;
      case 'Completada':
        bgColor = const Color(0xFF9C27B0); // Púrpura
        break;
      default:
        bgColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
