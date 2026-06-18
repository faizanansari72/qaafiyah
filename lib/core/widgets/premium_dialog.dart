import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class PremiumDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final IconData? icon;
  final Color? iconColor;

  const PremiumDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.icon,
    this.iconColor,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    IconData? icon,
    Color? iconColor,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: title,
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final double curveValue = Curves.easeOutBack.transform(anim1.value);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8.0 * anim1.value,
            sigmaY: 8.0 * anim1.value,
          ),
          child: Transform.scale(
            scale: 0.85 + (0.15 * curveValue),
            child: Opacity(
              opacity: anim1.value,
              child: Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  child: Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: PremiumDialog(
                        title: title,
                        content: content,
                        actions: actions,
                        icon: icon,
                        iconColor: iconColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      child: GlassCard(
        borderRadius: 24,
        blur: 20,
        padding: const EdgeInsets.all(24),
        border: Border.all(
          color: isDark ? AppTheme.darkPrimaryGold.withOpacity(0.2) : AppTheme.lightPrimaryGold.withOpacity(0.25),
          width: 1.5,
        ),
        shadow: [
          BoxShadow(
            color: (isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold).withOpacity(0.12),
            blurRadius: 32,
            spreadRadius: -4,
          )
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Close Button / Icon Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (iconColor ?? (isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold)).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (iconColor ?? (isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold)).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: iconColor ?? (isDark ? AppTheme.darkPrimaryGold : AppTheme.lightPrimaryGold),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                letterSpacing: -0.5,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Content
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
              child: content,
            ),
            
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!.map((action) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: action,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
