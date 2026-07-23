import 'package:flutter/material.dart';

/// Indicador de estado de conexión (online/offline).
/// En producción se conectaría a un stream real de conectividad.
class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({super.key, this.isOnline = true});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isOnline
            ? Colors.green.withValues(alpha: 0.12)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline
              ? Colors.green.withValues(alpha: 0.4)
              : Colors.orange.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'En línea' : 'Sin conexión',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isOnline ? Colors.green.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
