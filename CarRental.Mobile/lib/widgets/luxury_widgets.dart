import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class LuxurySurface extends StatelessWidget {
  const LuxurySurface({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.margin});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.border),
          boxShadow: const [BoxShadow(color: Color(0x0B09111F), blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: child,
      );
}

class LuxuryTopBar extends StatelessWidget {
  const LuxuryTopBar({super.key, required this.title, this.subtitle, this.onMenu, this.action});
  final String title;
  final String? subtitle;
  final VoidCallback? onMenu;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(
          children: [
            if (onMenu != null)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: IconButton.filledTonal(
                  onPressed: onMenu,
                  icon: const Icon(Icons.menu_rounded),
                  style: IconButton.styleFrom(backgroundColor: AppTheme.surface, foregroundColor: AppTheme.midnight),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, style: const TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
            if (action != null) action!,
          ],
        ),
      );
}

class LuxuryHero extends StatelessWidget {
  const LuxuryHero({super.key, required this.eyebrow, required this.title, required this.description, this.trailing});
  final String eyebrow;
  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
        decoration: BoxDecoration(gradient: AppTheme.luxuryGradient, borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        child: Stack(children: [
          Positioned(left: -36, top: -42, child: _orb(135, AppTheme.primary.withOpacity(.16))),
          Positioned(right: -62, bottom: -76, child: _orb(190, AppTheme.primary.withOpacity(.11))),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(eyebrow.toUpperCase(), style: const TextStyle(color: AppTheme.primaryLight, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 9),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 23, height: 1.15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(description, style: const TextStyle(color: Color(0xB8FFFFFF), height: 1.6, fontSize: 12, fontWeight: FontWeight.w500)),
            ])),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ]),
        ]),
      );

  Widget _orb(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class LuxuryMetric extends StatelessWidget {
  const LuxuryMetric({super.key, required this.label, required this.value, required this.icon, this.accent = AppTheme.primary});
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => LuxurySurface(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: accent.withOpacity(.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: accent, size: 20)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const SizedBox(height: 2), Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.muted, fontWeight: FontWeight.w600))])),
        ]),
      );
}

class LuxuryStatusChip extends StatelessWidget {
  const LuxuryStatusChip({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(.11), borderRadius: BorderRadius.circular(30), border: Border.all(color: color.withOpacity(.2))),
        child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
      );
}

class LuxurySectionTitle extends StatelessWidget {
  const LuxurySectionTitle({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))), if (trailing != null) trailing!]);
}

class LuxuryEmptyState extends StatelessWidget {
  const LuxuryEmptyState({super.key, required this.icon, required this.title, required this.description, this.action});
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => LuxurySurface(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
        child: Column(children: [
          Container(width: 68, height: 68, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(.12), shape: BoxShape.circle), child: Icon(icon, color: AppTheme.primary, size: 30)),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(description, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted, fontSize: 12, height: 1.6)),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ]),
      );
}

class LuxuryPageBackground extends StatelessWidget {
  const LuxuryPageBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF8F6F1), AppTheme.background])),
        child: child,
      );
}
