import 'package:flutter/material.dart';

import '../models/reporte.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({
    super.key,
    required this.reportes,
    required this.loading,
    required this.onOpenReporte,
  });

  final List<Reporte> reportes;
  final bool loading;
  final ValueChanged<String> onOpenReporte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historial de denuncias', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Explora el registro completo y abre cualquier denuncia para revisar sus detalles.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  child: DataTable(
                    columnSpacing: 24,
                    horizontalMargin: 16,
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Fecha')),
                      DataColumn(label: Text('Riesgo')),
                      DataColumn(label: Text('Zona')),
                      DataColumn(label: Text('Acción')),
                    ],
                    rows: reportes.map((reporte) {
                      return DataRow(
                        cells: [
                          DataCell(Text(reporte.id)),
                          DataCell(Text(_formatDate(reporte.fecha))),
                          DataCell(_RiskLabel(risk: reporte.nivelRiesgo)),
                          DataCell(Text(reporte.zonaProtegida.nombre ?? 'Sin zona protegida')),
                          DataCell(
                            FilledButton.tonal(
                              onPressed: () => onOpenReporte(reporte.id),
                              child: const Text('Abrir'),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

class _RiskLabel extends StatelessWidget {
  const _RiskLabel({required this.risk});

  final NivelRiesgo risk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, label) = switch (risk) {
      NivelRiesgo.bajo => (theme.colorScheme.tertiary, 'Bajo'),
      NivelRiesgo.medio => (theme.colorScheme.secondary, 'Medio'),
      NivelRiesgo.alto => (theme.colorScheme.error, 'Alto'),
    };

    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.16),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      side: BorderSide(color: color.withOpacity(0.4)),
    );
  }
}
