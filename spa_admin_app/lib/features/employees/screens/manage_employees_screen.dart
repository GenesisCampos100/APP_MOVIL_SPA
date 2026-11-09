import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import 'package:spa_admin_app/data/models/employee_model.dart';
import 'package:spa_admin_app/data/repositories/empleados_repository.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/features/employees/widgets/employee_card_widget.dart';
import 'package:spa_admin_app/features/employees/widgets/employee_form_dialog.dart';
import 'package:spa_admin_app/shared/widgets/confirm_action_dialog.dart';

/// Pantalla de personal. Las acciones existentes permanecen conectadas a la API.
class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({super.key});

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  final EmpleadosRepository _repository = EmpleadosRepository();
  final TextEditingController _busquedaController = TextEditingController();

  List<EmployeeModel> _employees = const [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String _filtro = 'Todos';
  String? _actualizandoEstadoId;

  @override
  void initState() {
    super.initState();
    _cargarEmpleados();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarEmpleados() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final empleados = await _repository.obtenerEmpleados();
      if (!mounted) return;
      setState(() {
        _employees = empleados;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo actualizar la lista. Intenta nuevamente.';
      });
    }
  }

  String _mensajeError(Object error) => error is ApiException
      ? error.message
      : 'No se pudo completar la operación. Intenta nuevamente.';

  Future<void> _abrirFormulario({EmployeeModel? empleado}) async {
    try {
      final puestos = await _repository.obtenerPuestos();
      if (!mounted) return;
      if (puestos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay puestos disponibles para asignar.'),
          ),
        );
        return;
      }
      final guardado = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => EmployeeFormDialog(
          employeeToEdit: empleado,
          puestos: puestos,
          onSave: (datos) async {
            if (empleado == null) {
              await _repository.crearEmpleado(datos);
            } else {
              await _repository.editarEmpleado(empleado.idEmpleado, datos);
            }
          },
        ),
      );
      if (!mounted || guardado != true) return;
      await _cargarEmpleados();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(empleado == null
              ? 'Empleado registrado correctamente.'
              : 'Empleado actualizado correctamente.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mensajeError(error))),
      );
    }
  }

  Future<void> _cambiarEstado(EmployeeModel empleado) async {
    if (_actualizandoEstadoId != null) return;
    final nuevoEstado = !empleado.estado;
    final confirmado = await mostrarConfirmacion(
      context: context,
      titulo: nuevoEstado ? '¿Reactivar empleado?' : '¿Desactivar empleado?',
      mensaje: nuevoEstado
          ? '${empleado.nombreCompleto} podrá volver a iniciar sesión.'
          : '${empleado.nombreCompleto} no podrá iniciar una nueva sesión. '
              'Antes de desactivarlo, deberán resolverse sus citas futuras pendientes.',
      textoConfirmar: nuevoEstado ? 'Sí, reactivar' : 'Sí, desactivar',
      icono: nuevoEstado
          ? Icons.check_circle_outline
          : Icons.person_off_outlined,
    );
    if (!mounted || !confirmado) return;
    setState(() => _actualizandoEstadoId = empleado.idEmpleado);
    try {
      await _repository.cambiarEstado(empleado.idEmpleado, activo: nuevoEstado);
      if (!mounted) return;
      await _cargarEmpleados();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nuevoEstado
              ? 'Empleado reactivado correctamente.'
              : 'Empleado desactivado correctamente.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mensajeError(error))),
      );
    } finally {
      if (mounted) setState(() => _actualizandoEstadoId = null);
    }
  }

  List<EmployeeModel> get _filtrados {
    final q = _searchQuery.toLowerCase().trim();
    return _employees.where((e) {
      final coincide = e.nombreCompleto.toLowerCase().contains(q) ||
          e.puesto.toLowerCase().contains(q) ||
          e.correo.toLowerCase().contains(q);
      final estado = _filtro == 'Todos' ||
          (_filtro == 'Activos' && e.estado) ||
          (_filtro == 'Inactivos' && !e.estado);
      return coincide && estado;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final disponibles = _filtrados;
    final activos = _employees.where((e) => e.estado).length;
    final inactivos = _employees.length - activos;
    final reducirMovimiento = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                tooltip: 'Regresar',
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textDark,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Gestionar empleados',
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.textDark,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar empleados',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryPink),
            onPressed: _loading ? null : _cargarEmpleados,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Administración del personal', style: AppTextStyles.heading2),
                const SizedBox(height: 4),
                Text(
                  'Consulta, organiza y administra al personal del SPA.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _resumenEstado('Activos', activos, Icons.check_circle_outline),
                    const SizedBox(width: 10),
                    _resumenEstado('Inactivos', inactivos, Icons.pause_circle_outline),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _busquedaController,
                  onChanged: (texto) => setState(() => _searchQuery = texto),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, puesto o correo',
                    hintStyle: AppTextStyles.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primaryPink,
                    ),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpiar búsqueda',
                            icon: const Icon(Icons.close_rounded, size: 19),
                            onPressed: () {
                              _busquedaController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                    filled: true,
                    fillColor: AppColors.fieldBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filtroChip('Todos'),
                      const SizedBox(width: 8),
                      _filtroChip('Activos'),
                      const SizedBox(width: 8),
                      _filtroChip('Inactivos'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${disponibles.length} empleado(s)',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _loading || _error != null ||
                              _actualizandoEstadoId != null
                          ? null
                          : () => _abrirFormulario(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nuevo'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: reducirMovimiento
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _loading
                  ? const Center(
                      key: ValueKey('cargando'),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPink,
                      ),
                    )
                  : _error != null
                      ? _mensaje(
                          key: 'error',
                          icon: Icons.wifi_off_outlined,
                          titulo: 'No se pudo cargar el personal',
                          detalle: _error!,
                          reintentar: true,
                        )
                      : disponibles.isEmpty
                          ? _mensaje(
                              key: 'vacio-$_filtro-$_searchQuery',
                              icon: Icons.people_outline,
                              titulo: _employees.isEmpty
                                  ? 'Aún no hay empleados'
                                  : 'No encontramos coincidencias',
                              detalle: _employees.isEmpty
                                  ? 'Registra a tu primer empleado con el botón Nuevo.'
                                  : 'Prueba con otro nombre o cambia el filtro.',
                            )
                          : RefreshIndicator(
                              key: const ValueKey('empleados'),
                              onRefresh: _cargarEmpleados,
                              color: AppColors.primaryPink,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(18, 7, 18, 28),
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                itemCount: disponibles.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final empleado = disponibles[index];
                                  return TweenAnimationBuilder<double>(
                                    key: ValueKey(empleado.idEmpleado),
                                    tween: Tween<double>(
                                      begin: reducirMovimiento ? 1 : 0,
                                      end: 1,
                                    ),
                                    duration: Duration(
                                      milliseconds: reducirMovimiento
                                          ? 0
                                          : 180 + ((index < 5 ? index : 5) * 30),
                                    ),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, progreso, child) => Opacity(
                                      opacity: progreso,
                                      child: Transform.translate(
                                        offset: Offset(0, 8 * (1 - progreso)),
                                        child: child,
                                      ),
                                    ),
                                    child: EmployeeCardWidget(
                                      empleado: empleado,
                                      actualizando: _actualizandoEstadoId ==
                                          empleado.idEmpleado,
                                      accionesDisponibles:
                                          _actualizandoEstadoId == null,
                                      onEditar: () => _abrirFormulario(
                                        empleado: empleado,
                                      ),
                                      onCambiarEstado: () =>
                                          _cambiarEstado(empleado),
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumenEstado(String titulo, int valor, IconData icono) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryPinkSoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icono, size: 20, color: AppColors.primaryPink),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textDark,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                _loading && _employees.isEmpty ? '—' : '$valor',
                key: ValueKey('$titulo-$valor-$_loading'),
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.primaryPink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filtroChip(String filtro) {
    final seleccionado = _filtro == filtro;
    return ChoiceChip(
      label: Text(filtro),
      selected: seleccionado,
      showCheckmark: seleccionado,
      selectedColor: AppColors.primaryPinkSoft,
      checkmarkColor: AppColors.primaryPink,
      backgroundColor: AppColors.cardBackground,
      side: BorderSide(
        color: seleccionado ? AppColors.primaryPinkSoft : AppColors.cardBorder,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      labelStyle: AppTextStyles.caption.copyWith(
        fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w400,
        color: seleccionado ? AppColors.primaryPink : AppColors.textDark,
      ),
      onSelected: (_) => setState(() => _filtro = filtro),
    );
  }

  Widget _mensaje({
    required String key,
    required IconData icon,
    required String titulo,
    required String detalle,
    bool reintentar = false,
  }) {
    return Center(
      key: ValueKey(key),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryPink, size: 42),
            const SizedBox(height: 12),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 7),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            if (reintentar) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _cargarEmpleados,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
