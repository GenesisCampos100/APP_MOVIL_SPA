class ApiEndpoints {
  // Rutas de empleados: PENDIENTES de implementar en SpaBackend de Vanessa.
  static const String employees = '/empleados';
  static String employeeById(String id) => '/empleados/$id';

  // Rutas reales existentes en SpaBackend de Vanessa.
  static const String services = '/servicios';
  // Solo Administrador: catálogo completo, incluidos los inactivos.
  static const String adminServices = '/admin/servicios';
  static String serviceById(String id) => '/servicios/$id';

  // Autenticación
  static const String login = '/auth/login';
}