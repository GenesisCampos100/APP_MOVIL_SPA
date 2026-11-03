import 'convertidores.dart';

/// Notificación para el usuario. Tipos según el ciclo de vida de una cita:
///   cita_creada      -> "Cita registrada"
///   confirmar_cita   -> "Confirma tu cita" (24 h antes; pide una acción)
///   cita_confirmada  -> "Cita confirmada"
///   cita_cancelada   -> "Cita cancelada" (por no confirmar a tiempo)
///   resena           -> "¿Cómo estuvo tu servicio?" (cuando la cita se completa)
///
/// Tabla actual "notificaciones": id_notificacion INT, id_cita INT,
/// tipo VARCHAR(20), fecha_envio TIMESTAMP.
/// Para esta pantalla hay que pedirle a Mario estas columnas nuevas:
///   id_usuario INT, titulo VARCHAR(100), mensaje TEXT, leida BOOLEAN
/// y que id_cita acepte NULL. "atendida" no es columna: sale del estado
/// de la cita (si ya está confirmada, la notificación ya fue atendida).
class Notificacion {
  static const citaCreada = 'cita_creada';
  static const confirmarCita = 'confirmar_cita';
  static const citaConfirmada = 'cita_confirmada';
  static const citaCancelada = 'cita_cancelada';
  static const resena = 'resena';

  final int id; //                 notificaciones.id_notificacion  INT
  final int? idCita; //            notificaciones.id_cita          INT (puede ser null)
  final String tipo; //            notificaciones.tipo             VARCHAR(20)
  final String titulo; //          (columna nueva)                 VARCHAR(100)
  final String mensaje; //         (columna nueva)                 TEXT
  final DateTime fechaEnvio; //    notificaciones.fecha_envio      TIMESTAMP
  final bool leida; //             (columna nueva)                 BOOLEAN
  final bool atendida; //          derivado del estado de la cita

  const Notificacion({
    required this.id,
    this.idCita,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.fechaEnvio,
    this.leida = false,
    this.atendida = false,
  });

  /// "Confirma tu cita" que todavía no se ha confirmado.
  bool get requiereAccion => tipo == confirmarCita && !atendida;

  Notificacion copyWith({bool? leida, bool? atendida}) => Notificacion(
        id: id,
        idCita: idCita,
        tipo: tipo,
        titulo: titulo,
        mensaje: mensaje,
        fechaEnvio: fechaEnvio,
        leida: leida ?? this.leida,
        atendida: atendida ?? this.atendida,
      );

  factory Notificacion.fromJson(Map<String, dynamic> j) => Notificacion(
        id: aInt(j['id_notificacion']),
        idCita: j['id_cita'] == null ? null : aInt(j['id_cita']),
        tipo: (j['tipo'] ?? '') as String,
        titulo: (j['titulo'] ?? '') as String,
        mensaje: (j['mensaje'] ?? '') as String,
        fechaEnvio: DateTime.parse(j['fecha_envio'].toString()).toLocal(),
        leida: (j['leida'] as bool?) ?? false,
        atendida: (j['atendida'] as bool?) ?? false,
      );
}
