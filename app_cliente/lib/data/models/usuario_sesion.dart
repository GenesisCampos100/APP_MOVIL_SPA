/// Usuario con sesión iniciada. Tipos alineados con las tablas
/// "usuarios" y "clientes" de PostgreSQL.
class UsuarioSesion {
  final int id; //                    usuarios.id_usuario   INT
  final String correo; //             usuarios.correo       VARCHAR(100)
  final String? foto; //              usuarios.foto         TEXT (URL)
  final String rol; //                usuarios.rol          VARCHAR(20)
  final String nombre; //             clientes.nombre       VARCHAR(100)
  final String apellido; //           clientes.apellido_p   VARCHAR(100)
  final String? apellidoMaterno; //   clientes.apellido_m   VARCHAR(100)
  final String? telefono; //          clientes.telefono     VARCHAR(15)

  const UsuarioSesion({
    this.id = 0,
    required this.correo,
    required this.nombre,
    required this.apellido,
    this.apellidoMaterno,
    this.foto,
    this.rol = 'cliente',
    this.telefono,
  });

  factory UsuarioSesion.fromJson(Map<String, dynamic> j) => UsuarioSesion(
        id: (j['id_usuario'] as num?)?.toInt() ?? 0,
        correo: j['correo'] as String,
        nombre: (j['nombre'] ?? '') as String,
        apellido: (j['apellido_p'] ?? '') as String,
        apellidoMaterno: j['apellido_m'] as String?,
        foto: j['foto'] as String?,
        rol: (j['rol'] ?? 'cliente') as String,
        telefono: j['telefono'] as String?,
      );

  UsuarioSesion copyWith({String? telefono}) => UsuarioSesion(
        id: id,
        correo: correo,
        nombre: nombre,
        apellido: apellido,
        apellidoMaterno: apellidoMaterno,
        foto: foto,
        rol: rol,
        telefono: telefono ?? this.telefono,
      );

  String get nombreCompleto => [nombre, apellido, apellidoMaterno]
      .whereType<String>()
      .where((e) => e.isNotEmpty)
      .join(' ');

  String get inicial => nombre.isEmpty ? '?' : nombre[0].toUpperCase();
}
