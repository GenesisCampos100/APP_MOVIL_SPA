import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/tema_state.dart';

/// Abre el selector de tema (fila "Tema" del Perfil).
void abrirTema(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => ListenableBuilder(
      listenable: TemaState.instance,
      builder: (ctx, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tema', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              _Opcion(
                icono: Icons.light_mode_outlined,
                titulo: 'Claro',
                modo: ThemeMode.light,
                cerrar: () => Navigator.pop(ctx),
              ),
              _Opcion(
                icono: Icons.dark_mode_outlined,
                titulo: 'Oscuro',
                modo: ThemeMode.dark,
                cerrar: () => Navigator.pop(ctx),
              ),
              _Opcion(
                icono: Icons.brightness_auto_outlined,
                titulo: 'Automático',
                subtitulo: 'Según la configuración de tu celular',
                modo: ThemeMode.system,
                cerrar: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Opcion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final ThemeMode modo;
  final VoidCallback cerrar;

  const _Opcion({
    required this.icono,
    required this.titulo,
    this.subtitulo,
    required this.modo,
    required this.cerrar,
  });

  @override
  Widget build(BuildContext context) {
    final elegido = TemaState.instance.modo == modo;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icono),
      title: Text(titulo),
      subtitle: subtitulo == null
          ? null
          : Text(subtitulo!, style: const TextStyle(fontSize: 12, color: AppColors.gris)),
      trailing: elegido ? const Icon(Icons.check, color: AppColors.rosaFuerte) : null,
      onTap: () {
        TemaState.instance.cambiar(modo);
        cerrar();
      },
    );
  }
}
