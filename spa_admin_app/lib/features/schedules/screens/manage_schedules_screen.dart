import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/admin_visual.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/data/models/horario_semanal_model.dart';
import 'package:spa_admin_app/data/repositories/horarios_repository.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/features/schedules/widgets/horario_bloque_form_dialog.dart';

/// Consulta y administración de turnos semanales del personal.
class ManageSchedulesScreen extends StatefulWidget {
  /// Si se abre tras crear un especialista, lo selecciona y muestra
  /// automáticamente el formulario para definir sus días y turnos.
  final int? empleadoInicialId;

  const ManageSchedulesScreen({super.key, this.empleadoInicialId});

  @override
  State<ManageSchedulesScreen> createState() => _ManageSchedulesScreenState();
}

class _ManageSchedulesScreenState extends State<ManageSchedulesScreen> {
  final HorariosRepository _repository = HorariosRepository();
  final TextEditingController _busquedaController = TextEditingController();
  static const List<String> _dias = <String>[
    'Todos', 'Lunes', 'Martes', 'Miercoles', 'Jueves',
    'Viernes', 'Sabado', 'Domingo',
  ];
  static const Map<String, String> _etiquetas = <String, String>{
    'Todos': 'Todos',
    'Lunes': 'Lun',
    'Martes': 'Mar',
    'Miercoles': 'Mié',
    'Jueves': 'Jue',
    'Viernes': 'Vie',
    'Sabado': 'Sáb',
    'Domingo': 'Dom',
  };

  List<EmpleadoConHorarios> _empleados = const [];
  bool _cargando = true;
  bool _procesando = false;
  String? _error;
  String _diaSeleccionado = 'Todos';
  int? _empleadoSeleccionado;
  bool _intentoAbrirHorarioInicial = false;

  @override
  void initState() {
    super.initState();
    _busquedaController.addListener(_actualizarBusqueda);
    _cargar();
  }

  @override
  void dispose() {
    _busquedaController.removeListener(_actualizarBusqueda);
    _busquedaController.dispose();
    super.dispose();
  }

  void _actualizarBusqueda() {
    if (mounted) setState(() {});
  }

  Future<void> _cargar() async {
    if (mounted) setState(() { _cargando = true; _error = null; });
    try {
      final nuevos = await _repository.obtenerHorarios();
      if (!mounted) return;
      final primeraApertura = !_intentoAbrirHorarioInicial &&
          widget.empleadoInicialId != null;
      EmpleadoConHorarios? objetivo;
      if (primeraApertura) {
        _intentoAbrirHorarioInicial = true;
        for (final item in nuevos) {
          if (item.idEmpleado == widget.empleadoInicialId) {
            objetivo = item;
            break;
          }
        }
      }
      final empleadoObjetivo = objetivo;
      setState(() {
        _empleados = nuevos;
        if (empleadoObjetivo != null) {
          _empleadoSeleccionado = empleadoObjetivo.idEmpleado;
        } else if (_empleadoSeleccionado != null &&
            !nuevos.any((e) => e.idEmpleado == _empleadoSeleccionado)) {
          _empleadoSeleccionado = null;
        }
        _cargando = false;
      });
      if (primeraApertura) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (empleadoObjetivo != null && empleadoObjetivo.activo) {
            _nuevoHorario(empleadoObjetivo);
          } else {
            _mensajeAccion(
              'No fue posible abrir el horario de este especialista. '
              'Puedes seleccionarlo desde la lista.',
            );
          }
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = error is ApiException
            ? error.message
            : 'No pudimos cargar los horarios. Intenta nuevamente.';
      });
    }
  }

  static String _diaNormalizado(String valor) {
    final d = valor.trim().toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    for (final dia in _dias.skip(1)) {
      if (dia.toLowerCase() == d) return dia;
    }
    return valor;
  }

  static int _ordenDia(String dia) {
    final pos = _dias.indexOf(_diaNormalizado(dia));
    return pos < 0 ? 99 : pos;
  }

  List<BloqueHorario> _horariosVisibles(EmpleadoConHorarios empleado) {
    final horarios = empleado.horarios.where((h) =>
        _diaSeleccionado == 'Todos' ||
        _diaNormalizado(h.diaSemana) == _diaSeleccionado).toList();
    horarios.sort((a, b) {
      final dia = _ordenDia(a.diaSemana).compareTo(_ordenDia(b.diaSemana));
      return dia != 0 ? dia : a.horaInicio.compareTo(b.horaInicio);
    });
    return horarios;
  }

  List<EmpleadoConHorarios> get _resultados {
    final texto = _busquedaController.text.trim().toLowerCase();
    return _empleados.where((e) {
      final textoCoincide = texto.isEmpty ||
          e.nombre.toLowerCase().contains(texto) ||
          e.puesto.toLowerCase().contains(texto);
      final empleadoCoincide = _empleadoSeleccionado == null ||
          _empleadoSeleccionado == e.idEmpleado;
      final diaCoincide = _diaSeleccionado == 'Todos' ||
          _horariosVisibles(e).isNotEmpty;
      return textoCoincide && empleadoCoincide && diaCoincide;
    }).toList(growable: false);
  }

  void _mensajeAccion(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _nuevoHorario([EmpleadoConHorarios? empleado]) async {
    if (_procesando) return;
    final disponibles = _empleados.where((e) => e.activo).toList();
    if (disponibles.isEmpty) {
      _mensajeAccion('No hay empleados activos para asignar un horario.');
      return;
    }
    final resultado = await showDialog<DatosBloqueHorario>(
      context: context,
      builder: (_) => HorarioBloqueFormDialog(
        empleados: disponibles,
        empleadoInicial: empleado,
      ),
    );
    if (resultado == null || !mounted) return;
    setState(() => _procesando = true);
    try {
      await _repository.crearHorariosVarios(
        idEmpleado: resultado.idEmpleado,
        diasSemana: resultado.diasSemana,
        horaInicio: resultado.horaInicio,
        horaFin: resultado.horaFin,
      );
      await _cargar();
      _mensajeAccion(resultado.diasSemana.length == 1
          ? 'Horario registrado correctamente.'
          : '${resultado.diasSemana.length} horarios registrados correctamente.');
    } catch (error) {
      _mensajeAccion(error is ApiException
          ? error.message : 'No pudimos registrar el horario.');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _editarHorario(
    EmpleadoConHorarios empleado, BloqueHorario bloque) async {
    if (_procesando) return;
    final resultado = await showDialog<DatosBloqueHorario>(
      context: context,
      builder: (_) => HorarioBloqueFormDialog(
        empleados: [empleado], empleadoInicial: empleado, bloque: bloque,
      ),
    );
    if (resultado == null || !mounted) return;
    setState(() => _procesando = true);
    try {
      await _repository.editarHorario(
        idHorario: bloque.idHorario,
        diaSemana: resultado.diaSemana,
        horaInicio: resultado.horaInicio,
        horaFin: resultado.horaFin,
      );
      await _cargar();
      _mensajeAccion('Horario actualizado correctamente.');
    } catch (error) {
      _mensajeAccion(error is ApiException
          ? error.message : 'No pudimos actualizar el horario.');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _eliminarHorario(
    EmpleadoConHorarios empleado, BloqueHorario bloque) async {
    if (_procesando) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AdminVisual.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const AdminTranslatedText('¿Deseas eliminar este horario?', 'Delete this schedule?'),
        content: Text(
          '${empleado.nombre} · ${_diaVisible(bloque.diaSemana)}\n'
          '${bloque.inicioVisible} – ${bloque.finVisible}\n\n'
          '${AdminVisual.t("No podrás eliminarlo si deja citas futuras sin horario.", "You cannot delete this shift if future appointments would lose their assigned time.")}'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const AdminTranslatedText('Cancelar', 'Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminVisual.primaryPink),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const AdminTranslatedText('Sí, eliminar', 'Yes, delete'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    setState(() => _procesando = true);
    try {
      await _repository.eliminarHorario(bloque.idHorario);
      await _cargar();
      _mensajeAccion('Horario eliminado correctamente.');
    } catch (error) {
      _mensajeAccion(error is ApiException
          ? error.message : 'No pudimos eliminar el horario.');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conHorario = _empleados.where((e) => e.horarios.isNotEmpty).length;
    final sinHorario = _empleados.length - conHorario;
    final reducirAnimaciones = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: AdminVisual.background,
      appBar: AppBar(
        backgroundColor: AdminVisual.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AdminVisual.textDark),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: AdminVisual.t('Volver', 'Back'),
        ),
        title: AdminTranslatedText('Gestionar horarios', 'Manage schedules',
          style: TextStyle(fontWeight: FontWeight.w800,
              fontSize: 20, color: AdminVisual.textDark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryPink),
            tooltip: AdminVisual.t('Actualizar horarios', 'Refresh schedules'),
            onPressed: _cargando || _procesando ? null : _cargar,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AdminVisual.primaryPink,
        onRefresh: _cargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
          children: [
            AdminTranslatedText('Horarios del equipo', 'Team schedules',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700,
                  color: AdminVisual.textDark)),
            const SizedBox(height: 4),
            AdminTranslatedText('Consulta los días y turnos del personal.', 'View staff workdays and shifts.',
              style: TextStyle(fontSize: 13, color: AdminVisual.textMuted)),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: _resumen(
                icono: Icons.event_available_outlined,
                etiqueta: AdminVisual.t('Con horario', 'With schedule'), cantidad: conHorario,
              )),
              const SizedBox(width: 12),
              Expanded(child: _resumen(
                icono: Icons.event_busy_outlined,
                etiqueta: AdminVisual.t('Sin horario', 'No schedule'), cantidad: sinHorario,
              )),
            ]),
            const SizedBox(height: 18),
            TextField(
              controller: _busquedaController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: AdminVisual.t('Buscar por nombre o puesto', 'Search name or job title'),
                hintStyle: TextStyle(color: AdminVisual.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryPink),
                suffixIcon: _busquedaController.text.isNotEmpty
                    ? IconButton(
                        onPressed: _busquedaController.clear,
                        icon: const Icon(Icons.close, size: 19),
                        tooltip: AdminVisual.t('Limpiar búsqueda', 'Clear search'),
                      )
                    : null,
                filled: true,
                fillColor: AdminVisual.fieldBackground,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primaryPink, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_empleados.isNotEmpty) _selectorEmpleados(),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dias.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final dia = _dias[i];
                  final seleccionado = dia == _diaSeleccionado;
                  return ChoiceChip(
                    label: Text(AdminVisual.ui(_etiquetas[dia] ?? dia)),
                    selected: seleccionado,
                    onSelected: (_) => setState(() => _diaSeleccionado = dia),
                    selectedColor: AdminVisual.primaryPinkSoft,
                    backgroundColor: AdminVisual.cardBackground,
                    labelStyle: TextStyle(
                      color: seleccionado ? AdminVisual.primaryPink : AdminVisual.textMuted,
                      fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: const BorderSide(color: AppColors.cardBorder),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_resultados.length} empleado(s)',
                  style: TextStyle(color: AdminVisual.textMuted, fontSize: 13)),
                FilledButton.icon(
                  onPressed: _cargando || _procesando || _empleados.where((e) => e.activo).isEmpty
                      ? null : () => _nuevoHorario(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const AdminTranslatedText('Nuevo horario', 'New schedule'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminVisual.primaryPink,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: reducirAnimaciones
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              child: _cargando
                  ? const Padding(
                      key: ValueKey('cargando'),
                      padding: EdgeInsets.symmetric(vertical: 54),
                      child: Center(child: CircularProgressIndicator(
                        color: AppColors.primaryPink,
                      )),
                    )
                  : _error != null
                      ? _mensaje(
                          key: const ValueKey('error'),
                          icono: Icons.wifi_off_outlined,
                          titulo: 'No pudimos cargar los horarios',
                          detalle: _error!,
                          boton: 'Reintentar',
                          onPressed: _cargar,
                        )
                      : _resultados.isEmpty
                          ? _mensaje(
                              key: const ValueKey('vacio'),
                              icono: Icons.calendar_today_outlined,
                              titulo: _empleados.isEmpty
                                  ? 'Aún no hay empleados registrados'
                                  : 'No hay horarios que coincidan',
                              detalle: 'Prueba con otro empleado o día de la semana.',
                            )
                          : Column(
                              key: ValueKey('resultados_${_diaSeleccionado}_${_empleadoSeleccionado}_${_busquedaController.text}'),
                              children: _resultados.asMap().entries.map((entry) =>
                                _tarjeta(entry.value, entry.key),
                              ).toList(),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumen({
    required IconData icono,
    required String etiqueta,
    required int cantidad,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
      decoration: BoxDecoration(
        color: AdminVisual.primaryPinkSoft,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(children: [
        Icon(icono, color: AdminVisual.primaryPink, size: 22),
        const SizedBox(width: 8),
        Expanded(child: Text(etiqueta,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted))),
        Text('$cantidad', style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primaryPink)),
      ]),
    );
  }

  Widget _selectorEmpleados() {
    return DropdownButtonFormField<int?>(
      value: _empleadoSeleccionado,
      hint: const AdminTranslatedText('Todo el personal', 'All staff'),
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.people_alt_outlined, color: AppColors.primaryPink),
        filled: true,
        fillColor: AdminVisual.fieldBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(13),
        ),
      ),
      items: <DropdownMenuItem<int?>>[
        const DropdownMenuItem<int?>(value: null, child: const AdminTranslatedText('Todo el personal', 'All staff')),
        ..._empleados.map((e) => DropdownMenuItem<int?>(
          value: e.idEmpleado,
          child: Text(e.nombre, overflow: TextOverflow.ellipsis),
        )),
      ],
      onChanged: (valor) => setState(() => _empleadoSeleccionado = valor),
    );
  }

  Widget _tarjeta(EmpleadoConHorarios empleado, int indice) {
    final bloques = _horariosVisibles(empleado);
    return TweenAnimationBuilder<double>(
      key: ValueKey('empleado_${empleado.idEmpleado}'),
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : Duration(milliseconds: 240 + ((indice < 4 ? indice : 4) * 55)),
      builder: (context, valor, child) => Opacity(
        opacity: valor,
        child: Transform.translate(
          offset: Offset(0, (1 - valor) * 10),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AdminVisual.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AdminVisual.cardBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AdminVisual.primaryPinkSoft,
              child: Text(empleado.nombre.isNotEmpty ? empleado.nombre[0].toUpperCase() : '·',
                style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(empleado.nombre,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                    color: AdminVisual.textDark)),
              const SizedBox(height: 3),
              Text(empleado.puesto, style: TextStyle(
                  color: AdminVisual.textMuted, fontSize: 13)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: empleado.activo ? AdminVisual.greenBackground : AdminVisual.statusBackground,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(AdminVisual.ui(empleado.activo ? 'Activo' : 'Inactivo'),
                style: TextStyle(color: empleado.activo
                    ? AdminVisual.greenText : AdminVisual.textMuted,
                    fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 14),
          const Divider(color: AppColors.cardBorder),
          const SizedBox(height: 6),
          if (bloques.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text('Aún no tiene horarios registrados.',
                style: TextStyle(color: AdminVisual.textMuted, fontSize: 13)),
            )
          else
            ...bloques.map((bloque) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                const Icon(Icons.event_note_outlined, color: AppColors.primaryPink, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(AdminVisual.ui(_diaVisible(bloque.diaSemana)),
                  style: TextStyle(color: AdminVisual.textDark,
                    fontWeight: FontWeight.w600, fontSize: 13))),
                Icon(Icons.schedule, color: AdminVisual.textMuted, size: 16),
                const SizedBox(width: 5),
                Text('${bloque.inicioVisible} – ${bloque.finVisible}',
                  style: TextStyle(color: AdminVisual.textDark, fontSize: 13)),
                PopupMenuButton<String>(
                  tooltip: 'Opciones del turno',
                  enabled: !_procesando,
                  icon: const Icon(Icons.more_vert, color: AppColors.primaryPink, size: 20),
                  onSelected: (accion) {
                    if (accion == 'editar') _editarHorario(empleado, bloque);
                    if (accion == 'eliminar') _eliminarHorario(empleado, bloque);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'editar', child: const AdminTranslatedText('Editar turno', 'Edit shift')),
                    PopupMenuItem(value: 'eliminar', child: const AdminTranslatedText('Eliminar turno', 'Delete shift')),
                  ],
                ),
              ]),
            )),
          const SizedBox(height: 8),
          const Divider(color: AppColors.cardBorder),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _procesando || !empleado.activo
                  ? null : () => _nuevoHorario(empleado),
              icon: const Icon(Icons.add, size: 18),
              label: const AdminTranslatedText('Agregar turno', 'Add shift'),
              style: TextButton.styleFrom(foregroundColor: AdminVisual.primaryPink),
            ),
          ),
        ]),
      ),
    );
  }

  static String _diaVisible(String dia) {
    switch (_diaNormalizado(dia)) {
      case 'Miercoles': return 'Miércoles';
      case 'Sabado': return 'Sábado';
      default: return dia;
    }
  }

  Widget _mensaje({
    required Key key,
    required IconData icono,
    required String titulo,
    required String detalle,
    String? boton,
    VoidCallback? onPressed,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(25),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AdminVisual.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminVisual.cardBorder),
      ),
      child: Column(children: [
        Icon(icono, size: 32, color: AdminVisual.primaryPink),
        const SizedBox(height: 10),
        Text(titulo, textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 6),
        Text(detalle, textAlign: TextAlign.center,
          style: TextStyle(color: AdminVisual.textMuted, fontSize: 13)),
        if (boton != null && onPressed != null) ...[
          const SizedBox(height: 10),
          TextButton(onPressed: onPressed, child: Text(boton)),
        ],
      ]),
    );
  }
}
