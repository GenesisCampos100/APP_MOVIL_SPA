
import 'resena.dart';

class ResenasServicio {
  final List<Resena> resenas;
  final int totalResenas;
  final double promedioServicio;
  final double promedioEmpleado;

  const ResenasServicio({
    required this.resenas,
    required this.totalResenas,
    required this.promedioServicio,
    required this.promedioEmpleado,
  });

  factory ResenasServicio.fromJson(Map<String, dynamic> json) {
    final resumen = Map<String, dynamic>.from(
      json['resumen'] ?? {},
    );

    final lista = json['resenas'] as List? ?? [];

    return ResenasServicio(
      resenas: lista
          .map(
            (item) => Resena.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      totalResenas:
          (resumen['total_resenas'] as num?)?.toInt() ?? 0,
      promedioServicio:
          (resumen['promedio_servicio'] as num?)?.toDouble() ?? 0,
      promedioEmpleado:
          (resumen['promedio_empleado'] as num?)?.toDouble() ?? 0,
    );
  }
}
