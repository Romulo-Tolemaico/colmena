import 'package:flutter/material.dart';

import '../models/metricas_dashboard.dart';
import '../models/reporte.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.reportes,
    required this.metricas,
    required this.loading,
    required this.onOpenReporte,
    required this.selectedReporteId,
  });

  final List<Reporte> reportes;
  final MetricasDashboard? metricas;
  final bool loading;
  final ValueChanged<String> onOpenReporte;
  final String? selectedReporteId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _DashboardHero(loading: loading, total: metricas?.totalDenuncias ?? reportes.length),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          if (loading || metricas == null)
            const SliverToBoxAdapter(child: LinearProgressIndicator()),
          if (!loading && metricas != null)
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth >= 1100 ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _MetricCard(title: 'Total de denuncias', value: metricas!.totalDenuncias.toString(), width: cardWidth),
                      _MetricCard(title: 'Mercurio acumulado', value: '${metricas!.mercurioAcumuladoKg.toStringAsFixed(1)} kg', width: cardWidth),
                      _MetricCard(title: 'Zonas protegidas', value: metricas!.zonasProtegidasAfectadas.toString(), width: cardWidth),
                      _MetricCard(title: 'Anónimas', value: '${metricas!.porcentajeAnonimas}%', width: cardWidth),
                    ],
                  );
                },
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1000;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _ActivityChart(metricas: metricas)),
                          const SizedBox(width: 16),
                          Expanded(child: _RecentActivityCard(reportes: reportes, onOpenReporte: onOpenReporte, selectedReporteId: selectedReporteId)),
                        ],
                      )
                    : Column(
                        children: [
                          _ActivityChart(metricas: metricas),
                          const SizedBox(height: 16),
                          _RecentActivityCard(reportes: reportes, onOpenReporte: onOpenReporte, selectedReporteId: selectedReporteId),
                        ],
                      );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Señales críticas', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...reportes.take(3).map((reporte) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Icon(_iconForRisk(reporte.nivelRiesgo), color: _colorForRisk(theme, reporte.nivelRiesgo)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(reporte.id, style: theme.textTheme.titleSmall),
                                  Text(reporte.zonaProtegida.nombre ?? 'Sin zona protegida', style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: () => onOpenReporte(reporte.id),
                              child: const Text('Ver'),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.width});

  final String title;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.clamp(180, 320).toDouble(),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(title), const SizedBox(height: 8), Text(value, style: Theme.of(context).textTheme.headlineSmall)],
          ),
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({required this.loading, required this.total});

  final bool loading;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primaryContainer, theme.colorScheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumen operativo', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text('Monitoreo ambiental y denuncias en tiempo casi real', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    loading ? 'Cargando métricas...' : 'Se están consolidando $total reportes para el tablero principal.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.hive_outlined, size: 64, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.metricas});

  final MetricasDashboard? metricas;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = metricas?.denunciasPorMes ?? const <SerieMensual>[];
    final maxValue = data.isEmpty ? 1 : data.map((item) => item.cantidad).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actividad por mes', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((serie) {
                  final height = 180 * (serie.cantidad / maxValue);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(serie.cantidad.toString(), style: theme.textTheme.labelLarge),
                          const SizedBox(height: 8),
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(serie.mes, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.reportes, required this.onOpenReporte, required this.selectedReporteId});

  final List<Reporte> reportes;
  final ValueChanged<String> onOpenReporte;
  final String? selectedReporteId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Últimos reportes', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ...reportes.map((reporte) {
              final selected = reporte.id == selectedReporteId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onOpenReporte(reporte.id),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: _colorForRisk(theme, reporte.nivelRiesgo),
                          child: Icon(_iconForRisk(reporte.nivelRiesgo), color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(reporte.id, style: theme.textTheme.titleMedium),
                              Text(reporte.zonaProtegida.nombre ?? 'Sin zona protegida', style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

Color _colorForRisk(ThemeData theme, NivelRiesgo risk) {
  switch (risk) {
    case NivelRiesgo.bajo:
      return theme.colorScheme.tertiary;
    case NivelRiesgo.medio:
      return theme.colorScheme.secondary;
    case NivelRiesgo.alto:
      return theme.colorScheme.error;
  }
}

IconData _iconForRisk(NivelRiesgo risk) {
  switch (risk) {
    case NivelRiesgo.bajo:
      return Icons.info_outline;
    case NivelRiesgo.medio:
      return Icons.report_outlined;
    case NivelRiesgo.alto:
      return Icons.warning_amber_outlined;
  }
}
