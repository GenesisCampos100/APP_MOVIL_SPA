import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/empleado.dart';
import '../../../data/repositories/empleados_repository.dart';
import '../../auth/widgets/auth_widgets.dart';
import '../reserva_borrador.dart';

/// "Elige a tu especialista": lista de empleados que hacen el servicio,
/// más la opción "Cualquier disponible".
class ElegirEspecialistaScreen extends StatefulWidget {
  final ReservaBorrador borrador;
  const ElegirEspecialistaScreen({super.key, required this.borrador});

  @override
  State<ElegirEspecialistaScreen> createState() => _ElegirEspecialistaScreenState();
}

class _ElegirEspecialistaScreenState extends State<ElegirEspecialistaScreen> {
  final _repo = EmpleadosRepository();
  late final Future<List<Empleado>> _futuro =
      _repo.obtenerParaServicio(widget.borrador.servicio.id);
  Empleado _seleccion = Empleado.cualquiera;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<List<Empleado>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('No se pudo cargar el personal'));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final lista = [Empleado.cualquiera, ...snap.data!];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              const Center(
                child: Text('Elige a tu especialista',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 24),
              for (final e in lista) ...[
                _TarjetaEmpleado(
                  empleado: e,
                  seleccionado: e.id == _seleccion.id,
                  onTap: () => setState(() => _seleccion = e),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: AuthBoton(
            texto: 'Continuar',
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.confirmarCita,
              arguments: widget.borrador.conEmpleado(_seleccion),
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaEmpleado extends StatelessWidget {
  final Empleado empleado;
  final bool seleccionado;
  final VoidCallback onTap;
  const _TarjetaEmpleado({
    required this.empleado,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final e = empleado;
    final foto = e.foto;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.rosaSuave.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? Colors.black : Colors.black12,
            width: seleccionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: e.esCualquiera ? AppColors.rosaSuave : AppColors.rosa,
              backgroundImage: (!e.esCualquiera && foto != null) ? NetworkImage(foto) : null,
              child: e.esCualquiera
                  ? const Icon(Icons.person_search_outlined, color: AppColors.rosaFuerte)
                  : (foto == null
                      ? Text(e.inicial,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))
                      : null),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.esCualquiera ? 'Cualquier disponible' : e.nombreCompleto,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.esCualquiera ? 'Te asignamos al primero disponible' : e.puesto,
                    style: const TextStyle(fontSize: 12, color: AppColors.gris),
                  ),
                ],
              ),
            ),
            if (!e.esCualquiera && e.rating > 0)
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  Text(' ${e.rating}', style: const TextStyle(fontSize: 12)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
