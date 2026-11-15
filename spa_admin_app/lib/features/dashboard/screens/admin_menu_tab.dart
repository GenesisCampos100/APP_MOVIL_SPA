import 'package:flutter/material.dart';
import '../../../core/preferences/staff_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/sesion_service.dart';
import '../../auth/screens/login_admin_screen.dart';
import 'package:spa_admin_app/shared/widgets/confirm_action_dialog.dart';
import '../../services/screens/admin_manage_services_screen.dart';
import '../../services/screens/assign_services_screen.dart';
import '../../employees/screens/manage_employees_screen.dart';
import '../../schedules/screens/manage_schedules_screen.dart';
import 'reports_statistics_screen.dart';
import 'reviews_screen.dart';

/// UI 22: menú UI 20 + consulta de Reseñas y opiniones.
/// La navegación, permisos y cierre de sesión permanecen intactos.
class AdminMenuTab extends StatefulWidget {
  const AdminMenuTab({super.key});

  @override
  State<AdminMenuTab> createState() => _AdminMenuTabState();
}

class _AdminMenuTabState extends State<AdminMenuTab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrada;

  @override
  void initState() {
    super.initState();
    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 440),
    )..forward();
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  String t(String es, String en) => StaffPreferences.tr(es, en);

  Future<void> _elegirTema() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: StaffPreferences.themeMode,
            builder: (_, mode, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(t('Apariencia', 'Appearance')),
                  subtitle: Text(t('Elige la apariencia de tu panel.', 'Choose how your dashboard looks.')),
                ),
                for (final option in [ThemeMode.system, ThemeMode.light, ThemeMode.dark])
                  ListTile(
                    title: Text(switch (option) {
                      ThemeMode.system => t('Según dispositivo', 'Use device setting'),
                      ThemeMode.light => t('Claro', 'Light'),
                      ThemeMode.dark => t('Oscuro', 'Dark'),
                    }),
                    trailing: mode == option ? const Icon(Icons.check_rounded) : null,
                    onTap: () async {
                      await StaffPreferences.changeTheme(option);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _elegirIdioma() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: Text(t('Idioma del Administrador', 'Administrator language')),
            subtitle: Text(t(
              'Se traducen los controles adaptados. Los servicios y las notas permanecen tal como se registraron.',
              'Updated interface controls are translated. Service names and notes remain as recorded.',
            )),
          ),
          ListTile(
            title: const Text('Español'),
            trailing: StaffPreferences.language.value == 'es' ? const Icon(Icons.check_rounded) : null,
            onTap: () async {
              await StaffPreferences.changeLanguage('es');
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            },
          ),
          ListTile(
            title: const Text('English'),
            trailing: StaffPreferences.language.value == 'en' ? const Icon(Icons.check_rounded) : null,
            onTap: () async {
              await StaffPreferences.changeLanguage('en');
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            },
          ),
          const SizedBox(height: 18),
        ]),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await mostrarConfirmacion(
      context: context,
      titulo: t('¿Deseas cerrar sesión?', 'Sign out of Aura SPA?'),
      mensaje: t('Tendrás que ingresar nuevamente para usar Aura SPA.', 'You will need to sign in again to use Aura SPA.'),
      textoConfirmar: t('Sí, cerrar sesión', 'Yes, sign out'),
      icono: Icons.logout_rounded,
    );
    if (!mounted || !confirmar) return;
    AuthSession.cerrar();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginAdminScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _entrada, curve: Curves.easeOutCubic);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.024),
              end: Offset.zero,
            ).animate(fade),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _AuraMenuHeader(),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SeccionTitulo(
                          titulo: t('Catálogo y servicios', 'Catalog and services'),
                          icono: Icons.spa_outlined,
                        ),
                        const SizedBox(height: 12),
                        _OpcionMenu(
                          icono: Icons.medical_services_outlined,
                          titulo: t('Gestionar servicios', 'Manage services'),
                          descripcion: t('Catálogo, precios y disponibilidad.', 'Catalog, prices and availability.'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const AdminManageServicesScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _OpcionMenu(
                          icono: Icons.link_rounded,
                          titulo: t('Asignar servicios', 'Assign services'),
                          descripcion: t('Vincular servicios a empleados o terapeutas.', 'Link services to staff and therapists.'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const AssignServicesScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        _SeccionTitulo(
                          titulo: t('Personal y operación', 'Staff and operations'),
                          icono: Icons.people_outline_rounded,
                        ),
                        const SizedBox(height: 12),
                        _OpcionMenu(
                          icono: Icons.badge_outlined,
                          titulo: t('Gestionar empleados', 'Manage employees'),
                          descripcion: t('Altas, edición de información y estado.', 'Staff profiles, editing and status.'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ManageEmployeesScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _OpcionMenu(
                          icono: Icons.access_time_outlined,
                          titulo: t('Gestionar horarios', 'Manage schedules'),
                          descripcion: t('Turnos, días laborales y descansos.', 'Shifts, workdays and breaks.'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ManageSchedulesScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        _SeccionTitulo(
                          titulo: t('Calidad y resultados', 'Quality and results'),
                          icono: Icons.insights_outlined,
                        ),
                        const SizedBox(height: 12),
                        _OpcionMenu(
                          icono: Icons.bar_chart_rounded,
                          titulo: t('Reportes y estadísticas', 'Reports and statistics'),
                          descripcion: t('Actividad, servicios y rendimiento.', 'Activity, services and performance.'),
                          destacado: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ReportsStatisticsScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _OpcionMenu(
                          icono: Icons.star_border_rounded,
                          titulo: t('Reseñas y opiniones', 'Reviews and ratings'),
                          descripcion: t('Valoraciones y comentarios de clientes.', 'Customer ratings and comments.'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const ReviewsScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        _SeccionTitulo(
                          titulo: t('Preferencias', 'Preferences'),
                          icono: Icons.tune_rounded,
                        ),
                        const SizedBox(height: 12),
                        _OpcionMenu(
                          icono: Icons.dark_mode_outlined,
                          titulo: t('Apariencia', 'Appearance'),
                          descripcion: switch (StaffPreferences.themeMode.value) {
                            ThemeMode.light => t('Claro', 'Light'),
                            ThemeMode.dark => t('Oscuro', 'Dark'),
                            ThemeMode.system => t('Según dispositivo', 'Use device setting'),
                          },
                          onTap: _elegirTema,
                        ),
                        const SizedBox(height: 10),
                        _OpcionMenu(
                          icono: Icons.translate_rounded,
                          titulo: t('Idioma', 'Language'),
                          descripcion: StaffPreferences.language.value == 'en' ? 'English' : 'Español',
                          onTap: _elegirIdioma,
                        ),
                        const SizedBox(height: 25),
                        _OpcionMenu(
                          icono: Icons.logout_rounded,
                          titulo: t('Cerrar sesión', 'Sign out'),
                          descripcion: t('Salir de tu cuenta de manera segura.', 'Safely sign out of your account.'),
                          salir: true,
                          onTap: _cerrarSesion,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Encabezado UI 19: curva real y composición vectorial, sin assets externos.
class _AuraMenuHeader extends StatelessWidget {
  const _AuraMenuHeader();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CurvaMenuClipper(),
      child: Container(
        width: double.infinity,
        height: 225,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
              ? const [Color(0xFF352834), Color(0xFF493344)]
              : const [Color(0xFFFFF8FA), Color(0xFFF8DAE5)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, limits) {
            final ancho = limits.maxWidth;
            final compacto = ancho < 380;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _OndasMenuPainter()),
                  ),
                ),
                Positioned(
                  right: 3,
                  bottom: 7,
                  width: compacto ? 132 : 156,
                  height: compacto ? 148 : 169,
                  child: const IgnorePointer(
                    child: CustomPaint(painter: _SpaIlustracionPainter()),
                  ),
                ),
                Positioned(
                  left: 23,
                  top: 26,
                  right: compacto ? 118 : 135,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A U R A   S P A',
                        maxLines: 1,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryPink,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          fontSize: 10.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        StaffPreferences.tr('Más opciones', 'More options'),
                        maxLines: 2,
                        style: AppTextStyles.displayExtraBold.copyWith(
                          fontSize: compacto ? 23 : 26,
                          height: 1.14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        StaffPreferences.tr('Gestiona y configura tu espacio de bienestar.', 'Manage and customize your workspace.'),
                        maxLines: 3,
                        style: AppTextStyles.body.copyWith(
                          fontSize: compacto ? 11.5 : 12.2,
                          height: 1.4,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Recorte ondulado que elimina el borde rectangular del encabezado.
class _CurvaMenuClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final h = size.height;
    return Path()
      ..lineTo(0, h - 30)
      ..cubicTo(size.width * .18, h - 19, size.width * .24, h + 2,
          size.width * .43, h - 20)
      ..cubicTo(size.width * .62, h - 51, size.width * .80, h + 3,
          size.width, h - 32)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant _CurvaMenuClipper oldClipper) => false;
}

/// Ondas tenues en el fondo, separadas de la ilustración protagonista.
class _OndasMenuPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wave = Path()
      ..moveTo(0, size.height - 43)
      ..cubicTo(size.width * .22, size.height - 61,
          size.width * .34, size.height + 2,
          size.width * .55, size.height - 36)
      ..cubicTo(size.width * .78, size.height - 74,
          size.width * .86, size.height - 17,
          size.width, size.height - 56)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(wave, Paint()..color = const Color(0xFFF1BED0).withValues(alpha: .47));
  }

  @override
  bool shouldRepaint(covariant _OndasMenuPainter oldDelegate) => false;
}

/// Pequeña naturaleza muerta spa (vela, piedras, toallas y flor),
/// dibujada proporcionalmente: no añade fuentes ni dependencias.
class _SpaIlustracionPainter extends CustomPainter {
  const _SpaIlustracionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 156, size.height / 169);
    final hojas = Paint()..color = const Color(0xFF91A97E);
    final hojaLuz = Paint()..color = const Color(0xFFB9C7A0);
    final rama = Paint()
      ..color = const Color(0xFF84996B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(122, 132), const Offset(126, 14), rama);
    void dibujarHoja(Offset base, Offset tip, Paint relleno) {
      final mid = Offset((base.dx + tip.dx) / 2, (base.dy + tip.dy) / 2);
      final path = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(mid.dx - 15, mid.dy - 18, tip.dx, tip.dy)
        ..quadraticBezierTo(mid.dx + 14, mid.dy + 12, base.dx, base.dy);
      canvas.drawPath(path, relleno);
    }
    dibujarHoja(const Offset(127, 46), const Offset(105, 8), hojaLuz);
    dibujarHoja(const Offset(127, 69), const Offset(151, 26), hojas);
    dibujarHoja(const Offset(124, 93), const Offset(96, 47), hojas);
    dibujarHoja(const Offset(126, 108), const Offset(155, 65), hojaLuz);

    final sombra = Paint()..color = const Color(0xFFCE99AB).withValues(alpha: .20);
    canvas.drawOval(const Rect.fromLTWH(7, 143, 142, 17), sombra);
    // Piedras apiladas y ovaladas con brillo discreto.
    for (final r in <Rect>[
      const Rect.fromLTWH(66, 105, 66, 25),
      const Rect.fromLTWH(74, 88, 52, 22),
      const Rect.fromLTWH(83, 73, 37, 17),
    ]) {
      canvas.drawOval(r, Paint()..color = const Color(0xFF99848D));
      canvas.drawOval(Rect.fromLTWH(r.left + 5, r.top + 3, r.width - 10, 5),
          Paint()..color = const Color(0xFFD7BCC3).withValues(alpha: .65));
    }
    // Vela con cristal cálido y llama.
    final vaso = RRect.fromRectAndRadius(
      const Rect.fromLTWH(23, 98, 43, 52), const Radius.circular(9));
    canvas.drawRRect(vaso, Paint()..color = const Color(0xFFFFE7B9));
    canvas.drawRRect(vaso, Paint()
      ..color = const Color(0xFFE8BCA3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3);
    final mecha = Paint()
      ..color = const Color(0xFF987A65)
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(45, 99), const Offset(45, 92), mecha);
    final llama = Path()
      ..moveTo(45, 91)
      ..quadraticBezierTo(34, 81, 46, 68)
      ..quadraticBezierTo(57, 84, 45, 91);
    canvas.drawPath(llama, Paint()..color = const Color(0xFFE6AB5F));
    // Toalla enrollada: contorno, pliegues y espiral.
    final toalla = RRect.fromRectAndRadius(
      const Rect.fromLTWH(94, 122, 51, 29), const Radius.circular(13));
    canvas.drawRRect(toalla, Paint()..color = const Color(0xFFFFF7F4));
    canvas.drawRRect(toalla, Paint()
      ..color = const Color(0xFFE7B9C7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke);
    final espiral = Path()..moveTo(116, 136)
      ..cubicTo(104, 121, 98, 145, 113, 144)
      ..cubicTo(125, 143, 126, 130, 115, 131)
      ..cubicTo(109, 132, 110, 139, 115, 137);
    canvas.drawPath(espiral, Paint()
      ..color = const Color(0xFFD59AAC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    // Flor junto a la vela, semitransparente.
    const centro = Offset(78, 140);
    final petalo = Paint()..color = const Color(0xFFEAA5BA).withValues(alpha: .85);
    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.translate(centro.dx, centro.dy);
      canvas.rotate(i * 1.256637);
      canvas.drawOval(const Rect.fromLTWH(-6, -18, 12, 20), petalo);
      canvas.restore();
    }
    canvas.drawCircle(centro, 4, Paint()..color = const Color(0xFFF6D6AA));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpaIlustracionPainter oldDelegate) => false;
}

class _SeccionTitulo extends StatelessWidget {
  final String titulo;
  final IconData icono;

  const _SeccionTitulo({required this.titulo, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icono, size: 21, color: AppColors.primaryPink),
        const SizedBox(width: 10),
        // Se da prioridad al título, no a la línea ornamental.
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heading2.copyWith(
              fontSize: 15.2,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: Theme.of(context).colorScheme.outlineVariant)),
      ],
    );
  }
}

class _OpcionMenu extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback onTap;
  final bool destacado;
  final bool salir;
  final bool enDesarrollo;

  const _OpcionMenu({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.onTap,
    this.destacado = false,
    this.salir = false,
    this.enDesarrollo = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark
          ? (salir ? scheme.errorContainer.withValues(alpha: .3)
             : destacado ? scheme.primaryContainer.withValues(alpha: .35) : scheme.surface)
          : salir ? const Color(0xFFFFF7F9)
             : destacado ? AppColors.primaryPinkSoft : AppColors.cardBackground,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: AppColors.primaryPink.withValues(alpha: 0.08),
        highlightColor: AppColors.primaryPink.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.82)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 47,
                  height: 47,
                  decoration: BoxDecoration(
                    color: dark ? scheme.primaryContainer : AppColors.primaryPinkSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icono, size: 25, color: dark ? scheme.onPrimaryContainer : AppColors.primaryPink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: AppTextStyles.subtitle.copyWith(
                          fontSize: 13.3,
                          fontWeight: FontWeight.w700,
                          color: salir ? (dark ? scheme.error : AppColors.primaryPink) : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        descripcion,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 10.5,
                          height: 1.35,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (enDesarrollo) ...[
                        const SizedBox(height: 5),
                        Text(
                          'En desarrollo',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.primaryPink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!salir) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded,
                      size: 22, color: AppColors.primaryPink),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
