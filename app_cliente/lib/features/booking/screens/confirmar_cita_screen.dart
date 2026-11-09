
import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formato.dart';
import '../../../data/repositories/citas_repository.dart';
import '../../../shared/widgets/pantalla_exito.dart';
import '../../../shared/widgets/servicio_visual.dart';
import '../../auth/widgets/auth_widgets.dart';
import '../../shell/shell_controller.dart';
import '../reserva_borrador.dart';

/// "Confirmar tu cita": resumen de la reserva y botón para confirmar.
class ConfirmarCitaScreen extends StatefulWidget {
  final ReservaBorrador borrador;

  const ConfirmarCitaScreen({
    super.key,
    required this.borrador,
  });

  @override
  State<ConfirmarCitaScreen> createState() =>
      _ConfirmarCitaScreenState();
}

class _ConfirmarCitaScreenState extends State<ConfirmarCitaScreen> {
  bool _cargando = false;

  /// Confirma el apartado temporal y registra la cita definitiva.
  Future<void> _confirmar() async {
    if (_cargando) return;

    final b = widget.borrador;

    if (b.idReserva == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No existe un apartado válido para confirmar'),
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      await CitasRepository.instance.confirmarApartado(
        idReserva: b.idReserva!,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PantallaExito(
            titulo: '¡Cita confirmada!',
            mensaje: 'Tu cita quedó registrada.\nTe esperamos en Aura Spa.',
            textoBoton: 'Ver mis citas',
            onContinuar: (ctx) {
              ShellController.irA(2);
              Navigator.popUntil(
                ctx,
                ModalRoute.withName(AppRoutes.shell),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _cargando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  /// Cancela el apartado temporal y regresa a la selección anterior.
  Future<void> _cancelar() async {
    if (_cargando) return;

    final idReserva = widget.borrador.idReserva;

    if (idReserva == null) {
      Navigator.popUntil(
        context,
        ModalRoute.withName(AppRoutes.detalle),
      );
      return;
    }

    setState(() => _cargando = true);

    try {
      await CitasRepository.instance.cancelarApartado(idReserva);

      if (!mounted) return;

      Navigator.popUntil(
        context,
        ModalRoute.withName(AppRoutes.detalle),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _cargando = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.borrador;
    final s = b.servicio;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          const Center(
            child: Text(
              'Confirmar tu cita',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'Revisa los detalles antes de reservar',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gris,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ServicioThumb(
            categoria: s.categoria,
            imagen: s.imagen,
            width: double.infinity,
            height: 150,
            radius: 14,
            iconSize: 60,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFE3E3E3),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _Fila('Servicio', s.nombre),
                _Fila(
                  'Especialista',
                  b.empleado.esCualquiera
                      ? 'Cualquier disponible'
                      : b.empleado.nombreCompleto,
                ),
                _Fila(
                  'Fecha y hora',
                  '${fechaCorta(b.fecha)} - ${hora12(b.hora)}',
                ),
                _Fila('Duración', s.duracionTexto),
                _Fila(
                  'Total',
                  '${s.precioTexto} MXN',
                  ultima: true,
                  destacado: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Consejo: llega 10 minutos antes de tu cita.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.gris,
              ),
            ),
          ),
          if (b.fechaExpiracion != null) ...[
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Tu horario está apartado temporalmente por 5 minutos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.gris,
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _cargando ? null : _cancelar,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEDEDED),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuthBoton(
                  texto: 'Confirmar',
                  cargando: _cargando,
                  onPressed: _confirmar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool ultima;
  final bool destacado;

  const _Fila(
    this.etiqueta,
    this.valor, {
    this.ultima = false,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: ultima
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFFEDEDED),
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.gris,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: TextStyle(
              fontSize: destacado ? 16 : 14,
              fontWeight: destacado
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
