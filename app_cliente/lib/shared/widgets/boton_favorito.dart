import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Botón circular con un corazón. Vacío = no es favorito; lleno = favorito.
class BotonFavorito extends StatelessWidget {
  final bool esFavorito;
  final VoidCallback onPressed;
  final double size;

  const BotonFavorito({
    super.key,
    required this.esFavorito,
    required this.onPressed,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: esFavorito ? 'Quitar de favoritos' : 'Agregar a favoritos',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.rosaFuerte, width: 1.5),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animacion) =>
                  ScaleTransition(scale: animacion, child: child),
              child: Icon(
                esFavorito ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(esFavorito),
                color: AppColors.rosaFuerte,
                size: size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
