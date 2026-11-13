# Aura SPA — Revisión e integración del administrador

## Origen y alcance
Esta versión se construyó **sobre `spa_admin_app.zip` recibido el 5 de noviembre de 2026**.
Se preservaron todos los archivos existentes; las pantallas originales de Zinedine
(citas, servicios, empleados, horarios, asignaciones, formularios, splash y dashboard)
no se eliminaron ni se sustituyeron.

**Se modificó solo la aplicación Flutter administrativa.** No se tocó
`app_cliente` ni `SpaBackend` de Vanessa.

## Cambios realizados
- Login sin correo/contraseña precargados ni acceso de prueba.
- `ApiService.login`: envía `correo` y `contrasenia`, recibe `token` y
  `usuario.rol` según `auth.controller.js` de Vanessa; maneja el campo `error`.
- Control de navegación por el rol **Administrador** o **Empleado**.
  El Cliente no puede ingresar a esta app.
- `AuthSession`: token, correo, id_usuario y rol solo **en memoria**; se borran
  al cerrar sesión. No se implementó persistencia de sesión.
- Agregadas pantallas `EmployeeHomeScreen`, `EmployeeAppointmentsScreen` y
  `EmployeeNavigationScreen`. La agenda consulta **GET /api/citas** con JWT,
  sin usar datos de prueba de `MisCitasScreen` (que permanece intacta).
- Menú administrativo: se añadió «Cerrar sesión» sin borrar opciones existentes.
- `ApiEndpoints`: rutas de servicios en español (`/servicios`); `/empleados`
  queda reservado para un endpoint que Vanessa todavía no implementa.
- API: URL local unificada en `ApiConfig.baseUrl = http://10.0.2.2:3000/api`
  para emulador Android; puede cambiarse mediante `--dart-define=SPA_API_URL=...`.
- Android: permiso INTERNET en el manifiesto principal y HTTP local permitido
  **solo en compilación debug**.
- Se conservaron los estilos rosa y Poppins del ZIP recibido.

## Importante sobre el backend de Vanessa
**El backend original permite login para `id_rol=1` (Administrador) y
`id_rol=3` (Cliente), pero rechaza `id_rol=2` (Empleado) con HTTP 403.**
La interfaz de empleado está preparada, pero el acceso real necesitará un cambio
coordinado con Vanessa. Esta entrega NO modifica el backend.

Los módulos administrativos de citas, empleados, horarios y servicios siguen
conteniendo datos visuales locales que deben conectarse a PostgreSQL en una
etapa posterior. No se afirma que esos CRUD ya funcionen de extremo a extremo.

## Cómo probar en VS Code (PowerShell)
Desde la raíz del repositorio:

```powershell
cd .\spa_admin_app
Test-Path .\pubspec.yaml
Test-Path .\lib\main.dart
flutter pub get
flutter analyze
flutter run -d emulator-5554
```

Para el login real, el backend debe estar ejecutándose en la computadora en
puerto 3000. El emulador accede a ese servidor mediante `10.0.2.2`.

No se pudo ejecutar Flutter SDK en el entorno de preparación. Se validaron
las rutas de importación y de assets, estructura de archivos y manifiestos XML;
**la compilación final debe comprobarse en tu computadora**.

## Notas de integración segura
- Haz un commit o respaldo de tu proyecto actual antes de reemplazarlo.
- El ZIP contiene toda la estructura y código Dart de esta revisión,
  y se aplica **combinando las carpetas** con tu proyecto actual.
  **Conserva `assets/fonts/` y sus fuentes Poppins locales** (no se incluyen
  los archivos de fuente en el paquete distribuido). No borres tu proyecto
  actual ni cambies sus archivos ajenos a esta integración.
- Evita subir `node_modules`, `.dart_tool`, `build` o secretos a Git.
- Para dispositivo real o producción usa una API accesible por HTTPS.
