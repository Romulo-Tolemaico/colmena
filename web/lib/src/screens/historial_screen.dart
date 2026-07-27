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
          Text(
            '${reportes.length} registros encontrados',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : reportes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text('No hay reportes', style: theme.textTheme.titleMedium),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: reportes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final reporte = reportes[index];
                          return _ReporteCard(reporte: reporte, onTap: () => onOpenReporte(reporte.id));
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ReporteCard extends StatelessWidget {
  const _ReporteCard({required this.reporte, required this.onTap});

  final Reporte reporte;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicador de estado/riesgo
              Container(
                width: 4,
                height: 80,
                decoration: BoxDecoration(
                  color: _colorForEstado(reporte.estado),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 14),

              // Contenido principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila 1: ID + Estado + Tipo contacto
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reporte.id.length > 20 ? '${reporte.id.substring(0, 8)}...' : reporte.id,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _EstadoBadge(estado: reporte.estado),
                        const SizedBox(width: 8),
                        Icon(
                          reporte.tipoContacto == TipoContacto.anonimo ? Icons.visibility_off : Icons.person,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Fila 2: Fecha + Ubicación
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(_formatDate(reporte.fecha), style: theme.textTheme.bodySmall),
                        const SizedBox(width: 16),
                        Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${reporte.ubicacion.lat.toStringAsFixed(4)}, ${reporte.ubicacion.lng.toStringAsFixed(4)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Fila 3: Draga + Tiempo + Indicadores
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _InfoChip(icon: Icons.directions_boat_outlined, label: _dragaLabel(reporte.tamanoDraga)),
                        _InfoChip(icon: Icons.access_time, label: _tiempoLabel(reporte.tiempoOperando)),
                        if (reporte.indicadores.personasVisibles)
                          _InfoChip(icon: Icons.people_outlined, label: 'Personas'),
                        if (reporte.indicadores.motobombasVisibles)
                          _InfoChip(icon: Icons.engineering_outlined, label: 'Motobombas'),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Fila 4: Mercurio + Notas preview
                    Row(
                      children: [
                        if (reporte.mercurioEstimadoKg > 0) ...[
                          Icon(Icons.science_outlined, size: 14, color: Colors.red.shade400),
                          const SizedBox(width: 4),
                          Text(
                            '${reporte.mercurioEstimadoKg.toStringAsFixed(1)} kg Hg',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.red.shade400, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (reporte.notas != null && reporte.notas!.isNotEmpty)
                          Expanded(
                            child: Text(
                              reporte.notas!,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.estado});

  final EstadoReporte estado;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (estado) {
      EstadoReporte.nuevo => (const Color(0xFF4CAF50), 'Nuevo'),
      EstadoReporte.revisado => (const Color(0xFFFFA726), 'Revisado'),
      EstadoReporte.escalado => (const Color(0xFFEF5350), 'Escalado'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}

Color _colorForEstado(EstadoReporte estado) {
  return switch (estado) {
    EstadoReporte.nuevo => const Color(0xFF4CAF50),
    EstadoReporte.revisado => const Color(0xFFFFA726),
    EstadoReporte.escalado => const Color(0xFFEF5350),
  };
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _dragaLabel(TamanoDraga t) => switch (t) {
      TamanoDraga.pequena => 'Pequeña',
      TamanoDraga.mediana => 'Mediana',
      TamanoDraga.grande => 'Grande',
    };

String _tiempoLabel(TiempoOperando t) => switch (t) {
      TiempoOperando.menosUnDia => '<1 día',
      TiempoOperando.variosDias => 'Varios días',
      TiempoOperando.masUnaSemana => '+1 semana',
    };
