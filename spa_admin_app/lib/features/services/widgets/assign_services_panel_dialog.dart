import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/theme/app_colors.dart';
import 'package:spa_admin_app/core/theme/app_text_styles.dart';
import 'package:spa_admin_app/data/models/employee_model.dart';
import 'package:spa_admin_app/data/models/service_model.dart';
import 'package:spa_admin_app/data/services/api_exception.dart';

class AssignServicesPanelDialog extends StatefulWidget {
  final EmployeeModel employee;
  final List<ServiceModel> allServices;
  final Set<String> initiallyAssignedServiceIds;
  final Future<void> Function(Set<String>) onSave;

  const AssignServicesPanelDialog({
    super.key,
    required this.employee,
    required this.allServices,
    required this.initiallyAssignedServiceIds,
    required this.onSave,
  });

  @override
  State<AssignServicesPanelDialog> createState() =>
      _AssignServicesPanelDialogState();
}

class _AssignServicesPanelDialogState extends State<AssignServicesPanelDialog> {
  late Set<String> _assignedIds;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _assignedIds = Set<String>.of(widget.initiallyAssignedServiceIds);
  }

  bool get _hayCambios =>
      !setEquals(_assignedIds, widget.initiallyAssignedServiceIds);

  Future<void> _guardar() async {
    if (_guardando || !_hayCambios) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await widget.onSave(Set<String>.of(_assignedIds));
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudieron guardar los cambios. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Widget _servicio(ServiceModel servicio) {
    final seleccionado = _assignedIds.contains(servicio.idServicio);
    final editable = !_guardando && (servicio.estado || seleccionado);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: seleccionado ? AppColors.primaryPinkSoft : Colors.white,
        border: Border.all(
          color: seleccionado ? AppColors.primaryPink : AppColors.cardBorder,
          width: seleccionado ? 1.25 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: CheckboxListTile(
        value: seleccionado,
        controlAffinity: ListTileControlAffinity.trailing,
        activeColor: AppColors.primaryPink,
        checkColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(13, 5, 7, 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onChanged: editable
            ? (marcado) {
                setState(() {
                  if (marcado == true) {
                    _assignedIds.add(servicio.idServicio);
                  } else {
                    _assignedIds.remove(servicio.idServicio);
                  }
                  _error = null;
                });
              }
            : null,
        title: Text(
          servicio.nombre,
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${servicio.duracion} · \$${servicio.precio.toStringAsFixed(2)} MXN',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
              if (!servicio.estado)
                const Text(
                  'Servicio inactivo',
                  style: TextStyle(fontSize: 11, color: Color(0xFFA55D5D)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grupos = <String, List<ServiceModel>>{};
    for (final servicio in widget.allServices) {
      final categoria = servicio.categoria.trim().isEmpty
          ? 'Sin categoría'
          : servicio.categoria;
      grupos.putIfAbsent(categoria, () => []).add(servicio);
    }
    for (final servicios in grupos.values) {
      servicios.sort((a, b) => a.nombre.compareTo(b.nombre));
    }
    final categorias = grupos.keys.toList()..sort();
    final total = widget.allServices.length;
    final inicial = widget.employee.nombreCompleto.trim().isEmpty
        ? 'E'
        : widget.employee.nombreCompleto.trim()[0].toUpperCase();

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SizedBox(
        width: 520,
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPinkSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primaryPink,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Asignar servicios',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Selecciona los tratamientos que puede realizar',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: _guardando ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.fieldBackground,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: AppColors.primaryPinkSoft,
                      child: Text(
                        inicial,
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.primaryPink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.employee.nombreCompleto,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.employee.puesto,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPinkSoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_assignedIds.length} seleccionados',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: widget.allServices.isEmpty
                  ? const Center(child: Text('No hay servicios disponibles.'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      children: [
                        Text(
                          'Catálogo de servicios ($total)',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final categoria in categorias) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.category_outlined,
                                size: 16,
                                color: AppColors.primaryPink,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  categoria,
                                  style: AppTextStyles.subtitle.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Text(
                                '${grupos[categoria]!.length}',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          for (final servicio in grupos[categoria]!) _servicio(servicio),
                          const SizedBox(height: 10),
                        ],
                        const Padding(
                          padding: EdgeInsets.only(top: 3, bottom: 4),
                          child: Text(
                            'Los servicios inactivos no se pueden asignar a nuevos especialistas.',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFAD405A), fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textDark,
                            side: const BorderSide(color: AppColors.cardBorder),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: const Text('Volver'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: (_guardando || !_hayCambios) ? null : _guardar,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryPink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          icon: _guardando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 18),
                          label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
