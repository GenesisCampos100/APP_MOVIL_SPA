# Registro de migración a la organización de `app_cliente`

**Base usada:** última versión integrada de `spa_admin_app` con la
compatibilidad de login de Vanessa y panel básico del Empleado.
**Objetivo:** cambiar exclusivamente la organización del código de Flutter.

## Movimientos

- `lib/core/constants/*` → `lib/core/theme/*`
- `lib/core/network/*` → `lib/data/services/*`
- `lib/features/*/data/models/*` → `lib/data/models/*`
- `lib/features/auth/data/auth_session.dart` → `lib/data/services/sesion_service.dart`
- `lib/features/*/presentation/screens/*` → `lib/features/*/screens/*`
- `lib/features/*/presentation/widgets/*` → `lib/features/*/widgets/*`
- `lib/features/auth/.../splash_screen.dart` → `lib/features/splash/screens/`
- `main_navigation_screen.dart` y `employee_navigation_screen.dart` → `lib/features/shell/screens/`
- `dashboard/presentation/tabs/*` → `lib/features/dashboard/screens/`

## Separaciones de configuración (sin cambiar funcionalidad)

- `lib/main.dart` conserva `main()`.
- `lib/app.dart` contiene `SpaAdminApp` y `MaterialApp`.
- `lib/core/theme/app_theme.dart` contiene el mismo `ThemeData` de antes.
- `lib/core/routes/app_routes.dart` concentra únicamente rutas de entrada (Splash/Login).

Todas las vistas, diálogos, modelos y servicios Dart existentes se conservaron.
Las importaciones relativas y `package:spa_admin_app/...` fueron actualizadas.
`data/repositories/` y `shared/widgets/` están preparadas; no se han inventado
conexiones ni componentes. La clase `AuthSession` y su comportamiento no
se modificaron, solo se reubicó su archivo.

## Compatibilidad con Vanessa

Se mantienen `correo`, `contrasenia`, `token`, `usuario`, `id_usuario`, `rol`.
No cambia la API, la base de datos ni ningún archivo del backend compartido.
El inicio de sesión real del Empleado sigue condicionado a que Vanessa permita
su rol en `auth.controller.js`. Las cuentas Cliente no pueden usar esta app.

## Forma segura de instalar

1. Renombra o respalda tu carpeta actual `spa_admin_app` fuera del repositorio.
2. Extrae este ZIP de modo que `APP_MOVIL_SPA/spa_admin_app` quede al mismo nivel
   que `app_cliente` y `SpaBackend`. **No combines las carpetas `lib` viejas y
   nuevas**, porque Flutter analizaría rutas duplicadas.
3. Copia **únicamente** `assets/fonts/` desde tu respaldo original a la nueva
   `spa_admin_app/assets/fonts/`. No sustituyas el resto de `lib`.
4. Dentro de `spa_admin_app`: `flutter pub get`, `flutter analyze` y
   `flutter run -d emulator-5554`.
5. Comprueba Splash → Login → Panel por rol, Menú, Servicios, Citas, Empleados
   y Horarios. Si no compila, conserva el respaldo sin sobrescribirlo.

## Validaciones disponibles

Se comprobaron las rutas de importación Dart dentro del paquete y la
correspondencia de archivos antes/después, pero no se ejecutó Flutter ni
la API en este entorno.
