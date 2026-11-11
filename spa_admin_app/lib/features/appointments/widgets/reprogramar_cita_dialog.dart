import 'package:flutter/material.dart';
import 'package:spa_admin_app/data/services/api_client.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';

/// Resultado del cambio de fecha, hora o especialista (misma cita).
class ReprogramacionResultado {
  final DateTime fecha;
  final String hora;
  final String especialista;
  final String estado;

  const ReprogramacionResultado({
    required this.fecha,
    required this.hora,
    required this.especialista,
    required this.estado,
  });
}

/// Dialogo compartido por Administrador y Recepcion.
/// Solo consulta /api/personal; la app Cliente no se modifica.
class ReprogramarCitaDialog extends StatefulWidget {
  final int idCita;

  const ReprogramarCitaDialog({super.key, required this.idCita});

  @override
  State<ReprogramarCitaDialog> createState() => _ReprogramarCitaDialogState();
}

class _ReprogramarCitaDialogState extends State<ReprogramarCitaDialog> {
  final ApiClient _api = ApiClient();
  Map<String, dynamic>? _cita;
  List<Map<String, dynamic>> _especialistas = [];
  List<String> _horas = [];
  DateTime? _fecha;
  int? _idEmpleado;
  String? _horaElegida;
  bool _cargando = true;
  bool _cargandoHoras = false;
  bool _guardando = false;
  String? _error;
  String? _errorHoras;
  int _versionConsulta = 0;

  String get _base => '/personal/citas-manuales/${widget.idCita}';

  static int? _entero(dynamic dato) {
    final v = int.tryParse('$dato');
    return v != null && v > 0 ? v : null;
  }

  static String _fechaSQL(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

  static String _hora5(dynamic valor) {
    final texto = '$valor';
    return texto.length >= 5 ? texto.substring(0, 5) : texto;
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final respuesta = await _api.get('$_base/reprogramacion');
      if (respuesta is! Map || respuesta['cita'] is! Map || respuesta['especialistas'] is! List) {
        throw ApiException(message: 'El servidor devolvió datos incompletos.');
      }
      final cita = Map<String, dynamic>.from(respuesta['cita'] as Map);
      final especialistas = <Map<String, dynamic>>[];
      for (final elemento in respuesta['especialistas'] as List) {
        if (elemento is Map) especialistas.add(Map<String, dynamic>.from(elemento));
      }
      final textoFecha = '${cita['fecha']}';
      final fecha = DateTime.tryParse(textoFecha.length >= 10 ? textoFecha.substring(0, 10) : textoFecha);
      if (fecha == null) throw ApiException(message: 'La cita no tiene una fecha válida.');
      if (!mounted) return;
      setState(() {
        _cita = cita;
        _especialistas = especialistas;
        _fecha = fecha;
        _idEmpleado = _entero(cita['id_empleado']);
        _cargando = false;
      });
      await _consultarHoras();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _cargando = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo consultar la cita. Revisa la conexión.';
        _cargando = false;
      });
    }
  }

  Future<void> _consultarHoras() async {
    final empleado = _idEmpleado;
    final fecha = _fecha;
    final version = ++_versionConsulta;
    if (empleado == null || fecha == null) {
      if (mounted) setState(() { _horas = []; _horaElegida = null; });
      return;
    }
    setState(() {
      _cargandoHoras = true;
      _horaElegida = null;
      _errorHoras = null;
      _horas = [];
    });
    try {
      final respuesta = await _api.get(
        '$_base/reprogramacion/disponibilidad?id_empleado=$empleado&fecha=${_fechaSQL(fecha)}',
      );
      if (respuesta is! Map || respuesta['horas'] is! List) {
        throw ApiException(message: 'No se pudo interpretar la disponibilidad.');
      }
      final horas = (respuesta['horas'] as List).map((valor) => '$valor').toList();
      if (!mounted || version != _versionConsulta) return;
      setState(() {
        _horas = horas;
        _cargandoHoras = false;
        _errorHoras = (respuesta['razon'] ?? '').toString().trim();
      });
    } on ApiException catch (e) {
      if (!mounted || version != _versionConsulta) return;
      setState(() { _errorHoras = e.message; _cargandoHoras = false; });
    } catch (_) {
      if (!mounted || version != _versionConsulta) return;
      setState(() {
        _errorHoras = 'No fue posible consultar los horarios disponibles.';
        _cargandoHoras = false;
      });
    }
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = inicio.add(const Duration(days: 365));
    final actual = _fecha ?? inicio;
    final inicial = actual.isBefore(inicio) ? inicio : (actual.isAfter(fin) ? fin : actual);
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: inicio,
      lastDate: fin,
      helpText: 'Fecha nueva de la cita',
      cancelText: 'Cancelar',
      confirmText: 'Elegir fecha',
    );
    if (!mounted || seleccionada == null) return;
    setState(() => _fecha = seleccionada);
    await _consultarHoras();
  }

  bool get _sinCambios {
    if (_cita == null || _fecha == null || _idEmpleado == null || _horaElegida == null) return true;
    return _entero(_cita!['id_empleado']) == _idEmpleado &&
        '${_cita!['fecha']}'.substring(0, 10) == _fechaSQL(_fecha!) &&
        _hora5(_cita!['hora_inicio']) == _horaElegida;
  }

  Future<void> _guardar() async {
    if (_guardando || _cargandoHoras || _sinCambios || _fecha == null ||
        _horaElegida == null || _idEmpleado == null) return;
    setState(() { _guardando = true; _error = null; });
    try {
      final respuesta = await _api.patch('$_base/reprogramar', body: {
        'id_empleado': _idEmpleado,
        'fecha': _fechaSQL(_fecha!),
        'hora_inicio': _horaElegida,
      });
      if (respuesta is! Map || respuesta['cita'] is! Map) {
        throw ApiException(message: 'El servidor no confirmó el cambio.');
      }
      if (!mounted) return;
      final elegido = _especialistas.firstWhere(
        (e) => _entero(e['id_empleado']) == _idEmpleado,
        orElse: () => {'nombre': 'Especialista'},
      );
      Navigator.of(context).pop(ReprogramacionResultado(
        fecha: _fecha!,
        hora: _horaElegida!,
        especialista: '${elegido['nombre']}',
        estado: '${(respuesta['cita'] as Map)['estado'] ?? 'Pendiente'}',
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _guardando = false; _error = e.message; });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = 'No se pudo guardar el cambio. Intenta nuevamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final actual = _cita;
    return AlertDialog(
      title: const Row(children: [
        Icon(Icons.event_repeat_outlined),
        SizedBox(width: 8),
        Expanded(child: Text('Reprogramar cita')),
      ]),
      content: SizedBox(
        width: 450,
        child: _cargando
            ? const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()))
            : _error != null && actual == null
                ? Text(_error!, style: const TextStyle(color: Color(0xFFB53942)))
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cliente: ${actual?['cliente'] ?? 'Sin nombre'}',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Servicio: ${actual?['servicio'] ?? 'Sin nombre'}'),
                        const SizedBox(height: 4),
                        Text('Actual: ${actual?['fecha'] ?? ''} a las ${_hora5(actual?['hora_inicio'])}'),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int>(
                          initialValue: _especialistas.any((e) => _entero(e['id_empleado']) == _idEmpleado)
                              ? _idEmpleado : null,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Especialista',
                              border: OutlineInputBorder()),
                          items: _especialistas.map((e) => DropdownMenuItem<int>(
                            value: _entero(e['id_empleado']),
                            child: Text('${e['nombre'] ?? 'Especialista'}', overflow: TextOverflow.ellipsis),
                          )).toList(),
                          onChanged: _guardando ? null : (id) async {
                            setState(() => _idEmpleado = id);
                            await _consultarHoras();
                          },
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _guardando ? null : _elegirFecha,
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: Text(_fecha == null ? 'Elegir fecha' : 'Fecha: ${_fechaSQL(_fecha!)}'),
                        ),
                        const SizedBox(height: 12),
                        const Text('Horarios libres', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 7),
                        if (_cargandoHoras) const Center(child: Padding(
                          padding: EdgeInsets.all(12), child: CircularProgressIndicator(),
                        )),
                        if (!_cargandoHoras && _horas.isEmpty)
                          Text((_errorHoras?.isNotEmpty ?? false)
                              ? _errorHoras! : 'No hay horarios libres para esa fecha.'),
                        if (!_cargandoHoras && _horas.isNotEmpty)
                          Wrap(spacing: 7, runSpacing: 7,
                            children: _horas.map((h) => ChoiceChip(
                              label: Text(h),
                              selected: _horaElegida == h,
                              onSelected: _guardando ? null : (_) => setState(() => _horaElegida = h),
                            )).toList(),
                          ),
                        const SizedBox(height: 12),
                        const Text('Después de reprogramar, la cita quedará Pendiente hasta que el personal la confirme.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF855B10))),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(_error!, style: const TextStyle(color: Color(0xFFB53942))),
                        ],
                      ],
                    ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Volver'),
        ),
        FilledButton.icon(
          onPressed: _guardando || _cargando || _cargandoHoras || _sinCambios ? null : _guardar,
          icon: _guardando
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined),
          label: Text(_guardando ? 'Guardando...' : 'Guardar cambio'),
        ),
      ],
    );
  }
}
