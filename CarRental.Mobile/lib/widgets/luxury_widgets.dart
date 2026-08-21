import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class LuxurySurface extends StatelessWidget {
  const LuxurySurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
  });

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
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

class LuxuryTopBar extends StatelessWidget {
  const LuxuryTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onMenu,
    this.action,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onMenu;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    decoration: const BoxDecoration(
      color: AppTheme.surface,
      border: Border(bottom: BorderSide(color: AppTheme.border)),
    ),
    child: Row(
      children: [
        if (onMenu != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              onPressed: onMenu,
              icon: const Icon(Icons.menu_rounded),
              color: AppTheme.body,
              tooltip: 'القائمة',
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

class LuxuryHero extends StatelessWidget {
  const LuxuryHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
    decoration: BoxDecoration(
      color: AppTheme.primaryMuted,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      border: Border.all(color: const Color(0xFFC9DCF8)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.body,
                  height: 1.5,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    ),
  );
}

class LuxuryMetric extends StatelessWidget {
  const LuxuryMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppTheme.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) => LuxurySurface(
    padding: const EdgeInsets.all(13),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class LuxuryStatusChip extends StatelessWidget {
  const LuxuryStatusChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: color.withValues(alpha: .18)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
    ),
  );
}

class LuxurySectionTitle extends StatelessWidget {
  const LuxurySectionTitle({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      ?trailing,
    ],
  );
}

class LuxuryEmptyState extends StatelessWidget {
  const LuxuryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => LuxurySurface(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
    child: Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: const BoxDecoration(
            color: AppTheme.primaryMuted,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: AppTheme.primary,
            size: 29,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.muted,
            fontSize: 12,
            height: 1.55,
          ),
        ),
        if (action != null) ...[const SizedBox(height: 17), action!],
      ],
    ),
  );
}

class LuxuryPageBackground extends StatelessWidget {
  const LuxuryPageBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: AppTheme.background, child: child);
}

class LuxurySearchField extends StatelessWidget {
  const LuxurySearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = 'ابحث عن سيارة أو علامة تجارية',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search_rounded),
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              onPressed: () {
                controller.clear();
                onChanged('');
              },
              icon: const Icon(Icons.close_rounded),
              tooltip: 'مسح البحث',
            ),
    ),
  );
}

class LuxuryQuickAction extends StatelessWidget {
  const LuxuryQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryMuted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 16),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.body,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class LuxuryLoadingCard extends StatelessWidget {
  const LuxuryLoadingCard({super.key});

  @override
  Widget build(BuildContext context) => LuxurySurface(
    child: Row(
      children: [
        Container(
          width: 82,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.surfaceSubtle,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 13),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                height: 14,
                child: ColoredBox(color: AppTheme.surfaceSubtle),
              ),
              SizedBox(height: 9),
              SizedBox(
                width: 170,
                height: 11,
                child: ColoredBox(color: AppTheme.surfaceSubtle),
              ),
              SizedBox(height: 9),
              SizedBox(
                width: 80,
                height: 11,
                child: ColoredBox(color: AppTheme.surfaceSubtle),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
