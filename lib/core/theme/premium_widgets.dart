import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'app_theme.dart';

/// ─── Premium Pill Button (black solid, pressable, pill) ─────────
class PremiumButton extends StatefulWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  final IconData? trailingIcon;
  final IconData? leadingIcon;
  final Color? background;
  final Color? foreground;
  final double height;
  final bool fullWidth;
  final bool outlined;

  const PremiumButton({
    super.key,
    required this.label,
    this.loading = false,
    this.onTap,
    this.trailingIcon,
    this.leadingIcon,
    this.background,
    this.foreground,
    this.height = 56,
    this.fullWidth = true,
    this.outlined = false,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final bg = widget.outlined
        ? Colors.transparent
        : (widget.background ?? AppColors.black);
    final fg = widget.outlined
        ? AppColors.black
        : (widget.foreground ?? AppColors.white);

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: disabled
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: widget.fullWidth ? double.infinity : null,
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: disabled ? AppColors.surfaceMuted : bg,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: widget.outlined
                ? Border.all(color: AppColors.black, width: 1.4)
                : null,
            boxShadow: disabled || widget.outlined
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(_pressed ? 0.10 : 0.20),
                      blurRadius: _pressed ? 10 : 22,
                      offset: Offset(0, _pressed ? 4 : 10),
                    ),
                  ],
          ),
          child: Center(
            child: widget.loading
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: disabled ? AppColors.textMuted : fg,
                      strokeWidth: 2.4,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leadingIcon != null) ...[
                        Icon(widget.leadingIcon,
                            size: 18,
                            color: disabled ? AppColors.textMuted : fg),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: disabled ? AppColors.textMuted : fg,
                          letterSpacing: 0.1,
                        ),
                      ),
                      if (widget.trailingIcon != null) ...[
                        const SizedBox(width: 10),
                        Icon(widget.trailingIcon,
                            size: 18,
                            color: disabled ? AppColors.textMuted : fg),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// ─── Floating Card (rounded 28+, soft shadow) ──────────────────
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 28,
    this.color,
    this.onTap,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: padding ?? const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color ?? AppColors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow ?? AppShadows.sm,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return _PressableScale(
      onTap: onTap!,
      child: content,
    );
  }
}

/// ─── Animated press-scale wrapper (reusable micro-interaction) ─
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;

  const _PressableScale({
    required this.child,
    required this.onTap,
    this.scale = 0.97,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class PressableScale extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scale;

  const PressableScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
  });

  @override
  Widget build(BuildContext context) =>
      _PressableScale(onTap: onTap, scale: scale, child: child);
}

/// ─── Premium Input (rounded, modern focus glow) ────────────────
class PremiumInput extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String hint;
  final IconData? icon;
  final TextInputType keyboardType;
  final bool obscure;
  final int? maxLength;
  final void Function(String)? onChanged;
  final Widget? suffix;

  const PremiumInput({
    super.key,
    required this.controller,
    this.label,
    required this.hint,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.maxLength,
    this.onChanged,
    this.suffix,
  });

  @override
  State<PremiumInput> createState() => _PremiumInputState();
}

class _PremiumInputState extends State<PremiumInput> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.08),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscure,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: widget.hint,
              prefixIcon: widget.icon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 18, right: 12),
                      child: Icon(widget.icon,
                          color: _focused
                              ? AppColors.black
                              : AppColors.textMuted,
                          size: 20),
                    )
                  : null,
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: widget.suffix,
            ),
          ),
        ),
      ],
    );
  }
}

/// ─── Premium Section Header ────────────────────────────────────
class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          if (action != null)
            PressableScale(
              onTap: onAction ?? () {},
              child: Row(
                children: [
                  Text(
                    action!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 2),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ─── Accent "chip" with neon pastel fill ───────────────────────
class AccentChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final Color? foreground;

  const AccentChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? AppColors.black;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Premium smooth page route with fade + slide ───────────────
class PremiumPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  PremiumPageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, anim, _) => page,
          transitionsBuilder: (context, anim, _, child) {
            final curve = CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curve,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.035),
                  end: Offset.zero,
                ).animate(curve),
                child: child,
              ),
            );
          },
        );
}

/// ─── Animated skeleton shimmer (loading state) ─────────────────
class PremiumSkeleton extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const PremiumSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 900.ms, curve: Curves.easeInOut)
        .then()
        .fade(begin: 1, end: 0.4, duration: 900.ms, curve: Curves.easeInOut);
  }
}

/// ─── Staggered list fade/slide entrance helper ─────────────────
extension PremiumEntranceEffects on Widget {
  Widget premiumEntrance({int index = 0, Duration? baseDelay}) {
    final delay =
        (baseDelay ?? const Duration(milliseconds: 60)) * index.clamp(0, 12);
    return animate(delay: delay)
        .fadeIn(duration: 420.ms, curve: Curves.easeOutCubic)
        .moveY(
            begin: 20,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOutCubic);
  }
}
