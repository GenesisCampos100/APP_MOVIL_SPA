import 'package:flutter/material.dart';
import 'package:spa_admin_app/features/appointments/widgets/cita_visual_components.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/preferences/staff_preferences.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';
import 'package:spa_admin_app/data/services/api_client.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';

/// Citas manuales: cliente con cuenta o nuevo cliente atendido sin acceso.
/// El backend valida permisos y disponibilidad antes de guardar.
class ManualAppointmentDialog extends StatefulWidget {
  const ManualAppointmentDialog({super.key});

  @override
  State<ManualAppointmentDialog> createState() => _ManualAppointmentDialogState();
}

enum _TipoClienteManual { registrado, sinCuenta }

class _ManualAppointmentDialogState extends State<ManualAppointmentDialog> {
  String t(String es, String en) => AuthSession.esEmpleado
      ? StaffPreferences.tr(es, en) : es;

  final ApiClient _api = ApiClient();
  final TextEditingController _busqueda = TextEditingController();
  final TextEditingController _observaciones = TextEditingController();
  final TextEditingController _nombreNuevo = TextEditingController();
  final TextEditingController _apellidoPaternoNuevo = TextEditingController();
  final TextEditingController _apellidoMaternoNuevo = TextEditingController();
  final TextEditingController _telefonoNuevo = TextEditingController();
  _TipoClienteManual _tipoCliente = _TipoClienteManual.registrado;
  List<Map<String, dynamic>> _clientes = [];
  List<Map<String, dynamic>> _servicios = [];
  List<Map<String, dynamic>> _especialistas = [];
  List<String> _horas = [];
  int? _idCliente;
  int? _idServicio;
  int? _idEmpleado;
  String? _hora;
  DateTime _fecha = DateTime.now();
  bool _cargando = true;
  bool _buscando = false;
  bool _cargandoHoras = false;
  bool _guardando = false;
  String? _error;
  String? _errorHoras;
  int _versionHorarios = 0;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    _observaciones.dispose();
    _nombreNuevo.dispose();
    _apellidoPaternoNuevo.dispose();
    _apellidoMaternoNuevo.dispose();
    _telefonoNuevo.dispose();
    super.dispose();
  }

  int? _id(dynamic valor) => int.tryParse('${valor ?? ''}');
  String _texto(dynamic valor) => (valor ?? '').toString();
  String _fechaIso(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> _leerLista(dynamic respuesta, String campo) {
    if (respuesta is! Map || respuesta[campo] is! List) {
      throw ApiException(message: 'El servidor devolvió datos incompletos.');
    }
    return (respuesta[campo] as List)
        .whereType<Map>()
        .map((dato) => Map<String, dynamic>.from(dato))
        .toList();
  }

  Future<void> _cargarCatalogo() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final datos = await _api.get('/personal/citas-manuales/catalogo');
      final clientes = await _api.get('/personal/citas-manuales/clientes');
      if (!mounted) return;
      setState(() {
        _servicios = _leerLista(datos, 'servicios');
        _especialistas = _leerLista(datos, 'especialistas');
        _clientes = _leerLista(clientes, 'clientes');
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e is ApiException ? e.message : t('No fue posible cargar los datos.', 'Unable to load data.');
      });
    }
  }

  Future<void> _buscarClientes() async {
    if (_guardando || _buscando) return;
    setState(() { _buscando = true; _error = null; });
    try {
      final q = Uri.encodeQueryComponent(_busqueda.text.trim());
      final respuesta = await _api.get('/personal/citas-manuales/clientes?q=$q');
      if (!mounted) return;
      setState(() {
        _clientes = _leerLista(respuesta, 'clientes');
        if (!_clientes.any((c) => _id(c['id_cliente']) == _idCliente)) {
          _idCliente = null;
        }
        _buscando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _buscando = false;
        _error = e is ApiException ? e.message : t('No se pudieron buscar los clientes.', 'Unable to search for clients.');
      });
    }
  }

  List<Map<String, dynamic>> get _especialistasFiltrados {
    if (_idServicio == null) return [];
    final ids = <int>{};
    return _especialistas.where((e) {
      final id = _id(e['id_empleado']);
      return _id(e['id_servicio']) == _idServicio && id != null && ids.add(id);
    }).toList();
  }

  void _limpiarHoras() {
    _versionHorarios++;
    _horas = [];
    _hora = null;
    _errorHoras = null;
    _cargandoHoras = false;
  }

  Future<void> _cargarHoras() async {
    final servicio = _idServicio;
    final empleado = _idEmpleado;
    if (servicio == null || empleado == null) return;
    final version = ++_versionHorarios;
    setState(() {
      _cargandoHoras = true;
      _horas = [];
      _hora = null;
      _errorHoras = null;
    });
    try {
      final fecha = _fechaIso(_fecha);
      final respuesta = await _api.get(
        '/personal/citas-manuales/disponibilidad?id_servicio=$servicio&id_empleado=$empleado&fecha=$fecha',
      );
      if (!mounted || version != _versionHorarios) return;
      if (respuesta is! Map || respuesta['horas'] is! List) {
        throw ApiException(message: 'No se pudieron interpretar los horarios disponibles.');
      }
      setState(() {
        _horas = (respuesta['horas'] as List).map((e) => e.toString()).toList();
        _cargandoHoras = false;
      });
    } catch (e) {
      if (!mounted || version != _versionHorarios) return;
      setState(() {
        _cargandoHoras = false;
        _errorHoras = e is ApiException ? e.message : t('No se pudo consultar la disponibilidad.', 'Unable to check availability.');
      });
    }
  }

  void _seleccionarDia(DateTime fecha) {
    if (_guardando || _fechaIso(fecha) == _fechaIso(_fecha)) return;
    setState(() { _fecha = fecha; _limpiarHoras(); });
    _cargarHoras();
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final minimo = DateTime(hoy.year, hoy.month, hoy.day);
    final seleccion = await abrirCalendarioCita(
      context,
      fechaActual: _fecha,
      fechaMinima: minimo,
      fechaMaxima: DateTime(hoy.year + 1, hoy.month, hoy.day),
    );
    if (seleccion == null || !mounted) return;
    _seleccionarDia(seleccion);
  }

  Future<void> _guardar() async {
    final esNuevo = _tipoCliente == _TipoClienteManual.sinCuenta;
    if (_idServicio == null || _idEmpleado == null || _hora == null ||
        (!esNuevo && _idCliente == null)) {
      setState(() => _error = t('Selecciona el cliente, servicio, especialista y un horario disponible.', 'Choose a client, service, specialist and available time.'));
      return;
    }
    if (esNuevo && (_nombreNuevo.text.trim().isEmpty ||
        _apellidoPaternoNuevo.text.trim().isEmpty ||
        !RegExp(r'^\d{10}$').hasMatch(_telefonoNuevo.text.trim()))) {
      setState(() => _error = t('Escribe nombre, apellido paterno y teléfono de 10 dígitos.', 'Enter a first name, last name and 10-digit phone number.'));
      return;
    }
    setState(() { _guardando = true; _error = null; });
    try {
      final body = <String, dynamic>{
        'id_servicio': _idServicio,
        'id_empleado': _idEmpleado,
        'fecha': _fechaIso(_fecha),
        'hora_inicio': _hora,
        'observaciones': _observaciones.text.trim(),
      };
      if (esNuevo) {
        body['cliente'] = {
          'nombre': _nombreNuevo.text.trim(),
          'apellido_p': _apellidoPaternoNuevo.text.trim(),
          'apellido_m': _apellidoMaternoNuevo.text.trim(),
          'telefono': _telefonoNuevo.text.trim(),
        };
      } else {
        body['id_cliente'] = _idCliente;
      }
      await _api.post(
        esNuevo ? '/personal/citas-manuales/sin-cuenta' : '/personal/citas-manuales',
        body: body,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e is ApiException ? e.message : t('No fue posible guardar la cita.', 'Unable to save the appointment.');
      });
      // Ante un conflicto de disponibilidad, refrescar los horarios.
      if (e is ApiException && e.statusCode == 409) await _cargarHoras();
    }
  }

  @override
  Widget build(BuildContext context) {
    final disponibles = _especialistasFiltrados;
    final servicio = _servicios.where((s) => _id(s['id_servicio']) == _idServicio).toList();
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: dark ? scheme.surface : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 760),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.event_available_outlined, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t('Nueva cita', 'New appointment'),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
                Text(t('Estado inicial: Pendiente', 'Initial status: Pending'),
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ])),
              IconButton(onPressed: _guardando ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded), tooltip: t('Cerrar', 'Close')),
            ]),
          ),
          const Divider(height: 1),
          Flexible(child: _cargando
              ? const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
                        child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer)),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (_servicios.isEmpty) ...[
                      Text(t('No hay servicios disponibles para crear citas.', 'No services available for appointments.')),
                      TextButton(onPressed: _cargarCatalogo, child: Text(t('Reintentar', 'Retry'))),
                    ] else ...[
                      _subtitulo(t('1. Datos del cliente', '1. Client details')),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        ChoiceChip(
                          label: Text(t('Cliente existente', 'Existing client')),
                          selected: _tipoCliente == _TipoClienteManual.registrado,
                          onSelected: _guardando ? null : (_) => setState(() {
                            _tipoCliente = _TipoClienteManual.registrado;
                            _error = null;
                          }),
                        ),
                        ChoiceChip(
                          label: Text(t('Nuevo sin cuenta', 'New without account')),
                          selected: _tipoCliente == _TipoClienteManual.sinCuenta,
                          onSelected: _guardando ? null : (_) => setState(() {
                            _tipoCliente = _TipoClienteManual.sinCuenta;
                            _error = null;
                          }),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      if (_tipoCliente == _TipoClienteManual.registrado) ...[
                      Row(children: [
                        Expanded(child: TextField(
                          controller: _busqueda,
                          enabled: !_guardando,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _buscarClientes(),
                          decoration: InputDecoration(
                            hintText: t('Buscar nombre, teléfono o correo', 'Search name, phone or email'),
                            prefixIcon: Icon(Icons.search_rounded),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        )),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: t('Buscar clientes', 'Search clients'),
                          onPressed: _buscando || _guardando ? null : _buscarClientes,
                          icon: _buscando ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search_rounded),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        key: ValueKey('clientes-${_clientes.length}-${_idCliente ?? 0}'),
                        initialValue: _idCliente,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: t('Seleccionar cliente', 'Select client'), border: const OutlineInputBorder()),
                        items: _clientes.map((cliente) => DropdownMenuItem<int>(
                          value: _id(cliente['id_cliente']),
                          child: Text('${_texto(cliente['nombre'])} · ${cliente['sin_cuenta'] == true ? t('Sin cuenta', 'No account') : _texto(cliente['correo'])}',
                              overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: _guardando ? null : (valor) => setState(() => _idCliente = valor),
                      ),
                      if (_clientes.isEmpty) Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(t('No se encontraron clientes. Busca otro nombre o teléfono.',
                            'No clients found. Try another name or phone.'),
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      ),
                      ] else ...[
                        Text(
                          t('Se guardará un perfil de atención sin acceso a la app ni correos. La cita quedará Pendiente hasta que Administración o Recepción la confirme.',
                            'A client record will be created without app access or emails. The appointment stays Pending until staff accept it.'),
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nombreNuevo,
                          maxLength: 80,
                          textCapitalization: TextCapitalization.words,
                          enabled: !_guardando,
                          decoration: InputDecoration(
                            labelText: t('Nombre *', 'First name *'), border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _apellidoPaternoNuevo,
                          maxLength: 80,
                          textCapitalization: TextCapitalization.words,
                          enabled: !_guardando,
                          decoration: InputDecoration(
                            labelText: t('Apellido paterno *', 'Last name *'), border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _apellidoMaternoNuevo,
                          maxLength: 80,
                          textCapitalization: TextCapitalization.words,
                          enabled: !_guardando,
                          decoration: InputDecoration(
                            labelText: t('Apellido materno (opcional)', 'Second last name (optional)'), border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _telefonoNuevo,
                          maxLength: 10,
                          keyboardType: TextInputType.phone,
                          enabled: !_guardando,
                          decoration: InputDecoration(
                            labelText: t('Teléfono de 10 dígitos *', '10-digit phone *'), border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _subtitulo(t('2. Servicio y especialista', '2. Service and specialist')),
                      DropdownButtonFormField<int>(
                        initialValue: _idServicio,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: t('Servicio', 'Service'), border: const OutlineInputBorder()),
                        items: _servicios.map((s) => DropdownMenuItem<int>(
                          value: _id(s['id_servicio']),
                          child: Text(_texto(s['nombre']), overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: _guardando ? null : (valor) => setState(() {
                          _idServicio = valor;
                          _idEmpleado = null;
                          _limpiarHoras();
                        }),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        key: ValueKey('empleado-${_idServicio ?? 0}'),
                        initialValue: _idEmpleado,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: t('Especialista', 'Specialist'), border: const OutlineInputBorder()),
                        items: disponibles.map((e) => DropdownMenuItem<int>(
                          value: _id(e['id_empleado']),
                          child: Text(_texto(e['nombre']), overflow: TextOverflow.ellipsis),
                        )).toList(),
                        onChanged: _guardando ? null : (valor) {
                          setState(() { _idEmpleado = valor; _limpiarHoras(); });
                          _cargarHoras();
                        },
                      ),
                      if (_idServicio != null && disponibles.isEmpty)
                        Padding(padding: const EdgeInsets.only(top: 8), child: Text(
                          t('Este servicio todavía no tiene especialistas asignados.',
                            'There are no specialists assigned to this service yet.'),
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12))),
                      if (servicio.isNotEmpty) Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('${_texto(servicio.first['duracion'])} min · \$${_texto(servicio.first['precio'])}',
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                      ),
                      const SizedBox(height: 18),
                      _subtitulo(t('3. Fecha y horario disponible', '3. Date and available times')),
                      SelectorFechaCita(
                        fecha: _fecha,
                        fechaMinima: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                        fechaMaxima: DateTime(DateTime.now().year + 1, DateTime.now().month, DateTime.now().day),
                        onSeleccionar: _seleccionarDia,
                        onAbrirCalendario: _elegirFecha,
                        habilitado: !_guardando,
                      ),
                      const SizedBox(height: 12),
                      SelectorHorariosCita(
                        horas: _horas,
                        seleccion: _hora,
                        cargando: _cargandoHoras,
                        habilitado: !_guardando,
                        error: _errorHoras,
                        mensajeVacio: _idEmpleado == null
                            ? t('Primero selecciona el servicio y el especialista.', 'Choose a service and specialist first.')
                            : t('No hay horarios disponibles para esta fecha. Prueba otro día.', 'No times available for this date. Try another day.'),
                        onSeleccionar: (hora) => setState(() => _hora = hora),
                        onReintentar: _idEmpleado == null ? null : _cargarHoras,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _observaciones,
                        maxLength: 500,
                        maxLines: 2,
                        enabled: !_guardando,
                        decoration: InputDecoration(
                          labelText: t('Observaciones (opcional)', 'Notes (optional)'),
                          hintText: t('Indicaciones para la cita', 'Appointment instructions'),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ]),
                )),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            child: Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: _guardando ? null : () => Navigator.pop(context),
                child: Text(t('Cancelar', 'Cancel')),
              )),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary),
                onPressed: _cargando || _guardando || _cargandoHoras || _hora == null ? null : _guardar,
                icon: _guardando ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: scheme.onPrimary,
                    strokeWidth: 2,
                  ),
                ) : const Icon(Icons.check_rounded),
                label: Text(t('Crear cita', 'Create appointment')),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _subtitulo(String texto) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
  );
}
