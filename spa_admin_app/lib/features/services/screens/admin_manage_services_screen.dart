import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/admin_visual.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import 'package:spa_admin_app/data/models/service_model.dart';
import 'package:spa_admin_app/data/repositories/servicios_repository.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';
import 'package:spa_admin_app/features/services/widgets/service_form_dialog.dart';
import 'package:spa_admin_app/features/services/widgets/service_image_preview.dart';
import 'package:spa_admin_app/shared/widgets/confirm_action_dialog.dart';

/// Administración completa de servicios, accesible desde Más opciones.
/// La pestaña inferior Servicios conserva su pantalla original.
enum _FiltroServicio { todos, activos, inactivos }

class AdminManageServicesScreen extends StatefulWidget {
  const AdminManageServicesScreen({super.key});

  @override
  State<AdminManageServicesScreen> createState() =>
      _AdminManageServicesScreenState();
}

class _AdminManageServicesScreenState extends State<AdminManageServicesScreen> {
  final _repositorio = ServiciosRepository();
  final _busquedaController = TextEditingController();
  List<ServiceModel> _servicios = [];
  Map<String, String> _categorias = {};
  _FiltroServicio _filtro = _FiltroServicio.todos;
  bool _cargando = true;
  String? _error;
  String? _idEnProceso;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final resultado = await _repositorio.obtenerTodosServiciosAdmin();
      final categorias = await _repositorio.obtenerCategorias();
      if (!mounted) return;
      setState(() {
        _servicios = resultado;
        _categorias = categorias;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No fue posible cargar el catálogo administrativo.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _aviso(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensaje),
      backgroundColor: error ? Colors.red.shade700 : AdminVisual.primaryPink,
    ));
  }

  Future<void> _abrirFormulario({ServiceModel? servicio}) async {
    if (_idEnProceso != null) return;
    final guardado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ServiceFormDialog(
        serviceToEdit: servicio,
        categorias: _categorias,
        onCrearCategoria: (nombre) async {
          final nueva = await _repositorio.crearCategoria(nombre);
          if (mounted) setState(() => _categorias[nueva.key] = nueva.value);
          return nueva;
        },
        onSave: (datos) => servicio == null
            ? _repositorio.crearServicio(datos)
            : _repositorio.actualizarServicio(datos),
      ),
    );
    if (!mounted || guardado != true) return;
    _aviso(servicio == null ? 'Servicio registrado.' : 'Servicio actualizado.');
    await _cargar();
  }

  Future<void> _cambiarEstado(ServiceModel servicio) async {
    if (_idEnProceso != null) return;
    final reactivar = !servicio.estado;
    final confirmado = await mostrarConfirmacion(
      context: context,
      titulo: reactivar ? '¿Reactivar servicio?' : '¿Desactivar servicio?',
      mensaje: reactivar
          ? '«${servicio.nombre}» volverá a estar disponible para nuevas reservas.'
          : '«${servicio.nombre}» dejará de estar disponible para nuevas reservas. Podrás reactivarlo cuando lo necesites.',
      textoConfirmar: reactivar ? 'Sí, reactivar' : 'Sí, desactivar',
      icono: reactivar ? Icons.restore_rounded : Icons.pause_circle_outline,
    );
    if (!mounted || !confirmado) return;

    setState(() => _idEnProceso = servicio.idServicio);
    try {
      if (reactivar) {
        // El PUT existente ya admite estado=true: no duplicamos la API.
        await _repositorio.reactivarServicio(servicio);
      } else {
        await _repositorio.desactivarServicio(servicio);
      }
      if (!mounted) return;
      _aviso(reactivar ? 'Servicio reactivado.' : 'Servicio desactivado.');
      await _cargar();
    } on ApiException catch (e) {
      if (mounted) _aviso(e.message, error: true);
    } on FormatException catch (e) {
      if (mounted) _aviso(e.message, error: true);
    } catch (_) {
      if (mounted) _aviso('No fue posible actualizar el estado.', error: true);
    } finally {
      if (mounted) setState(() => _idEnProceso = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final consulta = _busqueda.toLowerCase().trim();
    final visibles = _servicios.where((servicio) {
      final coincideEstado = switch (_filtro) {
        _FiltroServicio.todos => true,
        _FiltroServicio.activos => servicio.estado,
        _FiltroServicio.inactivos => !servicio.estado,
      };
      final coincideTexto = consulta.isEmpty ||
          servicio.nombre.toLowerCase().contains(consulta) ||
          servicio.categoria.toLowerCase().contains(consulta) ||
          servicio.descripcion.toLowerCase().contains(consulta);
      return coincideEstado && coincideTexto;
    }).toList();
    final activos = _servicios.where((s) => s.estado).length;
    final inactivos = _servicios.length - activos;
    final reducirAnimacion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: AdminVisual.background,
      appBar: AppBar(
        backgroundColor: AdminVisual.background,
        centerTitle: true,
        title: AdminTranslatedText('Gestionar servicios', 'Manage services',
          style: AppTextStyles.heading1.copyWith(color: AdminVisual.textDark)),
        actions: [
          IconButton(
            tooltip: AdminVisual.t('Actualizar catálogo', 'Refresh catalog'),
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryPink),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AdminTranslatedText('Administración del catálogo', 'Catalog management',
              style: AppTextStyles.heading2.copyWith(color: AdminVisual.textDark)),
            const SizedBox(height: 5),
            AdminTranslatedText('Consulta, organiza y administra los servicios del SPA.', 'Browse and manage the spa service catalog.',
              style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
            const SizedBox(height: 14),
            Row(children: [
              _ResumenEstado(label: 'Activos', cantidad: activos, icono: Icons.check_circle_outline),
              const SizedBox(width: 10),
              _ResumenEstado(label: 'Inactivos', cantidad: inactivos, icono: Icons.pause_circle_outline),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: _busquedaController,
              onChanged: (value) => setState(() => _busqueda = value),
              decoration: InputDecoration(
                hintText: AdminVisual.t('Buscar por nombre o categoría', 'Search name or category'),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryPink),
                suffixIcon: consulta.isEmpty ? null : IconButton(
                  tooltip: AdminVisual.t('Limpiar búsqueda', 'Clear search'),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _busquedaController.clear();
                    setState(() => _busqueda = '');
                  },
                ),
                filled: true,
                fillColor: AdminVisual.fieldBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.cardBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.cardBorder)),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filtroChip('Todos', _FiltroServicio.todos),
                const SizedBox(width: 8),
                _filtroChip('Activos', _FiltroServicio.activos),
                const SizedBox(width: 8),
                _filtroChip('Inactivos', _FiltroServicio.inactivos),
              ]),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text('${visibles.length} servicio(s)',
                style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted))),
              FilledButton.icon(
                onPressed: _cargando || _error != null ? null : () => _abrirFormulario(),
                style: FilledButton.styleFrom(backgroundColor: AdminVisual.primaryPink),
                icon: const Icon(Icons.add, size: 18),
                label: const AdminTranslatedText('Nuevo', 'New'),
              ),
            ]),
          ]),
        ),
        Expanded(child: AnimatedSwitcher(
          duration: reducirAnimacion ? Duration.zero : const Duration(milliseconds: 230),
          child: _cargando
              ? const Center(key: ValueKey('cargando'),
                  child: CircularProgressIndicator(color: AppColors.primaryPink))
              : _error != null
                  ? _EstadoLista(
                      key: const ValueKey('error'),
                      icono: Icons.wifi_off_rounded,
                      titulo: 'No se pudo consultar el catálogo',
                      mensaje: _error!, onActualizar: _cargar)
                  : visibles.isEmpty
                      ? _EstadoLista(
                          key: const ValueKey('vacio'),
                          icono: Icons.inventory_2_outlined,
                          titulo: 'No hay servicios para mostrar',
                          mensaje: 'Cambia el filtro o revisa tu búsqueda.',
                          onActualizar: _cargar)
                      : RefreshIndicator(
                          key: const ValueKey('lista'),
                          color: AdminVisual.primaryPink,
                          onRefresh: _cargar,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                            itemCount: visibles.length,
                            itemBuilder: (context, i) {
                              final servicio = visibles[i];
                              return TweenAnimationBuilder<double>(
                                key: ValueKey('servicio_${servicio.idServicio}'),
                                tween: Tween(begin: 0, end: 1),
                                duration: reducirAnimacion ? Duration.zero :
                                    Duration(milliseconds: 170 + ((i < 5 ? i : 5) * 30)),
                                builder: (context, progreso, child) => Opacity(
                                  opacity: progreso,
                                  child: Transform.translate(
                                    offset: Offset(0, 8 * (1 - progreso)),
                                    child: child,
                                  ),
                                ),
                                child: _TarjetaAdmin(
                                  servicio: servicio,
                                  ocupada: _idEnProceso == servicio.idServicio,
                                  bloqueada: _idEnProceso != null,
                                  onEditar: () => _abrirFormulario(servicio: servicio),
                                  onCambiarEstado: () => _cambiarEstado(servicio),
                                ),
                              );
                            },
                          ),
                        ),
        )),
      ]),
    );
  }

  Widget _filtroChip(String titulo, _FiltroServicio filtro) => ChoiceChip(
    label: Text(AdminVisual.ui(titulo)),
    selected: _filtro == filtro,
    selectedColor: AdminVisual.primaryPinkSoft,
    checkmarkColor: AdminVisual.primaryPink,
    side: const BorderSide(color: AppColors.cardBorder),
    labelStyle: TextStyle(
      color: _filtro == filtro ? AdminVisual.primaryPink : AdminVisual.textDark,
      fontWeight: _filtro == filtro ? FontWeight.w600 : FontWeight.normal,
    ),
    onSelected: (_) => setState(() => _filtro = filtro),
  );
}

class _ResumenEstado extends StatelessWidget {
  const _ResumenEstado({required this.label, required this.cantidad, required this.icono});
  final String label;
  final int cantidad;
  final IconData icono;

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      color: AdminVisual.primaryPinkSoft,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      Icon(icono, color: AdminVisual.primaryPink, size: 20),
      const SizedBox(width: 7),
      Expanded(child: Text(AdminVisual.ui(label), style: AppTextStyles.caption.copyWith(color: AdminVisual.textDark))),
      Text('$cantidad', style: AppTextStyles.heading2.copyWith(color: AdminVisual.primaryPink)),
    ]),
  ));
}

class _TarjetaAdmin extends StatelessWidget {
  const _TarjetaAdmin({
    required this.servicio,
    required this.ocupada,
    required this.bloqueada,
    required this.onEditar,
    required this.onCambiarEstado,
  });
  final ServiceModel servicio;
  final bool ocupada;
  final bool bloqueada;
  final VoidCallback onEditar;
  final VoidCallback onCambiarEstado;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AdminVisual.cardBackground,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AdminVisual.cardBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ServiceImagePreview(imagen: servicio.imagen, size: 58),
        const SizedBox(width: 10),
        Expanded(child: Text(servicio.nombre,
          style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700,
            color: AdminVisual.textDark))),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: servicio.estado ? AdminVisual.greenBackground : AdminVisual.statusBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(AdminVisual.ui(servicio.estado ? 'Activo' : 'Inactivo'),
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: servicio.estado ? AdminVisual.greenText : AdminVisual.textMuted,
            )),
        ),
      ]),
      if (servicio.descripcion.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(servicio.descripcion,
          maxLines: 2, overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
      ],
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 7, children: [
        _dato(Icons.category_outlined, servicio.categoria.isEmpty ? 'Sin categoría' : servicio.categoria),
        _dato(Icons.schedule_outlined, servicio.duracion),
        _dato(Icons.payments_outlined, '\$${servicio.precio.toStringAsFixed(2)} MXN'),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        OutlinedButton.icon(
          onPressed: bloqueada ? null : onEditar,
          icon: const Icon(Icons.edit_outlined, size: 17),
          label: const AdminTranslatedText('Editar', 'Edit'),
        ),
        const SizedBox(width: 10),
        Expanded(child: FilledButton.icon(
          onPressed: bloqueada ? null : onCambiarEstado,
          style: FilledButton.styleFrom(
            backgroundColor: AdminVisual.primaryPink,
            padding: const EdgeInsets.symmetric(horizontal: 10),
          ),
          icon: ocupada
              ? const SizedBox(width: 17, height: 17,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(servicio.estado ? Icons.pause_circle_outline : Icons.restore_rounded,
                  size: 18),
          label: Text(AdminVisual.ui(servicio.estado ? 'Desactivar' : 'Reactivar')),
        )),
      ]),
    ]),
  );

  Widget _dato(IconData icono, String valor) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icono, size: 15, color: AdminVisual.primaryPink),
      const SizedBox(width: 5),
      Text(valor, style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
    ],
  );
}

class _EstadoLista extends StatelessWidget {
  const _EstadoLista({super.key, required this.icono,
    required this.titulo, required this.mensaje, required this.onActualizar});
  final IconData icono;
  final String titulo;
  final String mensaje;
  final VoidCallback onActualizar;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icono, color: AdminVisual.primaryPink, size: 38),
        const SizedBox(height: 12),
        Text(titulo, textAlign: TextAlign.center,
          style: AppTextStyles.heading2.copyWith(color: AdminVisual.textDark)),
        const SizedBox(height: 8),
        Text(mensaje, textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(color: AdminVisual.textMuted)),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: onActualizar,
          icon: const Icon(Icons.refresh_rounded), label: const AdminTranslatedText('Reintentar', 'Retry')),
      ]),
    ),
  );
}
