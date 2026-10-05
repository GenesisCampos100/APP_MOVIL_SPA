import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formato.dart';
import '../../../data/models/cita.dart';
import '../../../shared/widgets/servicio_visual.dart';
import '../../auth/widgets/auth_widgets.dart';

/// "Escribir reseña": solo diseño por ahora. Se puede interactuar
/// (estrellas, aspectos, texto), pero "Publicar reseña" aún no guarda nada.
class WriteReviewScreen extends StatefulWidget {
  final Cita cita;
  const WriteReviewScreen({super.key, required this.cita});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  static const _aspectos = ['Atención', 'Limpieza', 'Resultado', 'Puntualidad', 'Instalaciones'];

  int _calificacion = 0;
  final Set<String> _seleccionados = {};

  @override
  Widget build(BuildContext context) {
    final c = widget.cita;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          const Text('Escribir reseña',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE3E3E3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ServicioThumb(
                  categoria: c.servicioCategoria,
                  width: 56,
                  height: 56,
                  radius: 8,
                  iconSize: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.servicioNombre,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        'Con ${c.empleadoNombre} - ${c.fecha.day} ${fechaCorta(c.fecha).split(' ').last}, ${hora12(c.horaInicio)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.gris),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Center(
            child: Text('¿Cómo calificarías tu experiencia?',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: () => setState(() => _calificacion = i),
                  child: Icon(
                    Icons.star_rounded,
                    size: 52,
                    color: i <= _calificacion ? Colors.amber : Colors.black12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Aspectos destacados',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              for (final a in _aspectos)
                FilterChip(
                  label: Text(a),
                  selected: _seleccionados.contains(a),
                  showCheckmark: false,
                  selectedColor: AppColors.rosaSuave,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: _seleccionados.contains(a) ? AppColors.rosaFuerte : Colors.black87,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _seleccionados.contains(a) ? AppColors.rosaFuerte : Colors.black26,
                    ),
                  ),
                  onSelected: (v) => setState(() {
                    v ? _seleccionados.add(a) : _seleccionados.remove(a);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Cuéntanos más',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(
            maxLines: 5,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Describe tu experiencia, qué te gustó y qué podríamos mejorar...',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.gris),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black26),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black26),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AuthBoton(
            texto: 'Publicar reseña',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Publicar reseña: próximamente')),
            ),
          ),
        ],
      ),
    );
  }
}
