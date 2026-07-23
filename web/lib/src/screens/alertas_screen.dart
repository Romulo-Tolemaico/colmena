import 'package:flutter/material.dart';

import '../models/reporte.dart';

class AlertasScreen extends StatelessWidget {
  const AlertasScreen({super.key, required this.reportes, required this.onOpenReporte});

  final List<Reporte> reportes;
  final ValueChanged<String> onOpenReporte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alertas = reportes.where((reporte) => reporte.nivelRiesgo == NivelRiesgo.alto || reporte.estado == EstadoReporte.nuevo).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alertas activas', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Casos prioritarios que requieren revisión o escalamiento.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: alertas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final reporte = alertas[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.error,
                      child: const Icon(Icons.notifications_active, color: Colors.white),
                    ),
                    title: Text('${reporte.id} · ${reporte.zonaProtegida.nombre ?? 'Sin zona protegida'}'),
                    subtitle: Text('Mercurio estimado: ${reporte.mercurioEstimadoKg.toStringAsFixed(1)} kg'),
                    trailing: FilledButton.tonal(
                      onPressed: () => onOpenReporte(reporte.id),
                      child: const Text('Revisar'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}