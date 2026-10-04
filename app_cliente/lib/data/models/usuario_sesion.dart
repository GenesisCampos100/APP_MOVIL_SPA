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

  const UsuarioSesion({
    this.id = 0,
    required this.correo,
    required this.nombre,
    required this.apellido,
    this.apellidoMaterno,
    this.foto,
    this.rol = 'cliente',
  });

  factory UsuarioSesion.fromJson(Map<String, dynamic> j) => UsuarioSesion(
        id: (j['id_usuario'] as num?)?.toInt() ?? 0,
        correo: j['correo'] as String,
        nombre: (j['nombre'] ?? '') as String,
        apellido: (j['apellido_p'] ?? '') as String,
        apellidoMaterno: j['apellido_m'] as String?,
        foto: j['foto'] as String?,
        rol: (j['rol'] ?? 'cliente') as String,
      );

  String get nombreCompleto => [nombre, apellido, apellidoMaterno]
      .whereType<String>()
      .where((e) => e.isNotEmpty)
      .join(' ');

  String get inicial => nombre.isEmpty ? '?' : nombre[0].toUpperCase();
}
