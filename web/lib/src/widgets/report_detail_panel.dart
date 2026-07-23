import 'package:flutter/material.dart';

import '../models/reporte.dart';
import 'map_widget.dart';

class ReportDetailPanel extends StatelessWidget {
  const ReportDetailPanel({super.key, required this.reporte, required this.onClose});

  final Reporte reporte;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Detalle del reporte', style: theme.textTheme.titleLarge),
                      Text(reporte.id, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DetailSection(
                  title: 'Ubicación y contexto',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Latitud: ${reporte.ubicacion.lat.toStringAsFixed(4)}'),
                      Text('Longitud: ${reporte.ubicacion.lng.toStringAsFixed(4)}'),
                      const SizedBox(height: 8),
                      MiniMapWidget(reporte: reporte),
                    ],
                  ),
                ),
                _DetailSection(
                  title: 'Impacto estimado',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mercurio: ${reporte.mercurioEstimadoKg.toStringAsFixed(1)} kg'),
                      Text('Daño económico: Bs ${reporte.danoEconomicoEstimado.toStringAsFixed(0)}'),
                      Text('Riesgo: ${_riskLabel(reporte.nivelRiesgo)}'),
                      Text('Zona protegida: ${reporte.zonaProtegida.esZonaProtegida ? 'Sí' : 'No'}'),
                    ],
                  ),
                ),
                _DetailSection(
                  title: 'Evidencia',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reporte.fotos.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(reporte.fotos.first, fit: BoxFit.cover),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(reporte.notas ?? 'Sin notas adicionales.'),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

String _riskLabel(NivelRiesgo risk) {
  return switch (risk) {
    NivelRiesgo.bajo => 'Bajo',
    NivelRiesgo.medio => 'Medio',
    NivelRiesgo.alto => 'Alto',
  };
}