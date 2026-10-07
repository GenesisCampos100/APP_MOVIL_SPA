import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formato.dart';
import '../../../data/models/cita.dart';
import '../../../data/repositories/citas_repository.dart';
import '../../auth/auth_flow.dart';
import '../../auth/auth_state.dart';
import '../../auth/widgets/auth_widgets.dart';

const String _titulo = 'Sin registro de actividad';
const String _mensajeSinSesion = 'Inicia sesión para poder ver y gestionar tus citas.';
const String _mensajeConSesion = 'Aquí se llevará el registro de tus citas realizadas.';

/// Sin sesión: mensaje + botón "Inicio de sesión".
/// Con sesión y sin citas: mensaje de registro vacío.
/// Con citas: lista con filtros Todas / Próximas / Anteriores.
/// [conAtras] = true cuando se abre desde el Perfil (agrega flecha de regreso).
class AppointmentsScreen extends StatefulWidget {
  final bool conAtras;
  const AppointmentsScreen({super.key, this.conAtras = false});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  static const _filtros = ['Todas', 'Próximas', 'Anteriores'];
  String _filtro = 'Todas';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AuthState.instance, CitasRepository.instance]),
      builder: (context, _) {
        final usuario = AuthState.instance.usuario;
        final citas = usuario == null
            ? <Cita>[]
            : CitasRepository.instance.citasDe(usuario.correo);
        return Scaffold(
          appBar: widget.conAtras ? AppBar() : null,
          body: SafeArea(
            child: citas.isEmpty ? _vacio(usuario != null) : _lista(citas),
          ),
        );
      },
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
              decoration: const BoxDecoration(
                color: AppColors.rosaSuave,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 56,
                color: AppColors.rosaFuerte,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              _titulo,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              conSesion ? _mensajeConSesion : _mensajeSinSesion,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.gris),
            ),
            if (!conSesion) ...[
              const SizedBox(height: 28),
              AuthBoton(
                texto: 'Inicio de sesión',
                onPressed: () => AuthFlow.iniciar(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _lista(List<Cita> todas) {
    final visibles = todas.where((c) {
      if (_filtro == 'Próximas') return c.esProxima;
      if (_filtro == 'Anteriores') return !c.esProxima;
      return true;
    }).toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Center(
          child: Text('Mis citas', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            for (final f in _filtros) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _filtro = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: f == _filtro ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: f == _filtro ? Colors.black : Colors.black26),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: f == _filtro ? Colors.white : AppColors.gris,
                      ),
                    ),
                  ),
                ),
              ),
              if (f != _filtros.last) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 16),
        if (visibles.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text('No hay citas en esta categoría',
                  style: TextStyle(color: AppColors.gris)),
            ),
          )
        else
          for (final c in visibles) ...[
            _CitaCard(cita: c),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _CitaCard extends StatelessWidget {
  final Cita cita;
  const _CitaCard({required this.cita});

  void _proximamente(BuildContext context, String que) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$que: próximamente')),
      );

  @override
  Widget build(BuildContext context) {
    final c = cita;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E3E3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(c.servicioNombre,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              _Estado(c.estado),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${fechaCorta(c.fecha)} - ${hora12(c.horaInicio)} - ${c.empleadoNombre}',
            style: const TextStyle(fontSize: 12, color: AppColors.gris),
          ),
          const SizedBox(height: 12),
          _acciones(context),
        ],
      ),
    );
  }

  Widget _acciones(BuildContext context) {
    ButtonStyle contorno() => OutlinedButton.styleFrom(
          foregroundColor: AppColors.gris,
          side: const BorderSide(color: Colors.black26),
          minimumSize: const Size.fromHeight(40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );
    ButtonStyle negro() => FilledButton.styleFrom(
          backgroundColor: Colors.black,
          minimumSize: const Size.fromHeight(40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        );

    switch (cita.estado) {
      case Cita.completada:
        return FilledButton(
          style: negro(),
          onPressed: () => Navigator.pushNamed(context, AppRoutes.escribirResena, arguments: cita),
          child: const Text('Escribir reseña'),
        );
      case Cita.cancelada:
        return FilledButton(
          style: negro(),
          onPressed: () => _proximamente(context, 'Reservar de nuevo'),
          child: const Text('Reservar de nuevo'),
        );
      default:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: contorno(),
                onPressed: () => _proximamente(context, 'Reagendar'),
                child: const Text('Reagendar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                style: contorno(),
                onPressed: () => _proximamente(context, 'Cancelar cita'),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        );
    }
  }
}

class _Estado extends StatelessWidget {
  final String estado;
  const _Estado(this.estado);

  @override
  Widget build(BuildContext context) {
    Color fondo;
    Color texto;
    switch (estado) {
      case Cita.confirmada:
        fondo = Colors.black;
        texto = Colors.white;
        break;
      case Cita.cancelada:
        fondo = AppColors.rosaSuave;
        texto = AppColors.rosaFuerte;
        break;
      default:
        fondo = const Color(0xFFEDEDED);
        texto = AppColors.gris;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(6)),
      child: Text(estado,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: texto)),
    );
  }
}
