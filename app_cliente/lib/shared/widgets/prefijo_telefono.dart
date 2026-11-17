import 'package:flutter/material.dart';
import '../../core/theme/aura_colores.dart';

/// Recuadro "+52" que va a la izquierda del campo de teléfono.
///
/// Usa un InputDecorator con el mismo relleno que el TextField, así que
/// SIEMPRE mide lo mismo de alto que el campo, sin importar el tamaño de
/// texto del celular. Úsalo junto con [PrefijoTelefono.relleno] en el
/// contentPadding del campo para que los dos queden idénticos.
///
///   Row(
///     crossAxisAlignment: CrossAxisAlignment.start,
///     children: [
///       const PrefijoTelefono(),
///       const SizedBox(width: 8),
///       Expanded(child: TextField(... contentPadding: PrefijoTelefono.relleno ...)),
///     ],
///   )
class PrefijoTelefono extends StatelessWidget {
  final String prefijo;
  final double radio;
  const PrefijoTelefono({super.key, this.prefijo = '+52', this.radio = 8});

  /// Mismo relleno que debe llevar el TextField del teléfono.
  static const EdgeInsets relleno = EdgeInsets.symmetric(horizontal: 12, vertical: 14);

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final colorBorde = oscuro ? c.textoSecundario : Colors.black54;
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(radio),
      borderSide: BorderSide(color: colorBorde),
    );
    return SizedBox(
      width: 64,
      child: InputDecorator(
        decoration: InputDecoration(
          isDense: true,
          contentPadding: relleno,
          border: borde,
          enabledBorder: borde,
        ),
        child: Center(
          child: Text(
            prefijo,
            style: (Theme.of(context).textTheme.bodyLarge ?? const TextStyle())
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
