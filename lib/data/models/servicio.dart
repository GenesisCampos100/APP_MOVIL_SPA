class Servicio {
  final int id;
  final String nombre;
  final String categoria;
  final double precio;
  final int minutos;
  final double rating;
  final bool destacado;

  const Servicio({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.minutos,
    required this.rating,
    this.destacado = false,
  });

  String get duracionTexto => minutos == 60 ? '1 hora' : '$minutos min';
  String get precioTexto => '\$${precio.toStringAsFixed(0)}';
}
