class EmployeeModel {
  // Campos principales en español de la base de datos (EMPLEADOS + USUARIOS + PUESTOS)
  final String idEmpleado; // id_empleado (PK)
  final String? idUsuario; // id_usuario (FK)
  final String? idPuesto; // id_puesto (FK)
  String nombreCompleto; // nombre, apellido_p, apellido_m
  final String nombre;
  final String apellidoP;
  final String apellidoM;
  String telefono; // telefono
  String correo; // correo (tabla USUARIOS)
  String puesto; // puesto / rol (tabla PUESTOS / USUARIOS)
  bool estado; // estado (tabla USUARIOS)
  String? foto; // foto (tabla USUARIOS)

  EmployeeModel({
    String? idEmpleado,
    String? id,
    this.idUsuario,
    this.idPuesto,
    String? nombreCompleto,
    this.nombre = '',
    this.apellidoP = '',
    this.apellidoM = '',
    String? fullName,
    String? telefono,
    String? phone,
    String? correo,
    String? email,
    String? puesto,
    String? role,
    bool? estado,
    bool? isActive,
    String? foto,
    String? avatarUrl,
  })  : idEmpleado = idEmpleado ?? id ?? '',
        nombreCompleto = nombreCompleto ?? fullName ?? '',
        telefono = telefono ?? phone ?? '',
        correo = correo ?? email ?? '',
        puesto = puesto ?? role ?? '',
        estado = estado ?? isActive ?? true,
        foto = foto ?? avatarUrl;

  /// Mapea las columnas devueltas por la API administrativa.
  /// No infiere el estado: se obtiene de la cuenta en USUARIOS.
  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final id = json['id_empleado'];
    final nombre = (json['nombre'] ?? '').toString().trim();
    final paterno = (json['apellido_p'] ?? '').toString().trim();
    final materno = (json['apellido_m'] ?? '').toString().trim();
    final completo = [nombre, paterno, materno]
        .where((parte) => parte.isNotEmpty)
        .join(' ');
    final activo = json['estado'];

    return EmployeeModel(
      idEmpleado: id?.toString() ?? '',
      idUsuario: json['id_usuario']?.toString(),
      idPuesto: json['id_puesto']?.toString(),
      nombreCompleto: completo,
      nombre: nombre,
      apellidoP: paterno,
      apellidoM: materno,
      telefono: json['telefono']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      puesto: json['puesto']?.toString() ?? 'Sin puesto asignado',
      estado: activo == true || activo == 1,
      foto: json['foto']?.toString(),
    );
  }

  // Getters alias para compatibilidad
  String get id => idEmpleado;
  String get fullName => nombreCompleto;
  String get phone => telefono;
  String get email => correo;
  String get role => puesto;
  bool get isActive => estado;
  String? get avatarUrl => foto;
}
