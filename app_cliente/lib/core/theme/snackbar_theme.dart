import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Estilo de los avisos que aparecen abajo ("Agregado a favoritos",
/// "Perfil actualizado", etc.): flotantes, oscuros y con esquinas redondeadas.
const SnackBarThemeData temaAvisos = SnackBarThemeData(
  behavior: SnackBarBehavior.floating,
  backgroundColor: Color(0xFF222222),
  contentTextStyle: TextStyle(color: Colors.white, fontSize: 13),
  actionTextColor: AppColors.rosa,
  elevation: 4,
  insetPadding: EdgeInsets.fromLTRB(20, 0, 20, 16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
);
