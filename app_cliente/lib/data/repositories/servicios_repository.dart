import '../models/servicio.dart';

/// Hoy devuelve datos de prueba (mock). Cuando Vanessa tenga GET /servicios,
/// solo se cambia el contenido de obtenerServicios() (ver Servicio.fromJson);
/// las pantallas no cambian.
class ServiciosRepository {
  static const categorias = [
    'Corporal',
    'Facial',
    'Manicure',
    'Aromaterapia',
    'Pedicure',
  ];

  Future<List<Servicio>> obtenerServicios() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mock;
  }

  static const _mock = [
    Servicio(id: 1, idCategoria: 1, nombre: 'Masaje relajante', categoria: 'Corporal', descripcion: 'Masaje corporal de relajación.', precio: 500, minutos: 45, rating: 4.5, destacado: true),
    Servicio(id: 2, idCategoria: 2, nombre: 'Facial hidratante', categoria: 'Facial', descripcion: 'Limpieza e hidratación profunda del rostro.', precio: 900, minutos: 45, rating: 4.5, destacado: true),
    Servicio(id: 3, idCategoria: 3, nombre: 'Manicure clásica', categoria: 'Manicure', descripcion: 'Cuidado y esmaltado de uñas de las manos.', precio: 500, minutos: 45, rating: 4.5),
    Servicio(id: 4, idCategoria: 4, nombre: 'Ritual de relajación', categoria: 'Aromaterapia', descripcion: 'Sesión de aromaterapia para relajarte.', precio: 800, minutos: 60, rating: 4.6),
    Servicio(id: 5, idCategoria: 5, nombre: 'Pedicure Spa', categoria: 'Pedicure', descripcion: 'Cuidado y masaje de pies.', precio: 600, minutos: 50, rating: 4.8),
  ];
}
