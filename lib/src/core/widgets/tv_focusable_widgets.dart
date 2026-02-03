import 'package:flutter/material.dart';
import 'package:simple_tv_navigation/simple_tv_navigation.dart';

/// Botón envuelto con TVFocusable para navegación TV
class TVButton extends StatelessWidget {
  final String id;
  final String? upId;
  final String? downId;
  final String? leftId;
  final String? rightId;
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool autofocus;

  const TVButton({
    super.key,
    required this.id,
    required this.child,
    this.onPressed,
    this.upId,
    this.downId,
    this.leftId,
    this.rightId,
    this.style,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusable(
      id: id,
      upId: upId,
      downId: downId,
      leftId: leftId,
      rightId: rightId,
      showDefaultFocusDecoration: true,
      onSelect: onPressed,
      builder: (context, isFocused, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isFocused
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  )
                : null,
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: style,
            child: child,
          ),
        );
      },
    );
  }
}

/// IconButton envuelto con TVFocusable para navegación TV
class TVIconButton extends StatelessWidget {
  final String id;
  final String? upId;
  final String? downId;
  final String? leftId;
  final String? rightId;
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final double iconSize;
  final Color? color;

  const TVIconButton({
    super.key,
    required this.id,
    required this.icon,
    this.onPressed,
    this.upId,
    this.downId,
    this.leftId,
    this.rightId,
    this.tooltip,
    this.iconSize = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusable(
      id: id,
      upId: upId,
      downId: downId,
      leftId: leftId,
      rightId: rightId,
      showDefaultFocusDecoration: true,
      onSelect: onPressed,
      builder: (context, isFocused, _) {
        // Wrap with GestureDetector for mobile touch support
        return GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFocused
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Colors.transparent,
              border: isFocused
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
            ),
            child: Icon(
              (icon as Icon).icon,
              size: isFocused ? iconSize * 1.2 : iconSize,
              color: isFocused
                  ? Theme.of(context).colorScheme.primary
                  : (color ?? Theme.of(context).colorScheme.onSurface),
            ),
          ),
        );
      },
    );
  }
}

/// Card envuelta con TVFocusable para navegación TV
class TVCard extends StatelessWidget {
  final String id;
  final String? upId;
  final String? downId;
  final String? leftId;
  final String? rightId;
  final VoidCallback? onTap;
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const TVCard({
    super.key,
    required this.id,
    required this.child,
    this.onTap,
    this.upId,
    this.downId,
    this.leftId,
    this.rightId,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusable(
      id: id,
      upId: upId,
      downId: downId,
      leftId: leftId,
      rightId: rightId,
      showDefaultFocusDecoration: false,
      onSelect: onTap,
      builder: (context, isFocused, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin:
              margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          transform: isFocused
              ? (Matrix4.identity()..scale(1.02))
              : Matrix4.identity(),
          child: Card(
            elevation: isFocused ? 8 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isFocused
                  ? BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    )
                  : BorderSide.none,
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Chip envuelto con TVFocusable para navegación TV
class TVChip extends StatelessWidget {
  final String id;
  final String? upId;
  final String? downId;
  final String? leftId;
  final String? rightId;
  final VoidCallback? onTap;
  final Widget label;
  final bool selected;

  const TVChip({
    super.key,
    required this.id,
    required this.label,
    this.onTap,
    this.upId,
    this.downId,
    this.leftId,
    this.rightId,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusable(
      id: id,
      upId: upId,
      downId: downId,
      leftId: leftId,
      rightId: rightId,
      showDefaultFocusDecoration: false,
      onSelect: onTap,
      builder: (context, isFocused, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FilterChip(
            label: label,
            selected: selected,
            onSelected: (_) => onTap?.call(),
            backgroundColor: isFocused
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isFocused
                    ? Theme.of(context).colorScheme.primary
                    : (selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.withOpacity(0.3)),
                width: isFocused ? 2 : 1,
              ),
            ),
            showCheckmark: false,
          ),
        );
      },
    );
  }
}

/// ListTile envuelto con TVFocusable para navegación TV
class TVListTile extends StatelessWidget {
  final String id;
  final String? upId;
  final String? downId;
  final String? leftId;
  final String? rightId;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;

  const TVListTile({
    super.key,
    required this.id,
    this.onTap,
    this.upId,
    this.downId,
    this.leftId,
    this.rightId,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusable(
      id: id,
      upId: upId,
      downId: downId,
      leftId: leftId,
      rightId: rightId,
      showDefaultFocusDecoration: false,
      onSelect: onTap,
      builder: (context, isFocused, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isFocused
                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isFocused
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: ListTile(
            onTap: onTap,
            leading: leading,
            title: title,
            subtitle: subtitle,
            trailing: trailing,
          ),
        );
      },
    );
  }
}

/// TextField envuelto con TVFocusable para navegación TV
class TVTextField extends StatelessWidget {
  final String id;
  final String? upId;
  final String? downId;
  final String? leftId;
  final String? rightId;
  final TextEditingController? controller;
  final InputDecoration? decoration;
  final bool enabled;
  final int? maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const TVTextField({
    super.key,
    required this.id,
    this.controller,
    this.decoration,
    this.upId,
    this.downId,
    this.leftId,
    this.rightId,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusable(
      id: id,
      upId: upId,
      downId: downId,
      leftId: leftId,
      rightId: rightId,
      showDefaultFocusDecoration: false,
      builder: (context, isFocused, _) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isFocused
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  )
                : null,
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: controller,
            decoration: decoration,
            enabled: enabled,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
          ),
        );
      },
    );
  }
}
