import 'package:flutter/material.dart';

import '../../shell/shell_controller.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../core/utils/errores.dart';
import '../../../core/utils/formato.dart';
import '../../../data/models/cita.dart';
import '../../../data/repositories/citas_repository.dart';
import '../../../data/services/sesion_service.dart';
import '../../auth/auth_state.dart';
import '../../auth/auth_flow.dart';
import '../../auth/widgets/auth_widgets.dart';
import '../widgets/acciones_cita.dart';

/// Sin sesión: mensaje + botón "Inicio de sesión".
/// Con sesión y sin citas: mensaje de registro vacío.
/// Con citas: lista con filtros Todas / Próximas / Anteriores.
/// [conAtras] = true cuando se abre desde el Perfil.
class AppointmentsScreen extends StatefulWidget {
  final bool conAtras;

  const AppointmentsScreen({
    super.key,
    this.conAtras = false,
  });

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  // Clave interna -> clave de traducción.
  static const _filtros = {
    'todas': 'citas.f_todas',
    'proximas': 'citas.f_proximas',
    'anteriores': 'citas.f_anteriores',
  };

  String _filtro = 'todas';

  List<Cita> _citas = [];
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _cargarCitas();

    ShellController.tab.addListener(_alCambiarPestana);
  }

  void _alCambiarPestana() {
    if (ShellController.tab.value == 2) {
      _cargarCitas();
    }
  }

  @override
  void dispose() {
    ShellController.tab.removeListener(_alCambiarPestana);
    super.dispose();
  }

  Future<void> _cargarCitas() async {
    final sesion = SesionService.instance;

    if (!sesion.estaIniciada) {
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final citas = await CitasRepository.instance.obtenerMisCitas();

      if (!mounted) return;

      setState(() {
        _citas = citas;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _error = textoError(context, e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = SesionService.instance;
    final tieneSesion = sesion.estaIniciada;

    return Scaffold(
      appBar: widget.conAtras ? AppBar() : null,
      body: SafeArea(
        child: !tieneSesion
            ? _vacio(false)
            : _cargando
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _error != null
                    ? _errorWidget()
                    : _citas.isEmpty
                        ? _vacio(true)
                        : _lista(_citas),
      ),
    );
  }

  Widget _errorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: AppColors.rosaFuerte,
            ),
            const SizedBox(height: 16),
            Text(
              context.t('citas.error_titulo'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? context.t('citas.error_generico'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.aura.textoSecundario,
              ),
            ),
            const SizedBox(height: 24),
            AuthBoton(
              texto: context.t('comun.reintentar'),
              onPressed: _cargarCitas,
            ),
          ],
        ),
      ),
    );
  }

  Widget _vacio(bool conSesion) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: context.aura.rosaSuave,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 56,
                color: AppColors.rosaFuerte,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.t('citas.vacio_titulo'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              conSesion
                  ? context.t('citas.con_sesion')
                  : context.t('citas.sin_sesion'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.aura.textoSecundario,
              ),
            ),
            if (!conSesion) ...[
              const SizedBox(height: 28),
              AuthBoton(
                texto: context.t('citas.iniciar'),
                onPressed: () async {
                  await AuthFlow.iniciar(context);

                  if (!mounted) return;

                  await _cargarCitas();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _lista(List<Cita> todas) {
    final visibles = todas.where((c) {
      if (_filtro == 'proximas') {
        return c.esProxima;
      }

      if (_filtro == 'anteriores') {
        return !c.esProxima;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final fechaComparacion = b.fecha.compareTo(a.fecha);

        if (fechaComparacion != 0) {
          return fechaComparacion;
        }

        return b.horaInicio.compareTo(a.horaInicio);
      });

    final ac = context.aura;

    return RefreshIndicator(
      onRefresh: _cargarCitas,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Center(
            child: Text(
              context.t('citas.titulo'),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (final f in _filtros.keys) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _filtro = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: f == _filtro ? ac.boton : ac.superficie,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: f == _filtro ? ac.boton : ac.borde,
                        ),
                      ),
                      child: Text(
                        context.t(_filtros[f]!),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: f == _filtro
                              ? ac.textoBoton
                              : ac.textoSecundario,
                        ),
                      ),
                    ),
                  ),
                ),
                if (f != _filtros.keys.last)
                  const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (visibles.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  context.t('citas.sin_categoria'),
                  style: TextStyle(
                    color: ac.textoSecundario,
                  ),
                ),
              ),
            )
          else
            for (final c in visibles) ...[
              _CitaCard(cita: c, onCambio: _cargarCitas),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _CitaCard extends StatelessWidget {
  final Cita cita;
  final VoidCallback? onCambio;

  const _CitaCard({
    required this.cita,
    this.onCambio,
  });

  void _proximamente(
    BuildContext context,
    String que,
  ) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('comun.proximamente', {'que': que})),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = cita;
    final ac = context.aura;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ac.superficie,
        border: Border.all(
          color: ac.borde,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.servicioNombre.isEmpty
                      ? context.t('citas.servicio')
                      : c.servicioNombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _Estado(c.estado),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${fechaCorta(c.fecha)} - '
            '${hora12(c.horaInicio)} - '
            '${c.empleadoNombre.isEmpty ? context.t('citas.empleado_asignado') : c.empleadoNombre}',
            style: TextStyle(
              fontSize: 12,
              color: ac.textoSecundario,
            ),
          ),
          const SizedBox(height: 12),
          _acciones(context),
        ],
      ),
    );
  }

  Widget _acciones(BuildContext context) {
    final ac = context.aura;
    ButtonStyle negro() => FilledButton.styleFrom(
          backgroundColor: ac.boton,
          foregroundColor: ac.textoBoton,
          minimumSize: const Size.fromHeight(40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        );

    switch (cita.estado) {
      case Cita.completada:
        return FilledButton(
          style: negro(),
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.escribirResena,
            arguments: cita,
          ),
          child: Text(context.t('citas.escribir_resena')),
        );

      case Cita.cancelada:
        return FilledButton(
          style: negro(),
          onPressed: () => _proximamente(
            context,
            context.t('citas.reservar_de_nuevo'),
          ),
          child: Text(context.t('citas.reservar_de_nuevo')),
        );

      default:
        // Confirmada: Reagendar / Cancelar (se desactivan a 24 h o menos).
        return AccionesCita(cita: cita, onCambio: onCambio);
    }
  }
}

class _Estado extends StatelessWidget {
  final String estado;

  const _Estado(this.estado);

  @override
  Widget build(BuildContext context) {
    final ac = context.aura;
    Color fondo;
    Color texto;

    switch (estado) {
      case Cita.confirmada:
        fondo = ac.boton;
        texto = ac.textoBoton;
        break;

      case Cita.cancelada:
        fondo = ac.rosaSuave;
        texto = AppColors.rosaFuerte;
        break;

      default:
        fondo = ac.campoBloqueado;
        texto = ac.textoSecundario;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        context.tOr('estado.$estado', estado),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: texto,
        ),
      ),
    );
  }
}
