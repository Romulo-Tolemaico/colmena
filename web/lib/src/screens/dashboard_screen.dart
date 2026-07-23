import 'package:flutter/material.dart';

import '../models/metricas_dashboard.dart';
import '../models/reporte.dart';
import '../widgets/map_widget.dart';

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
      padding: const EdgeInsets.all(16),
      child: CustomScrollView(
        slivers: [
          // Encabezado
          SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Eventos de minería ilegal en ríos',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monitorea y reporta actividades ilegales que afectan nuestros ríos',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo reporte'),
                ),
              ],
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Métricas en tarjetas
          SliverToBoxAdapter(
            child: _MetricsRow(metricas: metricas, reportes: reportes, loading: loading),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Mapa central + panel lateral
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                if (isWide) {
                  return SizedBox(
                    height: 480,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _MapSection(
                            reportes: reportes,
                            onMarkerTap: onOpenReporte,
                            selectedReporteId: selectedReporteId,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: _SideInfoPanel(reportes: reportes, metricas: metricas, onOpenReporte: onOpenReporte),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    SizedBox(
                      height: 360,
                      child: _MapSection(
                        reportes: reportes,
                        onMarkerTap: onOpenReporte,
                        selectedReporteId: selectedReporteId,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SideInfoPanel(reportes: reportes, metricas: metricas, onOpenReporte: onOpenReporte),
                  ],
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Alertas activas al fondo
          SliverToBoxAdapter(
            child: _AlertasBanner(reportes: reportes, onOpenReporte: onOpenReporte),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Métricas en fila
// ─────────────────────────────────────────────────────────────────────────────

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.metricas, required this.reportes, required this.loading});

  final MetricasDashboard? metricas;
  final List<Reporte> reportes;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) return const LinearProgressIndicator();

    final total = metricas?.totalDenuncias ?? reportes.length;
    final enVerificacion = reportes.where((r) => r.estado == EstadoReporte.revisado).length;
    final confirmados = reportes.where((r) => r.estado == EstadoReporte.escalado).length;
    final riosAfectados = metricas?.zonasProtegidasAfectadas ?? 0;
    final comunidades = reportes.map((r) => r.zonaProtegida.nombre).whereType<String>().toSet().length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricCard(
          title: 'Eventos reportados',
          value: total.toString(),
          icon: Icons.flag_outlined,
          color: const Color(0xFF4CAF50),
          subtitle: '↑ 23% vs. mes anterior',
        ),
        _MetricCard(
          title: 'En verificación',
          value: enVerificacion.toString(),
          icon: Icons.pending_outlined,
          color: const Color(0xFFFFA726),
        ),
        _MetricCard(
          title: 'Confirmados',
          value: confirmados.toString(),
          icon: Icons.check_circle_outline,
          color: const Color(0xFFEF5350),
        ),
        _MetricCard(
          title: 'Ríos afectados',
          value: riosAfectados.toString(),
          icon: Icons.water_outlined,
          color: const Color(0xFF42A5F5),
        ),
        _MetricCard(
          title: 'Comunidades activas',
          value: comunidades.toString(),
          icon: Icons.groups_outlined,
          color: const Color(0xFF7E57C2),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 195,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  Icon(icon, size: 18, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF4CAF50), fontSize: 11)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sección del mapa
// ─────────────────────────────────────────────────────────────────────────────

class _MapSection extends StatelessWidget {
  const _MapSection({required this.reportes, required this.onMarkerTap, required this.selectedReporteId});

  final List<Reporte> reportes;
  final ValueChanged<String> onMarkerTap;
  final String? selectedReporteId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: MapWidget(
              reportes: reportes,
              onMarkerTap: onMarkerTap,
              selectedReporteId: selectedReporteId,
            ),
          ),
          // Leyenda superpuesta
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Leyenda', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _LegendItem(color: const Color(0xFFEF5350), label: 'Confirmado'),
                  const SizedBox(height: 4),
                  _LegendItem(color: const Color(0xFFFFA726), label: 'En verificación'),
                  const SizedBox(height: 4),
                  _LegendItem(color: const Color(0xFF4CAF50), label: 'Reportado'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Panel lateral de info (evento destacado + actividad por mes + actividad reciente)
// ─────────────────────────────────────────────────────────────────────────────

class _SideInfoPanel extends StatelessWidget {
  const _SideInfoPanel({required this.reportes, required this.metricas, required this.onOpenReporte});

  final List<Reporte> reportes;
  final MetricasDashboard? metricas;
  final ValueChanged<String> onOpenReporte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Evento destacado
        if (reportes.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Evento destacado', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF5350).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _estadoLabel(reportes.first.estado),
                          style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFFEF5350)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    reportes.first.notas ?? 'Actividad detectada en zona de monitoreo',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reportes.first.zonaProtegida.nombre ?? 'Zona sin identificar',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 13, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(_formatDate(reportes.first.fecha), style: theme.textTheme.bodySmall),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on_outlined, size: 13, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${reportes.first.ubicacion.lat.toStringAsFixed(2)}°S, ${reportes.first.ubicacion.lng.abs().toStringAsFixed(2)}°W',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Gráfico de actividad por mes
        if (metricas != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Eventos por mes', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: _MiniChart(data: metricas!.denunciasPorMes),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),

        // Actividad reciente
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Actividad reciente', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                      child: const Text('Ver todos', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...reportes.take(3).map((reporte) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onOpenReporte(reporte.id),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _colorForEstado(reporte.estado),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reporte.notas ?? 'Reporte ${reporte.id}',
                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    reporte.zonaProtegida.nombre ?? 'Sin zona',
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatTime(reporte.fecha),
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner de alertas activas
// ─────────────────────────────────────────────────────────────────────────────

class _AlertasBanner extends StatelessWidget {
  const _AlertasBanner({required this.reportes, required this.onOpenReporte});

  final List<Reporte> reportes;
  final ValueChanged<String> onOpenReporte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alertas = reportes.where((r) => r.nivelRiesgo == NivelRiesgo.alto).take(3).toList();

    if (alertas.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Alertas activas', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                  child: const Text('Ver todas', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: alertas.map((alerta) {
                return InkWell(
                  onTap: () => onOpenReporte(alerta.id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFEF5350).withOpacity(0.15),
                          child: const Icon(Icons.warning_amber, size: 16, color: Color(0xFFEF5350)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alerta.notas ?? 'Alerta en ${alerta.zonaProtegida.nombre ?? alerta.id}',
                                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Nivel de alerta: Alto',
                                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: const Color(0xFFEF5350)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini gráfico de barras
// ─────────────────────────────────────────────────────────────────────────────

class _MiniChart extends StatelessWidget {
  const _MiniChart({required this.data});

  final List<SerieMensual> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) return const SizedBox.shrink();

    final maxVal = data.map((d) => d.cantidad).reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((serie) {
        final ratio = maxVal == 0 ? 0.0 : serie.cantidad / maxVal;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(serie.cantidad.toString(), style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                Container(
                  height: 60 * ratio,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  serie.mes.split(' ').first,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _estadoLabel(EstadoReporte estado) {
  return switch (estado) {
    EstadoReporte.nuevo => 'Nuevo',
    EstadoReporte.revisado => 'En verificación',
    EstadoReporte.escalado => 'Confirmado',
  };
}

Color _colorForEstado(EstadoReporte estado) {
  return switch (estado) {
    EstadoReporte.nuevo => const Color(0xFF4CAF50),
    EstadoReporte.revisado => const Color(0xFFFFA726),
    EstadoReporte.escalado => const Color(0xFFEF5350),
  };
}

String _formatDate(DateTime date) {
  final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  return '${date.day} ${months[date.month - 1]} ${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _formatTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inHours < 24) {
    return 'Hoy, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  if (diff.inDays == 1) {
    return 'Ayer, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  return '${date.day}/${date.month.toString().padLeft(2, '0')}';
}
