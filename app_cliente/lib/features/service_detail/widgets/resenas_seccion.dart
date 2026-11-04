import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formato.dart';
import '../../../data/models/resena.dart';
import '../../../data/repositories/resenas_repository.dart';

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
  static const _filtros = ['Todas', 'Servicio', 'Profesional'];
  String _filtro = 'Todas';
  String? _empleado; // empleado elegido en el filtro "Profesional"

  final _repo = ResenasRepository();
  late final Future<List<Resena>> _futuro = _repo.obtenerDeServicio(widget.idServicio);

  _Modo get _modo {
    if (_filtro == 'Servicio') return _Modo.servicio;
    if (_filtro == 'Profesional') return _Modo.profesional;
    return _Modo.todas;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Resena>>(
      future: _futuro,
      builder: (context, snap) {
        final resenas = snap.data ?? const <Resena>[];
        final cargando = !snap.hasData && !snap.hasError;
        final promedio = resenas.isEmpty
            ? 0.0
            : resenas.fold<int>(0, (suma, r) => suma + r.calificacionServicio) / resenas.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Reseñas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (resenas.isNotEmpty) ...[
                  const Icon(Icons.star, size: 20, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(promedio.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  Text('(${resenas.length})',
                      style: const TextStyle(fontSize: 11, color: AppColors.gris)),
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
                        color: f == _filtro ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: f == _filtro ? Colors.black : Colors.black26),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: f == _filtro ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            ..._cuerpo(cargando, resenas),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  List<Widget> _vacio() => const [
        SizedBox(height: 16),
        Center(
          child: Text('No hay reseñas encontradas',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        SizedBox(height: 6),
        Center(
          child: Text('Este servicio aún no tiene reseñas.',
              style: TextStyle(fontSize: 12, color: AppColors.gris)),
        ),
      ];

  List<Widget> _cuerpo(bool cargando, List<Resena> resenas) {
    if (cargando) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ];
    }
    if (resenas.isEmpty) return _vacio();

    final modo = _modo;

    if (modo == _Modo.profesional) {
      // Empleados que tienen reseñas en este servicio (sin repetir).
      final empleados = resenas
          .map((r) => r.empleadoNombre)
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList();
      if (empleados.isEmpty) return _vacio();

      final elegido = empleados.contains(_empleado) ? _empleado! : empleados.first;
      final delEmpleado = resenas.where((r) => r.empleadoNombre == elegido).toList();
      return [
        _selectorEmpleado(empleados, elegido, delEmpleado),
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

  Widget _selectorEmpleado(List<String> empleados, String elegido, List<Resena> suyas) {
    final promedio = suyas.isEmpty
        ? 0.0
        : suyas.fold<int>(0, (suma, r) => suma + r.calificacionEmpleado) / suyas.length;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black54),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: elegido,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
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
            _Estrellas(promedio.round(), size: 16),
            const SizedBox(height: 2),
            Text(
              '(${suyas.length}) ${promedio.toStringAsFixed(1)}',
              style: const TextStyle(fontSize: 11, color: AppColors.gris),
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
                  _Estrellas(estrellas),
                ],
              ),
              const SizedBox(height: 4),
              if (r.comentario != null && r.comentario!.isNotEmpty)
                Text(r.comentario!, style: const TextStyle(fontSize: 12, height: 1.3)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(r.servicioCategoria,
                      style: const TextStyle(fontSize: 10, color: AppColors.gris)),
                  if (modo != _Modo.servicio) ...[
                    const SizedBox(width: 8),
                    Text(r.empleadoNombre,
                        style: const TextStyle(fontSize: 10, color: AppColors.rosaFuerte)),
                  ],
                  const Spacer(),
                  Text(haceCuanto(r.fecha),
                      style: const TextStyle(fontSize: 10, color: AppColors.gris)),
                ],
              ),
              if (modo == _Modo.todas) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MiniCalificacion('Servicio', r.calificacionServicio),
                    const SizedBox(width: 14),
                    _MiniCalificacion('Profesional', r.calificacionEmpleado),
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
        Text(etiqueta, style: const TextStyle(fontSize: 10, color: AppColors.gris)),
        const SizedBox(width: 4),
        _Estrellas(cantidad, size: 10),
      ],
    );
  }
}

class _Estrellas extends StatelessWidget {
  final int cantidad;
  final double size;
  const _Estrellas(this.cantidad, {this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(Icons.star_rounded, size: size, color: i <= cantidad ? Colors.amber : Colors.black12),
      ],
    );
  }
}
