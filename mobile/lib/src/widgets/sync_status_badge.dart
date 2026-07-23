import 'package:flutter/material.dart';

import '../models/registro.dart';

/// Badge que muestra el estado de sincronización de un registro.
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key, required this.estado});

  final EstadoSync estado;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (estado) {
      EstadoSync.sincronizado => (Colors.green, Icons.cloud_done_outlined, 'Sincronizado'),
      EstadoSync.pendiente => (Colors.orange, Icons.cloud_upload_outlined, 'Pendiente'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
