import 'package:flutter/material.dart';
import '../../../core/i18n/textos.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/aura_colores.dart';
import '../../../core/utils/formato.dart';
import '../../../data/models/resena.dart';
import '../../../data/models/resenas_servicio.dart';
import '../../../data/repositories/servicios_repository.dart';

enum _Modo { todas, servicio, profesional }

/// Sección de reseñas del detalle del servicio.
///
/// Filtros:
///  - Todas: todas las reseñas, con la calificación del servicio y la del
///    profesional en cada una.
///  - Servicio: solo la calificación del servicio.
///  - Profesional: se elige un empleado y se ven sus reseñas con su promedio.
///
/// Sin reseñas: solo título, filtros y "No hay reseñas encontradas".
class ResenasSeccion extends StatefulWidget {
  final int idServicio;
  const ResenasSeccion({super.key, required this.idServicio});

  @override
  State<ResenasSeccion> createState() => _ResenasSeccionState();
}

class _ResenasSeccionState extends State<ResenasSeccion> {
  static const _filtros = [_Modo.todas, _Modo.servicio, _Modo.profesional];
  _Modo _filtro = _Modo.todas;
  String? _empleado; // empleado elegido en el filtro "Profesional"

  final _repo = ServiciosRepository();

  late final Future<ResenasServicio> _futuro =
      _repo.obtenerResenasPorServicio(widget.idServicio);

  _Modo get _modo => _filtro;

  String _nombreFiltro(BuildContext context, _Modo m) {
    switch (m) {
      case _Modo.servicio:
        return context.t('resenas.servicio');
      case _Modo.profesional:
        return context.t('resenas.profesional');
      case _Modo.todas:
        return context.t('resenas.todas');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ResenasServicio>(
      future: _futuro,
      builder: (context, snap) {
        final a = context.aura;
        final datos = snap.data;

        final resenas = datos?.resenas ?? const <Resena>[];
        final cargando = !snap.hasData && !snap.hasError;

        final promedio = datos?.promedioServicio ?? 0.0;
        final total = datos?.totalResenas ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(context.t('resenas.titulo'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (total > 0) ...[
                  const Icon(Icons.star, size: 20, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    promedio.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($total)',
                    style: TextStyle(
                      fontSize: 11,
                      color: a.textoSecundario,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final f in _filtros)
                  GestureDetector(
                    onTap: () => setState(() => _filtro = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                      decoration: BoxDecoration(
                        color: f == _filtro ? a.boton : a.superficie,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: f == _filtro ? a.boton : a.borde),
                      ),
                      child: Text(
                        _nombreFiltro(context, f),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: f == _filtro ? a.textoBoton : a.texto,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (snap.hasError)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No se pudieron cargar las reseñas. Intenta nuevamente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: a.textoSecundario,
                    ),
                  ),
                ),
              )
            else
              ..._cuerpo(context, cargando, resenas),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  List<Widget> _vacio(BuildContext context) => [
        const SizedBox(height: 16),
        Center(
          child: Text(context.t('resenas.vacio_titulo'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(context.t('resenas.vacio_msg'),
              style: TextStyle(fontSize: 12, color: context.aura.textoSecundario)),
        ),
      ];

  List<Widget> _cuerpo(BuildContext context, bool cargando, List<Resena> resenas) {
    if (cargando) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ];
    }
    if (resenas.isEmpty) return _vacio(context);

    final modo = _modo;

    if (modo == _Modo.profesional) {
      // Empleados que tienen reseñas en este servicio (sin repetir).
      final empleados = resenas
          .map((r) => r.empleadoNombre)
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();
      if (empleados.isEmpty) return _vacio(context);

      final elegido = empleados.contains(_empleado) ? _empleado! : empleados.first;
      final delEmpleado = resenas.where((r) => r.empleadoNombre == elegido).toList();
      return [
        _selectorEmpleado(context, empleados, elegido, delEmpleado),
        const SizedBox(height: 18),
        for (final r in delEmpleado) ...[
          _TarjetaResena(resena: r, modo: modo),
          const SizedBox(height: 18),
        ],
      ];
    }

    return [
      for (final r in resenas) ...[
        _TarjetaResena(resena: r, modo: modo),
        const SizedBox(height: 18),
      ],
    ];
  }

  Widget _selectorEmpleado(BuildContext context, List<String> empleados, String elegido, List<Resena> suyas) {
    final promedio = suyas.isEmpty
        ? 0.0
        : suyas.fold<int>(0, (suma, r) => suma + r.calificacionEmpleado) / suyas.length;
    final a = context.aura;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: a.textoSecundario),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: elegido,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: a.superficie,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: a.texto),
              items: [
                for (final e in empleados) DropdownMenuItem(value: e, child: Text(e)),
              ],
              onChanged: (v) => setState(() => _empleado = v),
            ),
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Estrellas(promedio.round(), size: 16, vacia: a.borde),
            const SizedBox(height: 2),
            Text(
              '(${suyas.length}) ${promedio.toStringAsFixed(1)}',
              style: TextStyle(fontSize: 11, color: a.textoSecundario),
            ),
          ],
        ),
      ],
    );
  }
}

class _TarjetaResena extends StatelessWidget {
  final Resena resena;
  final _Modo modo;
  const _TarjetaResena({required this.resena, required this.modo});

  @override
  Widget build(BuildContext context) {
    final r = resena;
    final a = context.aura;
    // En "Profesional" se muestra la calificación del empleado;
    // en "Todas" y "Servicio", la del servicio.
    final estrellas = modo == _Modo.profesional ? r.calificacionEmpleado : r.calificacionServicio;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.rosa,
          child: Text(
            r.autor.isEmpty ? '?' : r.autor[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(r.autor,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                  _Estrellas(estrellas, vacia: a.borde),
                ],
              ),
              const SizedBox(height: 4),
              if (r.comentario != null && r.comentario!.isNotEmpty)
                Text(r.comentario!, style: const TextStyle(fontSize: 12, height: 1.3)),

              if (r.aspectos.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final aspecto in r.aspectos)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: a.rosaSuave,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          context.tOr('rev.asp.$aspecto', aspecto),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.rosaFuerte,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(context.tOr('cat.${r.servicioCategoria}', r.servicioCategoria),
                      style: TextStyle(fontSize: 10, color: a.textoSecundario)),
                  if (modo != _Modo.servicio) ...[
                    const SizedBox(width: 8),
                    Text(r.empleadoNombre,
                        style: const TextStyle(fontSize: 10, color: AppColors.rosaFuerte)),
                  ],
                  const Spacer(),
                  Text(haceCuanto(r.fecha),
                      style: TextStyle(fontSize: 10, color: a.textoSecundario)),
                ],
              ),
              if (modo == _Modo.todas) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MiniCalificacion(context.t('resenas.servicio'), r.calificacionServicio),
                    const SizedBox(width: 14),
                    _MiniCalificacion(context.t('resenas.profesional'), r.calificacionEmpleado),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniCalificacion extends StatelessWidget {
  final String etiqueta;
  final int cantidad;
  const _MiniCalificacion(this.etiqueta, this.cantidad);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etiqueta, style: TextStyle(fontSize: 10, color: context.aura.textoSecundario)),
        const SizedBox(width: 4),
        _Estrellas(cantidad, size: 10, vacia: context.aura.borde),
      ],
    );
  }
}

class _Estrellas extends StatelessWidget {
  final int cantidad;
  final double size;
  final Color vacia; // color de las estrellas sin llenar (cambia con el tema)
  const _Estrellas(this.cantidad, {this.size = 14, required this.vacia});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(Icons.star_rounded, size: size, color: i <= cantidad ? Colors.amber : vacia),
      ],
    );
  }
}
