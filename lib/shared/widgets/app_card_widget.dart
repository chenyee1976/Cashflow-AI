import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppCard – standard card with shadow
// ─────────────────────────────────────────────────────────────────────────────

/// A generic card container with white background, 12 px radius and a subtle
/// shadow that matches the CashFlow AI design system.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), // rgba(0,0,0,0.08)
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: card,
        ),
      );
    }

    return card;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WidgetCard – dashboard widget card with Sky Blue accent bar
// ─────────────────────────────────────────────────────────────────────────────

/// A dashboard widget card that renders a 4 px Sky Blue accent bar at the top
/// followed by a title row and a content area.
class WidgetCard extends StatelessWidget {
  const WidgetCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.onTap,
    this.margin,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sky Blue accent bar
            Container(
              height: 4,
              color: const Color(0xFF1E90FF),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Content
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: content,
        ),
      );
    }

    return content;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppCardWithHeader – card with coloured gradient header
// ─────────────────────────────────────────────────────────────────────────────

/// A card that renders a Sky Blue gradient header containing [headerTitle],
/// followed by a white body area containing [child].
class AppCardWithHeader extends StatelessWidget {
  const AppCardWithHeader({
    super.key,
    required this.headerTitle,
    required this.child,
    this.headerActions,
    this.margin,
    this.bodyPadding = const EdgeInsets.all(16),
  });

  final String headerTitle;
  final Widget child;
  final List<Widget>? headerActions;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry bodyPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header – Sky Blue gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E90FF), Color(0xFF4EAAFF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      headerTitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (headerActions != null) ...headerActions!,
                ],
              ),
            ),
            // Body
            Padding(
              padding: bodyPadding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
