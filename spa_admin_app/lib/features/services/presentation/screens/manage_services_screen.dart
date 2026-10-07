import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/constants/app_colors.dart';
import 'package:spa_admin_app/features/services/data/models/service_model.dart';
import 'package:spa_admin_app/features/services/presentation/widgets/service_form_dialog.dart';
import 'package:spa_admin_app/features/services/presentation/widgets/service_delete_dialog.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final List<ServiceModel> _services = [
    ServiceModel(
      idServicio: '1',
      nombre: 'Masaje relajante',
      descripcion: 'Tratamiento corporal con aceites esenciales',
      duracion: '60 minutos',
      precio: 650.00,
      categoria: 'Masajes',
      estado: true,
    ),
  ];

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredServices = _services
        .where((s) => s.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        s.categoria.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Gestionar servicios',
          style: TextStyle(color: Colors.black, fontSize: 26, fontFamily: 'Georgia', fontWeight: FontWeight.w400),
        ),
      ),
      body: Column(
        children: [
          // Botón rosa '+' para crear servicio
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryPink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => ServiceFormDialog(
                        onSave: (newService) {
                          setState(() => _services.add(newService));
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Campo de búsqueda
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o puesto...',
                suffixIcon: const Icon(Icons.search, color: Colors.black),
                filled: true,
                fillColor: const Color(0xFFEFEFEF),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Lista de tarjetas
          Expanded(
            child: ListView.builder(
              itemCount: filteredServices.length,
              itemBuilder: (context, index) {
                final service = filteredServices[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${service.nombre}, ${service.duracion}, \$${service.precio.toStringAsFixed(2)}, ${service.categoria}, ${service.estado ? "Activo" : "Inactivo"}',
                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Botón Eliminar
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFEFEFEF),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => ServiceDeleteDialog(
                                  service: service,
                                  onDeleteConfirmed: () {
                                    setState(() => _services.removeWhere((s) => s.idServicio == service.idServicio));
                                  },
                                ),
                              );
                            },
                            child: const Text('Eliminar', style: TextStyle(color: Colors.black87, fontSize: 12)),
                          ),
                          // Ícono Editar
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.black),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => ServiceFormDialog(
                                  serviceToEdit: service,
                                  onSave: (updatedService) {
                                    setState(() {
                                      final i = _services.indexWhere((s) => s.idServicio == updatedService.idServicio);
                                      if (i != -1) _services[i] = updatedService;
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
