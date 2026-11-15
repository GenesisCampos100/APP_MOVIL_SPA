import 'package:flutter/material.dart';
import '../../../core/preferences/staff_preferences.dart';
import '../../../data/repositories/staff_profile_repository.dart';
import '../../../data/services/sesion_service.dart';
import 'staff_profile_edit_screen.dart';

/// Pantalla compartida por especialistas y Recepción. Sin accesos operativos duplicados.
class StaffMoreOptionsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const StaffMoreOptionsScreen({super.key, required this.onLogout});

  @override
  State<StaffMoreOptionsScreen> createState() => _StaffMoreOptionsScreenState();
}

class _StaffMoreOptionsScreenState extends State<StaffMoreOptionsScreen> {
  Map<String, dynamic>? _profile;
  String? _error;
  bool _loading = true;
  int _requestId = 0;

  String t(String es, String en) => StaffPreferences.tr(es, en);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final data = await StaffProfileRepository.obtener();
      if (!mounted || requestId != _requestId) return;
      setState(() { _profile = data; _loading = false; });
    } catch (err) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = err.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _editar() async {
    if (_profile == null) return;
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => StaffProfileEditScreen(profile: _profile!)),
    );
    if (mounted) await _load();
  }

  Future<void> _elegirTema() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: StaffPreferences.themeMode,
            builder: (_, mode, __) => Column(mainAxisSize: MainAxisSize.min, children: [
              ListTile(title: Text(t('Apariencia', 'Appearance')),
                subtitle: Text(t('Elige cómo quieres ver Aura SPA', 'Choose how Aura SPA looks'))),
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
            ]),
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
          ListTile(title: Text(t('Idioma del personal', 'Staff language')),
            subtitle: Text(t('Se traducen los controles del personal; los nombres de servicios y notas se conservan como los registró el negocio.',
                'Staff controls are translated; service names and client notes remain as recorded by the business.'))),
          ListTile(title: const Text('Español'),
            trailing: StaffPreferences.language.value == 'es' ? const Icon(Icons.check_rounded) : null,
            onTap: () async {
              await StaffPreferences.changeLanguage('es');
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            }),
          ListTile(title: const Text('English'),
            trailing: StaffPreferences.language.value == 'en' ? const Icon(Icons.check_rounded) : null,
            onTap: () async {
              await StaffPreferences.changeLanguage('en');
              if (sheetContext.mounted) Navigator.pop(sheetContext);
            }),
          const SizedBox(height: 18),
        ]),
      ),
    );
  }

  Widget _option(IconData icon, String heading, String subheading,
      VoidCallback onTap, Color accent) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
    leading: Container(
      height: 43, width: 43,
      decoration: BoxDecoration(color: accent.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(13)),
      child: Icon(icon, color: accent, size: 21),
    ),
    title: Text(heading, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    subtitle: Text(subheading, style: const TextStyle(fontSize: 11)),
    trailing: const Icon(Icons.chevron_right_rounded, size: 20),
  );

  String get _fullName {
    final p = _profile;
    if (p == null) return AuthSession.correo ?? t('Mi perfil', 'My profile');
    final name = [p['nombre'], p['apellido_p'], p['apellido_m']]
        .where((x) => x != null && x.toString().trim().isNotEmpty)
        .join(' ');
    return name.isEmpty ? (AuthSession.correo ?? '') : name;
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: StaffPreferences.language,
    builder: (context, _, __) {
      final colors = Theme.of(context).colorScheme;
      final dark = Theme.of(context).brightness == Brightness.dark;
      final accent = dark ? const Color(0xFFE8ADC2) : const Color(0xFFA9476C);
      final imageUrl = StaffProfileRepository.imageUrl(_profile?['foto']?.toString());
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(21, 20, 21, 28), children: [
          Text('AURA SPA  /  PERSONAL', style: TextStyle(
            fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w700, color: accent)),
          const SizedBox(height: 9),
          Text(t('Tu espacio', 'Your space'), style: Theme.of(context)
              .textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(t('Tus datos y preferencias, sin distraerte de tu jornada.',
             'Your account and preferences, without distracting from your day.'),
             style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF42313D) : const Color(0xFFF9E9EE),
              borderRadius: BorderRadius.circular(21),
            ),
            child: _loading ? const Center(child: Padding(
              padding: EdgeInsets.all(14), child: CircularProgressIndicator()))
            : _error != null ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('No pudimos cargar tu perfil.', 'Could not load your profile.')),
              Text(_error!, style: Theme.of(context).textTheme.bodySmall),
              TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded),
                label: Text(t('Reintentar', 'Retry'))),
            ])
            : Row(children: [
                CircleAvatar(radius: 29,
                  backgroundColor: colors.surface,
                  backgroundImage: imageUrl == null ? null : NetworkImage(imageUrl),
                  child: imageUrl == null ? Icon(Icons.person_outline_rounded,
                     size: 29, color: accent) : null),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_fullName, maxLines: 2, overflow: TextOverflow.ellipsis,
                     style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(AuthSession.esRecepcionista ? t('Recepción', 'Reception')
                         : t('Especialista', 'Specialist'),
                    style: TextStyle(color: accent, fontSize: 12)),
                ])),
                IconButton(tooltip: t('Editar perfil', 'Edit profile'),
                  onPressed: _editar, icon: const Icon(Icons.edit_outlined)),
              ]),
          ),
          const SizedBox(height: 27),
          Text(t('MI CUENTA', 'MY ACCOUNT'), style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: accent)),
          _option(Icons.manage_accounts_outlined, t('Editar perfil', 'Edit profile'),
            t('Nombre y fotografía', 'Name and photo'), _editar, accent),
          const Divider(height: 26),
          Text(t('PREFERENCIAS', 'PREFERENCES'), style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: accent)),
          _option(Icons.dark_mode_outlined, t('Apariencia', 'Appearance'),
            switch (StaffPreferences.themeMode.value) {
              ThemeMode.system => t('Según dispositivo', 'Use device setting'),
              ThemeMode.light => t('Claro', 'Light'),
              ThemeMode.dark => t('Oscuro', 'Dark'),
            }, _elegirTema, accent),
          _option(Icons.translate_rounded, t('Idioma', 'Language'),
            StaffPreferences.language.value == 'es' ? 'Español' : 'English',
            _elegirIdioma, accent),
          const Divider(height: 26),
          Text(t('INFORMACIÓN', 'INFORMATION'), style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: accent)),
          _option(Icons.info_outline_rounded, t('Acerca de Aura SPA', 'About Aura SPA'),
             t('Aplicación del personal · Versión 1.0', 'Staff application · Version 1.0'),
             () => showAboutDialog(context: context, applicationName: 'Aura SPA',
                 applicationVersion: '1.0'), accent),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error.withValues(alpha: .40)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: Text(t('Cerrar sesión', 'Sign out')),
          ),
          const SizedBox(height: 16),
        ]),
      );
    },
  );
}
