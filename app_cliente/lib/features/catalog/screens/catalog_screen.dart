import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../data/models/servicio.dart';
import '../../../data/repositories/servicios_repository.dart';
import '../../../shared/widgets/servicio_card.dart';

/// Catálogo y categorías (Figura 12, CU-03 y CU-25).
class CatalogScreen extends StatefulWidget {
  final String? categoriaInicial;
  final bool conAtras;
  const CatalogScreen({super.key, this.categoriaInicial, this.conAtras = false});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _repo = ServiciosRepository();
  List<Servicio>? _todos;
  bool _error = false;
  String? _categoria;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _categoria = widget.categoriaInicial;
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final datos = await _repo.obtenerServicios();
      if (!mounted) return;
      setState(() => _todos = datos);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = true);
    }
  }

  List<Servicio> get _filtrados => _todos!
      .where((s) =>
          (_categoria == null || s.categoria == _categoria) &&
          s.nombre.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.conAtras ? AppBar(title: Text(context.t('catalogo.titulo'))) : null,
      body: SafeArea(child: _contenido()),
    );
  }

  Widget _contenido() {
    if (_error) return Center(child: Text(context.t('catalogo.error')));
    if (_todos == null) return const Center(child: CircularProgressIndicator());

    final lista = _filtrados;
    final a = context.aura;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: context.t('catalogo.buscar'),
              hintStyle: TextStyle(color: a.textoSecundario),
              isDense: true,
              suffixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final c in ServiciosRepository.categorias)
                ChoiceChip(
                  label: Text(context.tOr('cat.$c', c)),
                  selected: c == _categoria,
                  showCheckmark: false,
                  selectedColor: a.boton,
                  backgroundColor: a.superficie,
                  labelStyle: TextStyle(
                    color: c == _categoria ? a.textoBoton : a.texto,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: StadiumBorder(side: BorderSide(color: a.texto)),
                  onSelected: (_) =>
                      setState(() => _categoria = c == _categoria ? null : c),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: lista.isEmpty
                ? Center(child: Text(context.t('catalogo.vacio')))
                : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: lista.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemBuilder: (context, i) => ServicioCard(
                      servicio: lista[i],
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.detalle,
                        arguments: lista[i],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
