import 'package:flutter/material.dart';
import 'package:spa_admin_app/core/preferences/staff_preferences.dart';
import 'package:spa_admin_app/data/repositories/staff_profile_repository.dart';

/// Cabecera editorial reutilizable. Lee el perfil autenticado, sin datos ficticios.
class StaffDailyHeader extends StatefulWidget {
  const StaffDailyHeader({super.key, required this.reception, this.refreshVersion = 0});
  final bool reception;
  final int refreshVersion;
  @override
  State<StaffDailyHeader> createState() => _StaffDailyHeaderState();
}

class _StaffDailyHeaderState extends State<StaffDailyHeader> {
  Map<String, dynamic>? _profile;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    StaffProfileRepository.profileRevision.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(covariant StaffDailyHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshVersion != oldWidget.refreshVersion) _load();
  }

  @override
  void dispose() {
    StaffProfileRepository.profileRevision.removeListener(_load);
    _request++;
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    try {
      final data = await StaffProfileRepository.obtener();
      if (mounted && request == _request) setState(() => _profile = data);
    } catch (_) {
      // Sin perfil temporalmente: se mantiene el saludo neutro.
      if (mounted && request == _request) setState(() => _profile = null);
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return StaffPreferences.tr('Buenos días', 'Good morning');
    if (hour < 19) return StaffPreferences.tr('Buenas tardes', 'Good afternoon');
    return StaffPreferences.tr('Buenas noches', 'Good evening');
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final first = _profile?['nombre']?.toString().trim() ?? '';
    final photoUrl = StaffProfileRepository.imageUrl(_profile?['foto']?.toString());
    final welcome = first.isEmpty
        ? StaffPreferences.tr('Tu jornada', 'Your day')
        : '${_greeting()}, $first';
    final subtitle = widget.reception
        ? StaffPreferences.tr('Las reservaciones de hoy, bajo control.', 'Today’s bookings, under control.')
        : StaffPreferences.tr('Tu agenda, a tu ritmo.', 'Your schedule, at your pace.');
    final accent = dark ? const Color(0xFFF2B9CD) : const Color(0xFFA04B6B);
    final headline = dark ? const Color(0xFFFFF4F8) : const Color(0xFF46313A);
    final today = DateTime.now();
    final date = '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year}';
    return Container(
      padding: const EdgeInsets.fromLTRB(21, 22, 19, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: dark
              ? [const Color(0xFF4C3340), const Color(0xFF2D242E)]
              : [const Color(0xFFF7E4EB), const Color(0xFFFFFAFC)],
        ),
        border: Border.all(color: dark ? const Color(0xFF624250) : const Color(0xFFEED3DE)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AURA SPA  /  ${widget.reception ? StaffPreferences.tr('RECEPCIÓN', 'RECEPTION') : StaffPreferences.tr('ESPECIALISTA', 'SPECIALIST')}',
            style: TextStyle(fontSize: 10, letterSpacing: 1.4, fontWeight: FontWeight.w700, color: accent)),
          const SizedBox(height: 14),
          Text(welcome, maxLines: 3, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 23, height: 1.16, fontWeight: FontWeight.w800, color: headline)),
          const SizedBox(height: 10),
          Text(subtitle, style: TextStyle(color: dark ? const Color(0xFFE6C6D1) : const Color(0xFF715C64), fontSize: 12)),
          const SizedBox(height: 12),
          Row(children: [
            Icon(Icons.event_outlined, size: 14, color: accent),
            const SizedBox(width: 6),
            Text(date, style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 11)),
          ]),
        ])),
        const SizedBox(width: 12),
        Container(
          width: 69, height: 69,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accent.withValues(alpha: 0.40), width: 1.5)),
          child: ClipOval(child: photoUrl == null
              ? ColoredBox(color: dark ? const Color(0xFF654759) : Colors.white,
                  child: Icon(Icons.person_outline_rounded, size: 30, color: accent))
              : Image.network(photoUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: dark ? const Color(0xFF654759) : Colors.white,
                    child: Icon(Icons.person_outline_rounded, size: 30, color: accent))),
          ),
        ),
      ]),
    );
  }
}

/// Métricas compactas que respetan el tema sin duplicar acciones del menú.
class StaffNumberCard extends StatelessWidget {
  const StaffNumberCard({super.key, required this.label, required this.count, required this.accent});
  final String label;
  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 12, 13),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dark ? const Color(0xFF52424C) : const Color(0xFFEDE1E6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 29, height: 3, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(3))),
        const SizedBox(height: 13),
        Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.1, color: theme.colorScheme.onSurface)),
        const SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
      ]),
    );
  }
}

class StaffSectionHeading extends StatelessWidget {
  const StaffSectionHeading({super.key, required this.title, this.onRefresh});
  final String title;
  final VoidCallback? onRefresh;
  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
    if (onRefresh != null) IconButton(
      tooltip: StaffPreferences.tr('Actualizar', 'Refresh'),
      onPressed: onRefresh,
      icon: const Icon(Icons.refresh_rounded, size: 21)),
  ]);
}

class StaffProgressCard extends StatelessWidget {
  const StaffProgressCard({super.key, required this.completed, required this.total, required this.label});
  final int completed;
  final int total;
  final String label;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: dark ? const Color(0xFF52424C) : const Color(0xFFEDE1E6)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
          Text('$completed / $total', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        ]),
        const SizedBox(height: 13),
        ClipRRect(borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : completed / total,
            backgroundColor: scheme.primary.withValues(alpha: 0.12),
            color: scheme.primary, minHeight: 7)),
        const SizedBox(height: 9),
        Text(StaffPreferences.tr('Las canceladas no forman parte del progreso.', 'Cancelled bookings are not included.'),
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
      ]),
    );
  }
}

class StaffUpcomingCard extends StatelessWidget {
  const StaffUpcomingCard({super.key, required this.service, required this.person, required this.when});
  final String service;
  final String person;
  final String when;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(17),
        border: Border.all(color: dark ? const Color(0xFF52424C) : const Color(0xFFEDE1E6))),
      child: Padding(padding: const EdgeInsets.fromLTRB(0, 11, 13, 11), child: Row(children: [
        Container(width: 3, height: 47, decoration: BoxDecoration(
          color: scheme.primary, borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(service, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: scheme.onSurface)),
          const SizedBox(height: 5),
          Text(person, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        ])),
        const SizedBox(width: 8),
        Text(when, textAlign: TextAlign.right, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700, color: scheme.primary)),
      ])),
    );
  }
}
