
import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../core/utils/formato.dart';
import '../../../core/utils/errores.dart';
import '../../../data/models/cita.dart';
import '../../../data/repositories/servicios_repository.dart';
import '../../../shared/widgets/servicio_visual.dart';
import '../../auth/widgets/auth_widgets.dart';

class WriteReviewScreen extends StatefulWidget {
  final Cita cita;

  const WriteReviewScreen({super.key, required this.cita});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  static const _aspectos = [
    'atencion',
    'limpieza',
    'resultado',
    'puntualidad',
    'instalaciones',
  ];

  final ServiciosRepository _serviciosRepository = ServiciosRepository();
  final TextEditingController _comentarioController =
      TextEditingController();

  int _calificacion = 0;
  bool _publicando = false;

  final Set<String> _seleccionados = {};

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _publicarResena() async {
    if (_publicando) return;

    if (_calificacion == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una calificación de 1 a 5 estrellas.'),
        ),
      );
      return;
    }

    setState(() => _publicando = true);

    try {
      await _serviciosRepository.publicarResena(
        idServicio: widget.cita.idServicio,
        idCita: widget.cita.id,
        calificacion: _calificacion,
        aspectos: _seleccionados.toList(),
        comentario: _comentarioController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Tu reseña se publicó correctamente!'),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(textoError(context, e)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _publicando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cita;
    final ac = context.aura;

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          Text(
            context.t('rev.titulo'),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
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
                      Text(
                        c.servicioNombre,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.t('rev.con', {
                          'nombre': c.empleadoNombre.isEmpty
                              ? context.t('citas.empleado_asignado')
                              : c.empleadoNombre,
                          'fecha':
                              '${fechaCorta(c.fecha)}, ${hora12(c.horaInicio)}',
                        }),
                        style: TextStyle(
                          fontSize: 11,
                          color: ac.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          Center(
            child: Text(
              context.t('rev.pregunta'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 1; i <= 5; i++)
                GestureDetector(
                  onTap: _publicando
                      ? null
                      : () => setState(() => _calificacion = i),
                  child: Icon(
                    Icons.star_rounded,
                    size: 52,
                    color: i <= _calificacion
                        ? Colors.amber
                        : ac.borde,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            context.t('rev.aspectos'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

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
                    color: _seleccionados.contains(a)
                        ? AppColors.rosaFuerte
                        : ac.texto,
                  ),
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _seleccionados.contains(a)
                          ? AppColors.rosaFuerte
                          : ac.bordeCampo,
                    ),
                  ),
                  onSelected: _publicando
                      ? null
                      : (v) {
                          setState(() {
                            v
                                ? _seleccionados.add(a)
                                : _seleccionados.remove(a);
                          });
                        },
                ),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            context.t('rev.mas'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: _comentarioController,
            enabled: !_publicando,
            maxLines: 5,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: context.t('rev.hint'),
              hintStyle: TextStyle(
                fontSize: 12,
                color: ac.textoSecundario,
              ),
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
            texto: _publicando
                ? 'Publicando...'
                : context.t('rev.publicar'),
            onPressed: _publicarResena,
          ),
        ],
      ),
    );
  }
}
