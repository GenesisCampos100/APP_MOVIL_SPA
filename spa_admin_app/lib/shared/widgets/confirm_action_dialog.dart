import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';

/// Reutilizable para confirmar operaciones antes de ejecutar sus efectos.
/// Devuelve true solo cuando el usuario acepta explícitamente.
Future<bool> mostrarConfirmacion({
  required BuildContext context,
  required String titulo,
  required String mensaje,
  String textoConfirmar = 'Confirmar',
  IconData icono = Icons.help_outline_rounded,
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.cardBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          Icon(icono, color: AppColors.primaryPink),
          const SizedBox(width: 10),
          Expanded(child: Text(titulo, style: const TextStyle(fontSize: 18))),
        ],
      ),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryPink),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
  return confirmado ?? false;
}
