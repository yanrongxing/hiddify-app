import 'package:flutter/material.dart';

class SettingsGroupWrapper extends StatelessWidget {
  const SettingsGroupWrapper({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Add dividers between tiles
    final dividedChildren = ListTile.divideTiles(
      context: context,
      tiles: children,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15),
    ).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IconTheme(
            data: IconThemeData(color: theme.colorScheme.primary),
            child: ListTileTheme(
              data: ListTileTheme.of(context).copyWith(
                iconColor: theme.colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: dividedChildren,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
