class EmployeeModel {
  // Campos principales en español de la base de datos (EMPLEADOS + USUARIOS + PUESTOS)
  final String idEmpleado; // id_empleado (PK)
  final String? idUsuario; // id_usuario (FK)
  final String? idPuesto; // id_puesto (FK)
  String nombreCompleto; // nombre, apellido_p, apellido_m
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

  // Getters alias para compatibilidad
  String get id => idEmpleado;
  String get fullName => nombreCompleto;
  String get phone => telefono;
  String get email => correo;
  String get role => puesto;
  bool get isActive => estado;
  String? get avatarUrl => foto;
}
