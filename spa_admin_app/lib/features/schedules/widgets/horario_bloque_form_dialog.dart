import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/data/models/horario_semanal_model.dart';

/// Resultado de un formulario. El identificador de horario se usa internamente.
class DatosBloqueHorario {
  final int idEmpleado;
  final List<String> diasSemana;
  String get diaSemana => diasSemana.first;
  final String horaInicio;
  final String horaFin;

  const DatosBloqueHorario({
    required this.idEmpleado,
    required this.diasSemana,
    required this.horaInicio,
    required this.horaFin,
  });
}

class HorarioBloqueFormDialog extends StatefulWidget {
  final List<EmpleadoConHorarios> empleados;
  final EmpleadoConHorarios? empleadoInicial;
  final BloqueHorario? bloque;

  const HorarioBloqueFormDialog({
    super.key,
    required this.empleados,
    this.empleadoInicial,
    this.bloque,
  });

  @override
  State<HorarioBloqueFormDialog> createState() => _HorarioBloqueFormDialogState();
}

class _HorarioBloqueFormDialogState extends State<HorarioBloqueFormDialog> {
  static const Map<String, String> _dias = {
    'Lunes': 'Lunes',
    'Martes': 'Martes',
    'Miercoles': 'Miércoles',
    'Jueves': 'Jueves',
    'Viernes': 'Viernes',
    'Sabado': 'Sábado',
    'Domingo': 'Domingo',
  };

  late int _idEmpleado;
  late String _dia;
  final Set<String> _diasSeleccionados = <String>{};
  late TimeOfDay _inicio;
  late TimeOfDay _fin;
  String? _error;

  bool get _editando => widget.bloque != null;

  @override
  void initState() {
    super.initState();
    _idEmpleado = widget.empleadoInicial?.idEmpleado ??
        widget.empleados.first.idEmpleado;
    _dia = _normalizarDia(widget.bloque?.diaSemana ?? 'Lunes');
    _inicio = _parsearHora(widget.bloque?.horaInicio, const TimeOfDay(hour: 9, minute: 0));
    _fin = _parsearHora(widget.bloque?.horaFin, const TimeOfDay(hour: 17, minute: 0));
  }

  static String _normalizarDia(String dia) => switch (dia.toLowerCase()) {
    'miércoles' => 'Miercoles',
    'sábado' => 'Sabado',
    _ => dia,
  };

  static TimeOfDay _parsearHora(String? valor, TimeOfDay alternativa) {
    final partes = (valor ?? '').split(':');
    if (partes.length < 2) return alternativa;
    final hora = int.tryParse(partes[0]);
    final minuto = int.tryParse(partes[1]);
    if (hora == null || hora < 0 || hora > 23 || minuto == null || minuto < 0 || minuto > 59) {
      return alternativa;
    }
    return TimeOfDay(hour: hora, minute: minuto);
  }

  static String _formato24(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _elegirHora({required bool entrada}) async {
    final seleccion = await showTimePicker(
      context: context,
      initialTime: entrada ? _inicio : _fin,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (seleccion == null || !mounted) return;
    setState(() {
      if (entrada) { _inicio = seleccion; } else { _fin = seleccion; }
      _error = null;
    });
  }

  void _guardar() {
    final inicio = _inicio.hour * 60 + _inicio.minute;
    final fin = _fin.hour * 60 + _fin.minute;
    if (inicio >= fin) {
      setState(() => _error = 'La salida debe ser posterior a la entrada.');
      return;
    }
    if (!_editando && _diasSeleccionados.isEmpty) {
      setState(() => _error = 'Selecciona al menos un día laboral.');
      return;
    }
    final dias = _editando
        ? <String>[_dia]
        : _dias.keys.where(_diasSeleccionados.contains).toList();
    Navigator.of(context).pop(DatosBloqueHorario(
      idEmpleado: _idEmpleado,
      diasSemana: dias,
      horaInicio: _formato24(_inicio),
      horaFin: _formato24(_fin),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(_editando ? 'Editar horario' : 'Nuevo horario',
        style: const TextStyle(fontWeight: FontWeight.w800,
          color: AppColors.textDark, fontSize: 19)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('Empleado', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 7),
          DropdownButtonFormField<int>(
            value: _idEmpleado,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: widget.empleados.map((e) => DropdownMenuItem<int>(
              value: e.idEmpleado,
              child: Text(e.nombre, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: _editando || widget.empleadoInicial != null
                ? null : (id) { if (id != null) setState(() => _idEmpleado = id); },
          ),
          const SizedBox(height: 14),
          Text(_editando ? 'Día de la semana' : 'Días laborales',
            style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 7),
          if (_editando)
            DropdownButtonFormField<String>(
              value: _dia,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _dias.entries.map((e) => DropdownMenuItem<String>(
                value: e.key, child: Text(e.value),
              )).toList(),
              onChanged: (dia) { if (dia != null) setState(() => _dia = dia); },
            )
          else ...[
            const Text('Puedes seleccionar varios días con el mismo turno.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 9),
            Wrap(
              spacing: 6,
              runSpacing: 3,
              children: _dias.entries.map((entrada) {
                final elegido = _diasSeleccionados.contains(entrada.key);
                return FilterChip(
                  label: Text(entrada.value,
                    style: const TextStyle(fontSize: 12)),
                  selected: elegido,
                  selectedColor: AppColors.primaryPinkSoft,
                  checkmarkColor: AppColors.primaryPink,
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                  onSelected: (seleccionar) => setState(() {
                    if (seleccionar) {
                      _diasSeleccionados.add(entrada.key);
                    } else {
                      _diasSeleccionados.remove(entrada.key);
                    }
                    _error = null;
                  }),
                );
              }).toList(),
            ),
            Row(children: [
              TextButton(
                onPressed: () => setState(() {
                  _diasSeleccionados
                    ..clear()
                    ..addAll(['Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes']);
                  _error = null;
                }),
                child: const Text('Lunes a viernes'),
              ),
              TextButton(
                onPressed: _diasSeleccionados.isEmpty ? null : () => setState(() {
                  _diasSeleccionados.clear();
                  _error = null;
                }),
                child: const Text('Limpiar'),
              ),
            ]),
            AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              child: Text(
                '${_diasSeleccionados.length} ${_diasSeleccionados.length == 1 ? 'día seleccionado' : 'días seleccionados'}',
                key: ValueKey(_diasSeleccionados.length),
                style: const TextStyle(color: AppColors.primaryPink, fontSize: 12,
                  fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Text('Turno', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 7),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _elegirHora(entrada: true),
              icon: const Icon(Icons.login, size: 16),
              label: Text(_formato24(_inicio)),
            )),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('a')),
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _elegirHora(entrada: false),
              icon: const Icon(Icons.logout, size: 16),
              label: Text(_formato24(_fin)),
            )),
          ]),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          const SizedBox(height: 10),
          Text(_editando
              ? 'Los cambios no deben afectar las citas que ya están reservadas.'
              : 'Si algún día se cruza con otro turno, no se guardará ninguno.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primaryPink),
          onPressed: _guardar,
          child: Text(_editando ? 'Guardar cambios' : 'Guardar horario'),
        ),
      ],
    );
  }
}
