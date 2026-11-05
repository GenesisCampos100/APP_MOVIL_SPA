
class PositionModel {
  final int idPuesto;
  final String nombre;
  final String? descripcion;

  const PositionModel({
    required this.idPuesto,
    required this.nombre,
    this.descripcion,
  });

  factory PositionModel.fromJson(Map<String, dynamic> json) {
    return PositionModel(
      idPuesto: (json['id_puesto'] as num).toInt(),
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_puesto': idPuesto,
      'nombre': nombre,
      'descripcion': descripcion,
    };
  }
}
  