import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/features/appointments/data/models/appointment_model.dart';

class CompletarServicioScreen extends StatefulWidget {
  final AppointmentModel appointment;
  final Function(AppointmentModel) onCompleted;

  const CompletarServicioScreen({
    super.key,
    required this.appointment,
    required this.onCompleted,
  });

  @override
  State<CompletarServicioScreen> createState() => _CompletarServicioScreenState();
}

class _CompletarServicioScreenState extends State<CompletarServicioScreen> {
  final TextEditingController _observacionesController = TextEditingController();
  bool _tiempoYForma = false;
  bool _citaSeguimiento = false;

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  void _showConfirmationModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Confirmar finalización?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'La cita se marcará como Completada y la cabina quedará disponible.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAEAEA),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF731C6), // Magenta
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx); // Cierra modal de confirmación
                      final updated = widget.appointment.copyWith(
                        estado: 'Completada',
                        observaciones: _observacionesController.text.trim().isEmpty
                            ? widget.appointment.observaciones
                            : _observacionesController.text.trim(),
                      );
                      widget.onCompleted(updated);
                      // Vuelve a Mis Citas (cierra pantalla de completar servicio)
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Sí, finalizar',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mis citas',
          style: TextStyle(
            color: Colors.black,
            fontSize: 26,
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Completar servicio',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Resumen de atención',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),

              // Cliente info con icono
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFEAEAEA),
                    child: Icon(Icons.person_outline, color: Colors.black87, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Cliente: ${widget.appointment.nombreCliente}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Resumen de atención caja gris
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAEAEA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Cliente: ${widget.appointment.nombreCliente}.\nTratamiento: ${widget.appointment.nombreServicio}.\nTiempo transcurrido: 58 min (de ${widget.appointment.duracionAplicada} programados).',
                  style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),

              // Campo observaciones
              const Text(
                'Observaciones de la sesión (0/300):',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _observacionesController,
                maxLines: 4,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: 'Escriba aquí los hallazgos o notas para la siguiente cita (ej. Se detectó contractura severa en trapecio derecho, se recomienda sesión de seguimiento en 8 días)...',
                  hintStyle: const TextStyle(fontSize: 11, color: Colors.black45),
                  filled: true,
                  fillColor: const Color(0xFFEAEAEA),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Checkbox 1
              Row(
                children: [
                  Checkbox(
                    value: _tiempoYForma,
                    activeColor: const Color(0xFFF731C6),
                    onChanged: (val) => setState(() => _tiempoYForma = val ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'Servicio finalizado en tiempo y forma',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),

              // Checkbox 2
              Row(
                children: [
                  Checkbox(
                    value: _citaSeguimiento,
                    activeColor: const Color(0xFFF731C6),
                    onChanged: (val) => setState(() => _citaSeguimiento = val ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'Cliente solicita agendar cita de seguimiento',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Botón Finalizar Cita y Liberar Agenda
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF731C6), // Magenta
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _showConfirmationModal(context),
                child: const Text(
                  'Finalizar Cita y Liberar Agenda',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
