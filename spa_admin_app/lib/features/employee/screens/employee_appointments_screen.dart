import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/data/services/api_config.dart';
import 'package:spa_admin_app/data/services/sesion_service.dart';

/// Consulta GET /api/citas. Vanessa filtra por id_usuario e id_rol=2 del JWT.
/// No reutiliza las citas simuladas de MisCitasScreen (que se conserva sin cambios).
class EmployeeAppointmentsScreen extends StatefulWidget {
  const EmployeeAppointmentsScreen({super.key});

  @override
  State<EmployeeAppointmentsScreen> createState() => _EmployeeAppointmentsScreenState();
}

class _EmployeeAppointmentsScreenState extends State<EmployeeAppointmentsScreen> {
  List<Map<String, dynamic>> _citas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  Future<void> _cargarCitas() async {
    final token = AuthSession.token;
    if (token == null || token.isEmpty) {
      if (mounted) setState(() {
        _cargando = false;
        _error = 'Inicia sesión para consultar tu agenda.';
      });
      return;
    }
    if (mounted) setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final respuesta = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/citas'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConfig.connectionTimeout);
      if (respuesta.statusCode == 401) {
        throw Exception('La sesión expiró. Cierra sesión y vuelve a ingresar.');
      }
      if (respuesta.statusCode != 200) {
        throw Exception('No fue posible consultar las citas (${respuesta.statusCode}).');
      }
      final datos = jsonDecode(respuesta.body);
      if (datos is! Map<String, dynamic> || datos['citas'] is! List) {
        throw const FormatException('La respuesta de citas es inesperada.');
      }
      final lista = (datos['citas'] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (mounted) setState(() => _citas = lista);
    } on TimeoutException {
      if (mounted) setState(() => _error = 'La carga está tardando más de lo esperado. Intenta nuevamente.');
    } on SocketException {
      if (mounted) setState(() => _error = 'No se pudo cargar la agenda. Comprueba tu conexión.');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _cargarCitas,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Text('Mis citas', style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textDark, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Solo las citas que te asignaron.',
              style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 18),
          if (_cargando)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_cargando && _error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(children: [
                  const Icon(Icons.wifi_off_outlined, size: 34),
                  const SizedBox(height: 8),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  TextButton(onPressed: _cargarCitas, child: const Text('Reintentar')),
                ]),
              ),
            ),
          if (!_cargando && _error == null && _citas.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No tienes citas asignadas todavía.',
                    textAlign: TextAlign.center),
              ),
            ),
          if (!_cargando && _error == null)
            ..._citas.map((cita) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${cita['servicio'] ?? 'Servicio'}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Cliente: ${cita['cliente'] ?? '—'}'),
                    Text('Fecha: ${('${cita['fecha'] ?? '—'}').split('T').first}'),
                    Text('Hora: ${cita['hora_inicio'] ?? '—'}'),
                    Text('Estado: ${cita['estado'] ?? '—'}'),
                  ],
                ),
              ),
            )),
        ],
      ),
    );
  }
}
