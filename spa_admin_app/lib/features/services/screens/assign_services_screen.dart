import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import 'package:spa_admin_app/data/models/employee_model.dart';
import 'package:spa_admin_app/data/models/service_model.dart';
import 'package:spa_admin_app/data/repositories/asignaciones_repository.dart';
import 'package:spa_admin_app/data/repositories/empleados_repository.dart';
import 'package:spa_admin_app/data/repositories/servicios_repository.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/features/services/widgets/assign_services_panel_dialog.dart';

/// Gestiona asignaciones reales, sin modificar las rutas de la app Cliente.
class AssignServicesScreen extends StatefulWidget {
  /// Abre automáticamente la asignación del especialista recién registrado.
  /// El correo solo sirve para localizarlo en la lista; no se envía a otra API.
  final String? correoEmpleadoInicial;

  const AssignServicesScreen({super.key, this.correoEmpleadoInicial});

  @override
  State<AssignServicesScreen> createState() => _AssignServicesScreenState();
}

class _AssignServicesScreenState extends State<AssignServicesScreen> {
  final _empleadosRepo = EmpleadosRepository();
  final _serviciosRepo = ServiciosRepository();
  final _asignacionesRepo = AsignacionesRepository();

  List<EmployeeModel> _empleados = [];
  List<ServiceModel> _servicios = [];
  Map<String, Set<String>> _asignaciones = {};
  String _busqueda = '';
  bool _cargando = true;
  bool _guardando = false;
  String? _error;
  bool _intentoAbrirEmpleadoInicial = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final empleados = await _empleadosRepo.obtenerEmpleados();
      final servicios = await _serviciosRepo.obtenerTodosServiciosAdmin();
      final asignaciones = await _asignacionesRepo.obtenerAsignaciones();
      if (!mounted) return;
      setState(() {
        _empleados = empleados.where((e) => e.idPuesto != '5').toList();
        _servicios = servicios;
        _asignaciones = asignaciones;
      });

      // Una sola autoapertura, después de cargar empleados y asignaciones reales.
      final correo = widget.correoEmpleadoInicial?.trim().toLowerCase();
      if (!_intentoAbrirEmpleadoInicial &&
          correo != null &&
          correo.isNotEmpty) {
        _intentoAbrirEmpleadoInicial = true;
        EmployeeModel? nuevo;
        for (final item in _empleados) {
          if (item.correo.trim().toLowerCase() == correo) {
            nuevo = item;
            break;
          }
        }
        final empleadoEncontrado = nuevo;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (empleadoEncontrado != null && empleadoEncontrado.estado) {
            _editar(empleadoEncontrado);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No fue posible abrir automáticamente al especialista. '
                  'Puedes buscarlo y asignarle servicios desde esta pantalla.',
                ),
              ),
            );
          }
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudieron consultar los servicios asignados.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar(EmployeeModel empleado, Set<String> seleccion) async {
    if (_guardando) throw StateError('Ya se están guardando cambios.');
    if (!mounted) return;
    setState(() => _guardando = true);
    try {
      await _asignacionesRepo.guardarAsignaciones(empleado.idEmpleado, seleccion);
      if (!mounted) return;
      setState(() => _asignaciones[empleado.idEmpleado] = Set.of(seleccion));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF356A57),
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Servicios asignados correctamente.')),
              ],
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _editar(EmployeeModel empleado) async {
    if (_guardando || !empleado.estado) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AssignServicesPanelDialog(
        employee: empleado,
        allServices: _servicios,
        initiallyAssignedServiceIds: Set.of(
          _asignaciones[empleado.idEmpleado] ?? <String>{},
        ),
        onSave: (ids) => _guardar(empleado, ids),
      ),
    );
  }

  Future<void> _verResumen(EmployeeModel empleado) async {
    final asignados = _asignaciones[empleado.idEmpleado] ?? <String>{};
    final servicios = _servicios
        .where((s) => asignados.contains(s.idServicio))
        .toList();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Servicios de ${empleado.nombreCompleto}',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textDark),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: servicios.isEmpty
              ? const Text('Este especialista todavía no tiene servicios asignados.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: servicios.length,
                  separatorBuilder: (_, _) => const Divider(height: 12),
                  itemBuilder: (_, index) {
                    final servicio = servicios[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Icon(
                        Icons.check_circle_outline_rounded,
                        color: servicio.estado
                            ? AppColors.primaryPink
                            : AppColors.textMuted,
                      ),
                      title: Text(servicio.nombre),
                      subtitle: servicio.estado
                          ? null
                          : const Text('Servicio inactivo'),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cerrar'),
          ),
          if (empleado.estado)
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _editar(empleado);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
              ),
              child: const Text('Editar servicios'),
            ),
        ],
      ),
    );
  }

  Widget _resumen(String numero, String etiqueta, IconData icono) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, size: 18, color: AppColors.primaryPink),
                const Spacer(),
                Text(
                  numero,
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              etiqueta,
              maxLines: 2,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjeta(EmployeeModel empleado) {
    final asignados = _asignaciones[empleado.idEmpleado] ?? <String>{};
    final nombres = _servicios
        .where((s) => asignados.contains(s.idServicio))
        .map((s) => s.nombre)
        .toList();
    final nombre = empleado.nombreCompleto.trim();
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'E';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withValues(alpha: 0.045),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.primaryPinkSoft,
                child: Text(
                  inicial,
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.primaryPink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      empleado.nombreCompleto,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      empleado.puesto,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: empleado.estado
                      ? const Color(0xFFE8F4ED)
                      : const Color(0xFFF4EBEB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  empleado.estado ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: empleado.estado
                        ? const Color(0xFF347652)
                        : const Color(0xFFA55D5D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.cardBorder.withValues(alpha: 0.8), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.spa_outlined,
                color: AppColors.primaryPink,
                size: 17,
              ),
              const SizedBox(width: 7),
              Text(
                '${asignados.length} ${asignados.length == 1 ? 'servicio asignado' : 'servicios asignados'}',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            nombres.isEmpty
                ? 'Aún no tiene servicios asignados.'
                : nombres.take(2).join(' · ') +
                    (nombres.length > 2 ? ' · y ${nombres.length - 2} más' : ''),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _verResumen(empleado),
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text('Ver servicios'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryPink,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: (_guardando || !empleado.estado)
                      ? null
                      : () => _editar(empleado),
                  icon: const Icon(Icons.tune_rounded, size: 17),
                  label: const Text('Asignar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final consulta = _busqueda.trim().toLowerCase();
    final visibles = _empleados.where((e) =>
        e.nombreCompleto.toLowerCase().contains(consulta) ||
        e.puesto.toLowerCase().contains(consulta)).toList();
    final activos = _empleados.where((e) => e.estado).length;
    final conServicios = _empleados.where((e) =>
      (_asignaciones[e.idEmpleado] ?? <String>{}).isNotEmpty).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        centerTitle: true,
        title: Text(
          'Asignar servicios',
          style: AppTextStyles.displayExtraBold.copyWith(
            color: AppColors.textDark,
            fontSize: 21,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar listado',
            onPressed: (_cargando || _guardando) ? null : _cargar,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryPink),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryPinkSoft, Color(0xFFFFF4F6)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.spa_outlined,
                          color: AppColors.primaryPink,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Servicios por especialista',
                              style: AppTextStyles.subtitle.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Elige qué tratamientos puede realizar cada profesional.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _resumen('${_empleados.length}', 'Especialistas', Icons.groups_outlined),
                    const SizedBox(width: 8),
                    _resumen('$activos', 'Activos', Icons.verified_user_outlined),
                    const SizedBox(width: 8),
                    _resumen('$conServicios', 'Con servicios', Icons.checklist_rounded),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (valor) => setState(() => _busqueda = valor),
                  decoration: InputDecoration(
                    hintText: 'Buscar especialista o puesto',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primaryPink,
                    ),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${visibles.length} ${visibles.length == 1 ? 'resultado' : 'resultados'}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Solo especialistas',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryPink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 38, color: AppColors.primaryPink),
                              const SizedBox(height: 10),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 14),
                              FilledButton(
                                onPressed: _cargar,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : visibles.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off_rounded, size: 44, color: AppColors.textMuted),
                                  const SizedBox(height: 10),
                                  Text(
                                    _empleados.isEmpty
                                        ? 'Aún no hay especialistas registrados.'
                                        : 'No encontramos especialistas con esa búsqueda.',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                            itemCount: visibles.length,
                            itemBuilder: (context, index) => _tarjeta(visibles[index]),
                          ),
          ),
        ],
      ),
    );
  }
}
