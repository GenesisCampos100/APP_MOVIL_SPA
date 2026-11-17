import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/aura_colores.dart';
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
  static const _aspectos = ['atencion', 'limpieza', 'resultado', 'puntualidad', 'instalaciones'];

  int _calificacion = 0;
  final Set<String> _seleccionados = {};

  @override
  Widget build(BuildContext context) {
    final c = widget.cita;
    final ac = context.aura;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          Text(context.t('rev.titulo'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ac.superficie,
              border: Border.all(color: ac.borde),
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
                        context.t('rev.con', {
                          'nombre': c.empleadoNombre.isEmpty
                              ? context.t('citas.empleado_asignado')
                              : c.empleadoNombre,
                          'fecha': '${fechaCorta(c.fecha)}, ${hora12(c.horaInicio)}',
                        }),
                        style: TextStyle(fontSize: 11, color: ac.textoSecundario),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(context.t('rev.pregunta'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
                    color: i <= _calificacion ? Colors.amber : ac.borde,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(context.t('rev.aspectos'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              for (final a in _aspectos)
                FilterChip(
                  label: Text(context.t('rev.asp.$a')),
                  selected: _seleccionados.contains(a),
                  showCheckmark: false,
                  selectedColor: ac.rosaSuave,
                  backgroundColor: ac.superficie,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: _seleccionados.contains(a) ? AppColors.rosaFuerte : ac.texto,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _seleccionados.contains(a) ? AppColors.rosaFuerte : ac.bordeCampo,
                    ),
                  ),
                  onSelected: (v) => setState(() {
                    v ? _seleccionados.add(a) : _seleccionados.remove(a);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(context.t('rev.mas'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextField(
            maxLines: 5,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: context.t('rev.hint'),
              hintStyle: TextStyle(fontSize: 12, color: ac.textoSecundario),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: ac.bordeCampo),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: ac.bordeCampo),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: ac.texto),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AuthBoton(
            texto: context.t('rev.publicar'),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.t('comun.proximamente',
                    {'que': context.t('rev.publicar')})),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
