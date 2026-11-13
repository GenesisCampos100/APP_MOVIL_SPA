# Aura SPA — aplicación administrativa y del empleado

Proyecto Flutter independiente de `app_cliente`, conectado al mismo backend
`SpaBackend` (Vanessa) y a PostgreSQL **únicamente mediante la API REST**.

## Organización (mismo estilo que `app_cliente`)

```text
lib/
├── main.dart                      # Entrada a Flutter
├── app.dart                       # MaterialApp
├── core/
│   ├── routes/app_routes.dart     # Rutas iniciales; login y splash
│   └── theme/                     # app_theme, app_colors, app_text_styles
├── data/
│   ├── models/                    # Entidades Dart para citas, empleados, etc.
│   ├── repositories/              # Repositorios futuros, sin simulaciones
│   └── services/                  # api_config, api_service, api_client, sesión
├── features/
│   ├── auth/screens/              # Login, ambas cuentas de personal
│   ├── splash/screens/            # Bienvenida
│   ├── shell/screens/             # Navegación por rol
│   ├── dashboard/screens/         # Dashboard y menú del administrador
│   ├── employee/screens/          # Panel y agenda del empleado
│   ├── employees/screens|widgets/  # Gestión del personal
│   ├── appointments/screens|widgets/
│   ├── schedules/screens|widgets/
│   └── services/screens|widgets/
└── shared/widgets/               # Componentes futuros compartidos
```

Los nombres de las clases de todas las vistas se conservaron. Las carpetas
`features/.../screens` y `features/.../widgets` contienen todas las pantallas
originales; no se modificó su lógica, salvo rutas `import` por el traslado.

## Autenticación

El login envía `{correo, contrasenia}` a `POST /api/auth/login`, lee `token`
y `usuario.rol` y redirige al panel según el rol. La sesión se mantiene **en
memoria** y no persiste al cerrar el proceso. En el backend de Vanessa usado
como referencia, el acceso del Empleado continúa pendiente de habilitar.

Los datos de servicios, citas, empleados y horarios que originalmente se
simulan en algunos módulos no se transformaron en datos reales con este
refactor. No se hicieron cambios a `SpaBackend` o `app_cliente`.

## Requisitos

- Flutter y Android Studio instalados.
- Conservar las fuentes **Poppins** que ya tienes en `assets/fonts/` del
  proyecto original; la distribución de reorganización no las adjunta.
- Para Android Emulator, la URL por defecto de `data/services/api_config.dart`
  es `http://10.0.2.2:3000/api`. Para otros ambientes usar
  `--dart-define=SPA_API_URL=https://.../api`.

## Ejecución

```powershell
cd spa_admin_app
flutter pub get
flutter analyze
flutter run -d emulator-5554
```

Para consultar diferencias, leer `MIGRACION_ESTRUCTURA.md`.
