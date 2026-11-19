class PuestoModel {
  final int idPuesto;
  final String nombre;
  final String? descripcion;

  const PuestoModel({
    required this.idPuesto,
    required this.nombre,
    this.descripcion,
  });

  factory PuestoModel.fromJson(Map<String, dynamic> json) {
    final id = json['id_puesto'];
    final parsed = id is num ? id.toInt() : int.tryParse('$id');
    if (parsed == null || parsed <= 0 || json['nombre'] is! String) {
      throw const FormatException('Puesto incompleto.');
    }
    return PuestoModel(
      idPuesto: parsed,
      nombre: (json['nombre'] as String).trim(),
      descripcion: json['descripcion']?.toString(),
    );
  }
}
