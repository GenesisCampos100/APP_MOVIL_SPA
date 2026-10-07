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

  // rating 0 = el servicio todavía no tiene reseñas (no se muestra la estrella).
  // imagen: ruta en assets/images/ (o una URL http). Si el archivo no existe,
  // la app muestra el degradado con ícono.
  static const _mock = [
    Servicio(
      id: 1, idCategoria: 1, nombre: 'Masaje relajante', categoria: 'Corporal',
      descripcion: 'Disfruta de una experiencia de relajación total con este masaje corporal completo. Nuestros terapeutas certificados utilizan técnicas suaves y aceites esenciales para aliviar la tensión muscular, reducir el estrés y restaurar el equilibrio de tu cuerpo y mente. Una sesión ideal para desconectar y revitalizarte.',
      precio: 500, minutos: 45, rating: 4.7, destacado: true,
      imagen: 'assets/images/masaje_relajante.jpeg',
    ),
    Servicio(
      id: 2, idCategoria: 2, nombre: 'Facial hidratante', categoria: 'Facial',
      descripcion: 'Tratamiento facial que limpia en profundidad y devuelve la hidratación a tu piel. Incluye exfoliación suave, mascarilla nutritiva y un masaje relajante para dejar tu rostro luminoso, fresco y renovado desde la primera sesión.',
      precio: 900, minutos: 45, destacado: true,
      imagen: 'assets/images/facial_hidratante.jpg',
    ),
    Servicio(
      id: 3, idCategoria: 3, nombre: 'Manicure clásica', categoria: 'Manicure',
      descripcion: 'Cuidado completo de tus manos y uñas: limado, cuidado de cutícula, hidratación y esmaltado a tu elección. Un servicio sencillo para lucir manos impecables en cualquier ocasión.',
      precio: 500, minutos: 45,
      imagen: 'assets/images/manicure_clasica.jpg',
    ),
    Servicio(
      id: 4, idCategoria: 4, nombre: 'Ritual de relajación', categoria: 'Aromaterapia',
      descripcion: 'Sesión de aromaterapia con aceites esenciales y música suave para calmar la mente y liberar el estrés. Un momento de pausa pensado para que te vayas con una sensación profunda de calma y bienestar.',
      precio: 800, minutos: 60,
      imagen: 'assets/images/ritual_relajacion.jpg',
    ),
    Servicio(
      id: 5, idCategoria: 5, nombre: 'Pedicure Spa', categoria: 'Pedicure',
      descripcion: 'Tratamiento completo para tus pies con baño relajante, exfoliación, cuidado de uñas e hidratación profunda, junto con un masaje que alivia el cansancio. Deja tus pies suaves, cuidados y descansados.',
      precio: 600, minutos: 50,
      imagen: 'assets/images/pedicure_spa.jpg',
    ),
  ];
}
