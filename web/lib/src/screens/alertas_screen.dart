import 'package:flutter/material.dart';

import '../models/reporte.dart';

class AlertasScreen extends StatelessWidget {
  const AlertasScreen({super.key, required this.reportes, required this.onOpenReporte});

  final List<Reporte> reportes;
  final ValueChanged<String> onOpenReporte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alertas = reportes
        .where((r) => r.nivelRiesgo == NivelRiesgo.alto || r.estado == EstadoReporte.nuevo)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alertas activas', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${alertas.length} casos prioritarios que requieren atención',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                    const SizedBox(width: 6),
                    Text('${alertas.length}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: alertas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text('Sin alertas activas', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Todos los reportes han sido atendidos', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: alertas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final reporte = alertas[index];
                      return _AlertaCard(reporte: reporte, onTap: () => onOpenReporte(reporte.id));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AlertaCard extends StatelessWidget {
  const _AlertaCard({required this.reporte, required this.onTap});

  final Reporte reporte;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAlto = reporte.nivelRiesgo == NivelRiesgo.alto;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isAlto ? Colors.red : Colors.orange,
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: badge urgencia + estado + fecha
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isAlto ? Colors.red : Colors.orange).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAlto ? Icons.error : Icons.warning_amber,
                          size: 14,
                          color: isAlto ? Colors.red : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAlto ? 'Riesgo alto' : 'Nuevo',
                          style: TextStyle(
                            color: isAlto ? Colors.red : Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _EstadoBadge(estado: reporte.estado),
                  const Spacer(),
                  Text(
                    _formatDate(reporte.fecha),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Contenido principal
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ID
                        Text(
                          reporte.id.length > 20 ? '${reporte.id.substring(0, 8)}...' : reporte.id,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),

                        // Notas o descripción
                        Text(
                          reporte.notas ?? 'Sin notas — actividad detectada en zona de monitoreo',
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Info chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            _InfoChip(icon: Icons.location_on_outlined, label: '${reporte.ubicacion.lat.toStringAsFixed(2)}°, ${reporte.ubicacion.lng.toStringAsFixed(2)}°'),
                            _InfoChip(icon: Icons.directions_boat_outlined, label: _dragaLabel(reporte.tamanoDraga)),
                            _InfoChip(icon: Icons.access_time, label: _tiempoLabel(reporte.tiempoOperando)),
                            if (reporte.mercurioEstimadoKg > 0)
                              _InfoChip(icon: Icons.science_outlined, label: '${reporte.mercurioEstimadoKg.toStringAsFixed(1)} kg Hg'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonal(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('Revisar'),
                  ),
                ],
              ),

              // Indicadores visibles
              if (reporte.indicadores.personasVisibles || reporte.indicadores.motobombasVisibles) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (reporte.indicadores.personasVisibles)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('Personas visibles', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    if (reporte.indicadores.motobombasVisibles)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.engineering_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('Motobombas visibles', style: theme.textTheme.bodySmall),
                        ],
                      ),
                  ],
                ),
              ],

              // Tipo de contacto
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    reporte.tipoContacto == TipoContacto.anonimo ? Icons.visibility_off : Icons.person,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    reporte.tipoContacto == TipoContacto.anonimo ? 'Reporte anónimo' : 'Con contacto: ${reporte.contacto?.alias ?? ''}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
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
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
