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

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final ServiciosRepository _repository = ServiciosRepository();
  final TextEditingController _busquedaController = TextEditingController();
  List<ServiceModel> _services = [];
  Map<String, String> _categorias = {};
  bool _cargando = true;
  String? _error;
  String _busqueda = '';
  String? _idEnProceso;

  @override
  void initState() {
    super.initState();
    _cargarServicios();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarServicios() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final servicios = await _repository.obtenerServicios();
      final categorias = await _repository.obtenerCategorias();
      if (!mounted) return;
      setState(() {
        _services = servicios;
        _categorias = categorias;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No fue posible cargar los servicios.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _abrirFormulario({ServiceModel? servicio}) async {
    final categorias = _categorias;
    final guardado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ServiceFormDialog(
        serviceToEdit: servicio,
        categorias: categorias,
        onCrearCategoria: (nombre) async {
          final nueva = await _repository.crearCategoria(nombre);
          if (mounted) setState(() => _categorias[nueva.key] = nueva.value);
          return nueva;
        },
        onSave: (datos) => servicio == null
            ? _repository.crearServicio(datos)
            : _repository.actualizarServicio(datos),
      ),
    );
    if (guardado == true && mounted) {
      _mostrarMensaje(servicio == null
          ? 'Servicio creado correctamente.'
          : 'Servicio actualizado correctamente.');
      await _cargarServicios();
    }
  }

  Future<void> _desactivarServicio(ServiceModel servicio) async {
    if (_idEnProceso != null) return;
    final aceptado = await mostrarConfirmacion(
      context: context,
      titulo: '¿Desactivar servicio?',
      mensaje: '«${servicio.nombre}» dejará de estar disponible para nuevas reservas. '
          'Podrás reactivarlo desde Gestionar servicios.',
      textoConfirmar: 'Sí, desactivar',
      icono: Icons.info_outline_rounded,
    );
    if (!aceptado || !mounted) return;

    setState(() => _idEnProceso = servicio.idServicio);
    try {
      await _repository.desactivarServicio(servicio);
      if (!mounted) return;
      _mostrarMensaje('Servicio desactivado correctamente.');
      await _cargarServicios();
    } on ApiException catch (e) {
      if (mounted) _mostrarMensaje(e.message, error: true);
    } catch (_) {
      if (mounted) _mostrarMensaje('No se pudo desactivar el servicio.', error: true);
    } finally {
      if (mounted) setState(() => _idEnProceso = null);
    }
  }

  void _mostrarMensaje(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? Colors.red.shade700 : _ServiciosTema.acentoBoton(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final consulta = _busqueda.trim().toLowerCase();
    final visibles = _services.where((s) =>
      s.nombre.toLowerCase().contains(consulta) ||
      s.categoria.toLowerCase().contains(consulta) ||
      s.descripcion.toLowerCase().contains(consulta)
    ).toList();
    final animacionesReducidas = MediaQuery.disableAnimationsOf(context);
    // Theme.of(context) registra esta pestaña en el tema heredado.
    // IndexedStack conserva su State: debe reconstruirse al cambiar la apariencia.
    final temaActual = Theme.of(context);
    final idiomaActual = Localizations.localeOf(context).languageCode;

    return Scaffold(
      backgroundColor: temaActual.brightness == Brightness.dark
          ? const Color(0xFF211A21)
          : AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              )
            : null,
        title: AdminTranslatedText('Gestionar servicios', 'Manage services',
          style: AppTextStyles.displayExtraBold.copyWith(color: _ServiciosTema.texto(context)),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar servicios',
            onPressed: _cargando ? null : _cargarServicios,
            icon: Icon(Icons.refresh_rounded, color: _ServiciosTema.acento(context)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: AdminTranslatedText(
                    'Catálogo del SPA', 'Spa catalog',
                    style: AppTextStyles.heading2.copyWith(color: _ServiciosTema.texto(context)),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _ServiciosTema.acentoBoton(context),
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  ),
                  onPressed: _cargando || _error != null ? null : () => _abrirFormulario(),
                  icon: const Icon(Icons.add_rounded),
                  label: const AdminTranslatedText('Agregar', 'Add'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _busquedaController,
              onChanged: (valor) => setState(() => _busqueda = valor),
              decoration: InputDecoration(
                hintText: AdminVisual.t('Buscar servicio o categoría...', 'Search service or category...'),
                prefixIcon: Icon(Icons.search_rounded, color: _ServiciosTema.acento(context)),
                suffixIcon: _busqueda.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _busquedaController.clear();
                          setState(() => _busqueda = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      )
                    : null,
                filled: true,
                fillColor: _ServiciosTema.campo(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _ServiciosTema.borde(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _ServiciosTema.borde(context)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _cargando ? (idiomaActual == 'en' ? 'Loading catalog…' : 'Consultando catálogo…')
                    : idiomaActual == 'en' ? '${visibles.length} service(s) shown' : '${visibles.length} servicio(s) visible(s)',
                style: AppTextStyles.caption.copyWith(color: _ServiciosTema.secundario(context)),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: animacionesReducidas
                  ? Duration.zero
                  : const Duration(milliseconds: 240),
              child: _cargando
                  ? Center(
                      key: const ValueKey('loading'),
                      child: CircularProgressIndicator(color: _ServiciosTema.acento(context)),
                    )
                  : _error != null
                      ? _EstadoServicios(
                          key: const ValueKey('error'),
                          icono: Icons.wifi_off_rounded,
                          titulo: AdminVisual.t('No se pudieron cargar los servicios', 'Could not load services'),
                          descripcion: _error!,
                          onActualizar: _cargarServicios,
                        )
                      : visibles.isEmpty
                          ? _EstadoServicios(
                              key: const ValueKey('empty'),
                              icono: Icons.spa_outlined,
                              titulo: _busqueda.isEmpty
                                  ? AdminVisual.t('No hay servicios activos', 'No active services')
                                  : AdminVisual.t('No se encontraron servicios', 'No services found'),
                              descripcion: _busqueda.isEmpty
                                  ? AdminVisual.t('Los servicios registrados aparecerán aquí.', 'Registered services will appear here.')
                                  : AdminVisual.t('Intenta buscar con otro nombre o categoría.', 'Try a different name or category.'),
                              onActualizar: _cargarServicios,
                            )
                          : RefreshIndicator(
                              key: const ValueKey('list'),
                              color: _ServiciosTema.acentoBoton(context),
                              onRefresh: _cargarServicios,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                itemCount: visibles.length,
                                itemBuilder: (context, index) {
                                  final servicio = visibles[index];
                                  return TweenAnimationBuilder<double>(
                                    key: ValueKey(servicio.idServicio),
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: animacionesReducidas
                                        ? Duration.zero
                                        : Duration(milliseconds: 180 + ((index < 5 ? index : 5) * 35)),
                                    builder: (context, avance, child) => Opacity(
                                      opacity: avance,
                                      child: Transform.translate(
                                        offset: Offset(0, (1 - avance) * 10),
                                        child: child,
                                      ),
                                    ),
                                    child: _TarjetaServicio(
                                      servicio: servicio,
                                      trabajando: _idEnProceso == servicio.idServicio,
                                      onEditar: () => _abrirFormulario(servicio: servicio),
                                      onDesactivar: () => _desactivarServicio(servicio),
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
}

/// Colores de esta pestaña basados en el tema Flutter activo, no en
/// valores globales que pueden quedar obsoletos dentro del IndexedStack.
/// No interviene en repositorios, validaciones ni estados de los servicios.
class _ServiciosTema {
  const _ServiciosTema._();
  static bool oscuro(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color tarjeta(BuildContext context) => oscuro(context)
      ? const Color(0xFF302630) : AppColors.cardBackground;
  static Color campo(BuildContext context) => oscuro(context)
      ? const Color(0xFF382C37) : AppColors.fieldBackground;
  static Color borde(BuildContext context) => oscuro(context)
      ? const Color(0xFF584654) : AppColors.cardBorder;
  static Color texto(BuildContext context) => oscuro(context)
      ? const Color(0xFFFFEFF5) : AppColors.textDark;
  static Color secundario(BuildContext context) => oscuro(context)
      ? const Color(0xFFD5C0CC) : AppColors.textMuted;
  static Color acento(BuildContext context) => oscuro(context)
      ? const Color(0xFFF3B8CE) : AppColors.primaryPink;
  static Color acentoBoton(BuildContext context) => oscuro(context)
      ? const Color(0xFFB46E8A) : AppColors.primaryPink;
  static Color verdeFondo(BuildContext context) => oscuro(context)
      ? const Color(0xFF244237) : const Color(0xFFE8F5EB);
  static Color verdeTexto(BuildContext context) => oscuro(context)
      ? const Color(0xFF9EE3B7) : const Color(0xFF286A44);
}

class _TarjetaServicio extends StatelessWidget {
  final ServiceModel servicio;
  final bool trabajando;
  final VoidCallback onEditar;
  final VoidCallback onDesactivar;

  const _TarjetaServicio({
    required this.servicio,
    required this.trabajando,
    required this.onEditar,
    required this.onDesactivar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _ServiciosTema.tarjeta(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ServiciosTema.borde(context)),
        boxShadow: [
          BoxShadow(
            color: _ServiciosTema.acentoBoton(context).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ServiceImagePreview(imagen: servicio.imagen, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      servicio.nombre,
                      style: AppTextStyles.heading2.copyWith(color: _ServiciosTema.texto(context)),
                    ),
                    const SizedBox(height: 4),
                    Text(servicio.categoria,
                      style: AppTextStyles.caption.copyWith(color: _ServiciosTema.secundario(context)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _ServiciosTema.verdeFondo(context),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: AdminTranslatedText('Activo', 'Active',
                  style: TextStyle(color: _ServiciosTema.verdeTexto(context), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (servicio.descripcion.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              servicio.descripcion,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(color: _ServiciosTema.secundario(context)),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _DatoIcono(icono: Icons.schedule_outlined, texto: servicio.duracion),
              _DatoIcono(icono: Icons.payments_outlined, texto: '\$${servicio.precio.toStringAsFixed(2)} MXN'),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: _ServiciosTema.borde(context)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: trabajando ? null : onDesactivar,
                icon: trabajando
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.block_outlined, size: 19),
                label: const AdminTranslatedText('Desactivar', 'Deactivate'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: trabajando ? null : onEditar,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const AdminTranslatedText('Editar', 'Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatoIcono extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _DatoIcono({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 17, color: _ServiciosTema.acentoBoton(context)),
        const SizedBox(width: 5),
        Text(texto, style: AppTextStyles.caption.copyWith(color: _ServiciosTema.texto(context))),
      ],
    );
  }
}

class _EstadoServicios extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onActualizar;

  const _EstadoServicios({
    super.key,
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onActualizar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 44, color: _ServiciosTema.acentoBoton(context)),
            const SizedBox(height: 14),
            Text(titulo, textAlign: TextAlign.center,
              style: AppTextStyles.heading2.copyWith(color: _ServiciosTema.texto(context))),
            const SizedBox(height: 8),
            Text(descripcion, textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: _ServiciosTema.secundario(context))),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onActualizar,
              icon: const Icon(Icons.refresh_rounded),
              label: const AdminTranslatedText('Reintentar', 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
