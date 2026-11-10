import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/data/services/api_client.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';

/// Vista de solo lectura de GET /api/personal/agenda.
class ReceptionAppointmentsScreen extends StatefulWidget {
  const ReceptionAppointmentsScreen({super.key});

  @override
  State<ReceptionAppointmentsScreen> createState() => _ReceptionAppointmentsScreenState();
}

class _ReceptionAppointmentsScreenState extends State<ReceptionAppointmentsScreen> {
  final ApiClient _api = ApiClient();
  List<Map<String, dynamic>> _citas = [];
  bool _cargando = true;
  String? _error;
  String _busqueda = '';
  String _filtro = 'Próximas';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  static String _fechaTexto(dynamic valor) {
    final texto = (valor ?? '').toString();
    return texto.length >= 10 ? texto.substring(0, 10) : texto;
  }

  static String _texto(dynamic valor, [String defecto = 'No disponible']) {
    final texto = valor?.toString().trim() ?? '';
    return texto.isEmpty ? defecto : texto;
  }

  Future<void> _cargar() async {
    if (!AuthSession.esRecepcionista || !AuthSession.activa) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No tienes permiso para consultar la agenda general.';
      });
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final respuesta = await _api.get('/personal/agenda');
      if (respuesta is! Map<String, dynamic> || respuesta['citas'] is! List) {
        throw ApiException(message: 'El servidor devolvió un formato inesperado.');
      }
      final citas = <Map<String, dynamic>>[];
      for (final dato in respuesta['citas'] as List) {
        if (dato is! Map) {
          throw ApiException(message: 'La agenda contiene datos inválidos.');
        }
        citas.add(Map<String, dynamic>.from(dato));
      }
      if (!mounted) return;
      setState(() {
        _citas = citas;
        _cargando = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo cargar la agenda. Revisa la conexión.';
      });
    }
  }

  List<Map<String, dynamic>> get _filtradas {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final busqueda = _busqueda.trim().toLowerCase();
    final resultado = _citas.where((cita) {
      final fecha = DateTime.tryParse(_fechaTexto(cita['fecha']));
      if (fecha == null) return false;
      if (_filtro == 'Hoy' &&
          (fecha.year != hoy.year || fecha.month != hoy.month || fecha.day != hoy.day)) {
        return false;
      }
      if (_filtro == 'Próximas' && fecha.isBefore(hoy)) return false;
      if (busqueda.isEmpty) return true;
      final campos = [
        cita['cliente'], cita['servicio'], cita['empleado'],
        cita['estado'], cita['id_cita'],
      ].join(' ').toLowerCase();
      return campos.contains(busqueda);
    }).toList();
    resultado.sort((a, b) {
      final fechaA = _fechaTexto(a['fecha']);
      final fechaB = _fechaTexto(b['fecha']);
      final orden = fechaA.compareTo(fechaB);
      if (orden != 0) return orden;
      return _texto(a['hora_inicio'], '').compareTo(_texto(b['hora_inicio'], ''));
    });
    return resultado;
  }

  Color _colorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmada': return const Color(0xFF2E7D32);
      case 'pendiente': return const Color(0xFFAC780D);
      case 'cancelada': return const Color(0xFFC03945);
      case 'completada': return const Color(0xFF7954A7);
      default: return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final citas = _filtradas;
    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          Text('Agenda general',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textDark, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          const Text('Reservaciones del SPA · Consulta de solo lectura',
              style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 14),
          TextField(
            onChanged: (valor) => setState(() => _busqueda = valor),
            decoration: const InputDecoration(
              hintText: 'Buscar cliente, servicio o especialista',
              prefixIcon: Icon(Icons.search_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['Próximas', 'Hoy', 'Todas'].map((filtro) {
              return ChoiceChip(
                label: Text(filtro),
                selected: filtro == _filtro,
                onSelected: (_) => setState(() => _filtro = filtro),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${citas.length} citas',
                  style: const TextStyle(color: AppColors.textMuted)),
              TextButton.icon(
                onPressed: _cargando ? null : _cargar,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Actualizar'),
              ),
            ],
          ),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_cargando && _error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  const Icon(Icons.wifi_off_outlined, size: 34),
                  const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: _cargar, child: const Text('Reintentar')),
                ]),
              ),
            ),
          if (!_cargando && _error == null && citas.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: Text('No hay citas que coincidan con el filtro.',
                    textAlign: TextAlign.center),
              ),
            ),
          if (!_cargando && _error == null)
            ...citas.map((cita) {
              final estado = _texto(cita['estado'], 'Pendiente');
              final hora = _texto(cita['hora_inicio'], '--:--');
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: AppColors.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(_texto(cita['servicio']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16,
                                )),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: _colorEstado(estado).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(estado,
                                style: TextStyle(color: _colorEstado(estado),
                                    fontSize: 11, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text('Cliente: ${_texto(cita['cliente'])}'),
                      Text('Especialista: ${_texto(cita['empleado'])}'),
                      Text('Fecha: ${_fechaTexto(cita['fecha'])} · Hora: ${hora.length >= 5 ? hora.substring(0, 5) : hora}'),
                      Text('Cita #${_texto(cita['id_cita'], '-')}'),
                    ],
                  ),
                ),
              );
            }),
          if (!_cargando && _error == null && _citas.length >= 500)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Se muestran hasta 500 citas. La paginación se agregará después.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
