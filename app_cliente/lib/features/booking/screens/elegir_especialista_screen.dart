import 'package:flutter/material.dart';

import '../../../core/i18n/textos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../core/utils/errores.dart';
import '../../../data/models/empleado.dart';
import '../../../data/repositories/empleados_repository.dart';
import '../../../data/repositories/citas_repository.dart';
import '../../../data/repositories/favoritos_repository.dart';
import '../../../shared/widgets/boton_favorito.dart';
import '../../auth/widgets/auth_widgets.dart';
import '../../favorites/screens/favorites_screen.dart';
import '../reserva_borrador.dart';

/// "Elige a tu especialista": lista de empleados que hacen el servicio,
/// más la opción "Cualquier disponible". Los favoritos salen primero y cada
/// especialista tiene su corazón.
class ElegirEspecialistaScreen extends StatefulWidget {
  final ReservaBorrador borrador;

  const ElegirEspecialistaScreen({
    super.key,
    required this.borrador,
  });

  @override
  State<ElegirEspecialistaScreen> createState() =>
      _ElegirEspecialistaScreenState();
}

class _ElegirEspecialistaScreenState
    extends State<ElegirEspecialistaScreen> {
  final _repo = EmpleadosRepository();

  late final Future<List<Empleado>> _futuro = _repo
      .obtenerParaServicio(widget.borrador.servicio.id)
      .then(_favoritosPrimero);

  Empleado _seleccion = Empleado.cualquiera;

  bool _apartando = false;

  /// Los especialistas favoritos aparecen primero (solo al abrir la pantalla).
  List<Empleado> _favoritosPrimero(List<Empleado> lista) {
    final repo = FavoritosRepository.instance;
    return [
      ...lista.where((e) => repo.esFavoritoEmpleado(e.id)),
      ...lista.where((e) => !repo.esFavoritoEmpleado(e.id)),
    ];
  }

  /// Crea el apartado temporal y después abre la confirmación.
  Future<void> _continuar() async {
    if (_apartando) return;

    setState(() => _apartando = true);

    
  try {
    // Si es un reagendamiento, actualizar la cita directamente.
    if (widget.borrador.esReagendamiento) {
      await CitasRepository.instance.reagendarCita(
        idCita: widget.borrador.idCitaReagendar!,
        idEmpleado: _seleccion.id,
        fecha: widget.borrador.fecha,
        hora: widget.borrador.hora,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita reagendada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Cierra ElegirEspecialistaScreen
      Navigator.pop(context); // Cierra AgendarCitaScreen

      return;
    }

    // Si es una reserva nueva, utilizar el apartado temporal.
    final respuesta = await CitasRepository.instance.apartarHorario(
      servicio: widget.borrador.servicio,
      empleado: _seleccion,
      fecha: widget.borrador.fecha,
      hora: widget.borrador.hora,
    );

    final reservaJson =
        respuesta['reserva'] as Map<String, dynamic>;

    final empleadoJson =
        respuesta['empleado'] as Map<String, dynamic>;

    final idReserva = (reservaJson['id_reserva'] as num).toInt();

    final fechaExpiracion =
        DateTime.parse(reservaJson['fecha_expiracion'].toString());

    final empleadoAsignado = Empleado.fromJson(empleadoJson);

    final nuevoBorrador = widget.borrador.conApartado(
      idReserva: idReserva,
      fechaExpiracion: fechaExpiracion,
      empleado: empleadoAsignado,
    );

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      AppRoutes.confirmarCita,
      arguments: nuevoBorrador,
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString().replaceFirst('Exception: ', ''),
        ),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _apartando = false);
    }
  }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<List<Empleado>>(
        future: _futuro,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text(context.t('esp.error')),
            );
          }

          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final lista = [Empleado.cualquiera, ...snap.data!];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              Center(
                child: Text(
                  context.t('esp.titulo'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              for (final e in lista) ...[
                _TarjetaEmpleado(
                  empleado: e,
                  seleccionado: e.id == _seleccion.id,
                  onTap: () {
                    if (!_apartando) {
                      setState(() => _seleccion = e);
                    }
                  },
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
          child: _apartando
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                )
              : AuthBoton(
                  texto: context.t('comun.continuar'),
                  onPressed: _continuar,
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
    final c = context.aura;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: seleccionado
              ? c.rosaSuave.withValues(alpha: 0.7)
              : c.superficie,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: seleccionado ? c.texto : c.borde,
            width: seleccionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: e.esCualquiera
                  ? c.rosaSuave
                  : AppColors.rosa,
              backgroundImage:
                  (!e.esCualquiera && foto != null)
                      ? NetworkImage(foto)
                      : null,
              child: e.esCualquiera
                  ? const Icon(
                      Icons.person_search_outlined,
                      color: AppColors.rosaFuerte,
                    )
                  : (foto == null
                      ? Text(
                          e.inicial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.esCualquiera
                        ? context.t('esp.cualquiera')
                        : e.nombreCompleto,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.esCualquiera
                        ? context.t('esp.cualquiera_sub')
                        : e.puesto,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            if (!e.esCualquiera && e.rating > 0)
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    size: 14,
                    color: Colors.amber,
                  ),
                  Text(
                    ' ${e.rating}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            if (!e.esCualquiera) ...[
              const SizedBox(width: 8),
              ListenableBuilder(
                listenable: FavoritosRepository.instance,
                builder: (context, _) => BotonFavorito(
                  esFavorito:
                      FavoritosRepository.instance.esFavoritoEmpleado(e.id),
                  size: 34,
                  onPressed: () => alternarFavoritoEmpleado(context, e),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
