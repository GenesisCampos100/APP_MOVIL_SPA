import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formato.dart';
import '../../../data/models/servicio.dart';
import '../../auth/auth_flow.dart';
import '../../auth/auth_state.dart';
import '../../auth/widgets/auth_widgets.dart';
import '../disponibilidad.dart';
import '../reserva_borrador.dart';

/// Agendar cita: calendario + horarios disponibles.
class AgendarCitaScreen extends StatefulWidget {
  final Servicio servicio;
  const AgendarCitaScreen({super.key, required this.servicio});

  @override
  State<AgendarCitaScreen> createState() => _AgendarCitaScreenState();
}

class _AgendarCitaScreenState extends State<AgendarCitaScreen> {
  late DateTime _mes; // primer día del mes que se está viendo
  DateTime? _dia;
  String? _hora;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _mes = DateTime(n.year, n.month);
  }

  bool get _hayMesAnterior {
    final n = DateTime.now();
    return DateTime(_mes.year, _mes.month).isAfter(DateTime(n.year, n.month));
  }

  bool get _hayMesSiguiente {
    final n = DateTime.now();
    final limite = DateTime(n.year, n.month + 3); // se puede agendar 3 meses
    return DateTime(_mes.year, _mes.month + 1).isBefore(limite);
  }

  Future<void> _continuar() async {
    // Si no ha iniciado sesión, primero se le pide (y luego regresa aquí).
    if (!AuthState.instance.isLoggedIn) {
      final ok = await AuthFlow.iniciar(context);
      if (!ok || !mounted) return;
    }
    final usuario = AuthState.instance.usuario;
    if (usuario == null || !mounted) return;

    final borrador = ReservaBorrador(servicio: widget.servicio, fecha: _dia!, hora: _hora!);
    final tieneTelefono = (usuario.telefono ?? '').isNotEmpty;
    Navigator.pushNamed(
      context,
      tieneTelefono ? AppRoutes.especialista : AppRoutes.telefono,
      arguments: borrador,
    );
  }

  @override
  Widget build(BuildContext context) {
    final listo = _dia != null && _hora != null;
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text('Agendar cita',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            const Center(child: Text('Fecha y hora disponible')),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(mesAnio(_mes),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  onPressed: _hayMesAnterior
                      ? () => setState(() => _mes = DateTime(_mes.year, _mes.month - 1))
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: _hayMesSiguiente
                      ? () => setState(() => _mes = DateTime(_mes.year, _mes.month + 1))
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final d in const ['D', 'L', 'M', 'M', 'J', 'V', 'S'])
                  Expanded(
                    child: Center(
                      child: Text(d, style: const TextStyle(fontSize: 13, color: AppColors.gris)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            _calendario(),
            const SizedBox(height: 20),
            _horarios(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: AuthBoton(texto: 'Continuar', onPressed: listo ? _continuar : null),
        ),
      ),
    );
  }

  Widget _calendario() {
    final primero = DateTime(_mes.year, _mes.month, 1);
    final offset = primero.weekday % 7; // domingo = 0
    final diasMes = DateTime(_mes.year, _mes.month + 1, 0).day;
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.15,
      children: [
        for (var i = 0; i < offset; i++) const SizedBox.shrink(),
        for (var d = 1; d <= diasMes; d++) _celdaDia(DateTime(_mes.year, _mes.month, d)),
      ],
    );
  }

  Widget _celdaDia(DateTime d) {
    final habil = Disponibilidad.diaHabil(d);
    final seleccionado = _dia != null &&
        _dia!.year == d.year &&
        _dia!.month == d.month &&
        _dia!.day == d.day;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: habil ? () => setState(() {
            _dia = d;
            _hora = null;
          }) : null,
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: seleccionado ? AppColors.rosa : null,
          ),
          child: Text(
            '${d.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w400,
              color: !habil ? Colors.black26 : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _horarios() {
    if (_dia == null) {
      return const Center(
        child: Text('Selecciona una fecha para ver los horarios.',
            style: TextStyle(color: AppColors.gris, fontSize: 13)),
      );
    }
    final disponibles = Disponibilidad.horarios
        .where((h) => Disponibilidad.horaDisponible(_dia!, h))
        .toList();
    if (disponibles.isEmpty) {
      return const Center(
        child: Text('No hay horarios disponibles para este día.',
            style: TextStyle(color: AppColors.gris, fontSize: 13)),
      );
    }
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: [
        for (final h in disponibles)
          GestureDetector(
            onTap: () => setState(() => _hora = h),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: h == _hora ? AppColors.rosaSuave : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: h == _hora ? AppColors.rosaFuerte : Colors.black87),
              ),
              child: Text(
                hora12(h),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: h == _hora ? AppColors.rosaFuerte : Colors.black87,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
