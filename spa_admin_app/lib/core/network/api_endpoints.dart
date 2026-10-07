class ApiEndpoints {
  // Rutas de Empleados
  static const String employees = '/employees';
  static String employeeById(String id) => '/employees/$id';

  // Rutas de Servicios
  static const String services = '/services';
  static String serviceById(String id) => '/services/$id';

  // Autenticación
  static const String login = '/auth/login';
}