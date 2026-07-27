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
          Text('Historial de denuncias', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            '${reportes.length} registros encontrados',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
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
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
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

class _ReporteCard extends StatefulWidget {
  const _ReporteCard({required this.reporte, required this.onTap});

  final Reporte reporte;
  final VoidCallback onTap;

  @override
  State<_ReporteCard> createState() => _ReporteCardState();
}

class _ReporteCardState extends State<_ReporteCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reporte = widget.reporte;

    final riskColor = switch (reporte.nivelRiesgo) {
      NivelRiesgo.alto => Colors.red,
      NivelRiesgo.medio => Colors.orange,
      NivelRiesgo.bajo => Colors.green,
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _hovered ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15) : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered ? theme.colorScheme.primary.withValues(alpha: 0.3) : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered ? theme.colorScheme.primary.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
                blurRadius: _hovered ? 16 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: icono riesgo + fecha + ubicación + estado
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [riskColor.withValues(alpha: 0.15), riskColor.withValues(alpha: 0.05)],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      reporte.nivelRiesgo == NivelRiesgo.alto ? Icons.warning_rounded : Icons.water_drop_outlined,
                      color: riskColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(reporte.fecha),
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 13, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 3),
                            Text(
                              '${reporte.ubicacion.lat.toStringAsFixed(4)}, ${reporte.ubicacion.lng.toStringAsFixed(4)}',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _EstadoBadge(estado: reporte.estado),
                ],
              ),

              const SizedBox(height: 14),

              // Chips modernos con color
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ModernChip(icon: Icons.directions_boat_outlined, label: _dragaLabel(reporte.tamanoDraga), color: const Color(0xFF1565C0)),
                  _ModernChip(icon: Icons.access_time_outlined, label: _tiempoLabel(reporte.tiempoOperando), color: const Color(0xFF6A1B9A)),
                  if (reporte.indicadores.personasVisibles)
                    _ModernChip(icon: Icons.people_outlined, label: 'Personas', color: const Color(0xFFE65100)),
                  if (reporte.indicadores.motobombasVisibles)
                    _ModernChip(icon: Icons.engineering_outlined, label: 'Motobombas', color: const Color(0xFF2E7D32)),
                  if (reporte.mercurioEstimadoKg > 0)
                    _ModernChip(icon: Icons.science_outlined, label: '${reporte.mercurioEstimadoKg.toStringAsFixed(1)} kg Hg', color: Colors.red),
                ],
              ),

              // Notas
              if (reporte.notas != null && reporte.notas!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.format_quote_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
                      const SizedBox(width: 8),
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
                ),
              ],

              // Footer
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    reporte.tipoContacto == TipoContacto.anonimo ? Icons.visibility_off_outlined : Icons.person_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    reporte.tipoContacto == TipoContacto.anonimo ? 'Anónimo' : 'Con contacto',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(fontSize: 12, color: _hovered ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                    child: const Text('Ver detalle'),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: _hovered ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class _ModernChip extends StatelessWidget {
  const _ModernChip({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

Color _colorForEstado(EstadoReporte estado) {
  return switch (estado) {
    EstadoReporte.nuevo => const Color(0xFF4CAF50),
    EstadoReporte.revisado => const Color(0xFFFFA726),
    EstadoReporte.escalado => const Color(0xFFEF5350),
  };
}

String _formatDate(DateTime date) {
  final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
