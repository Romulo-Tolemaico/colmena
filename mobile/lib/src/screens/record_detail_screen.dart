import 'package:flutter/material.dart';

import '../models/registro.dart';
import '../widgets/sync_status_badge.dart';

/// Pantalla de detalle de un registro existente (solo lectura).
/// Muestra toda la información capturada y, si fue analizado, los resultados del agente.
class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.registro});

  final Registro registro;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(registro.id),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: SyncStatusBadge(estado: registro.estadoSync)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto placeholder
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    '${registro.fotos.length} foto${registro.fotos.length != 1 ? 's' : ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Fecha y hora
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Fecha',
              value: _formatDateTime(registro.fecha),
            ),

            // Ubicación
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Ubicación',
              value: registro.ubicacion.toString(),
            ),

            // Tamaño de draga
            _InfoRow(
              icon: Icons.directions_boat_outlined,
              label: 'Tamaño de draga',
              value: _dragaLabel(registro.tamanoDraga),
            ),

            // Tiempo operando
            _InfoRow(
              icon: Icons.access_time_outlined,
              label: 'Tiempo operando',
              value: _tiempoLabel(registro.tiempoOperando),
            ),

            // Indicadores
            _InfoRow(
              icon: Icons.visibility_outlined,
              label: 'Indicadores',
              value: _indicadoresLabel(registro.indicadores),
            ),

            // Notas
            if (registro.notas != null && registro.notas!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.notes_outlined,
                label: 'Notas',
                value: registro.notas!,
              ),
            ],

            // Divider si fue analizado
            if (registro.fueAnalizado) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              Text('Resultado del análisis', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // Nivel de riesgo
              if (registro.nivelRiesgo != null)
                _RiskBadge(riesgo: registro.nivelRiesgo!),

              const SizedBox(height: 12),

              // Mercurio
              if (registro.mercurioEstimadoKg != null)
                _InfoRow(
                  icon: Icons.science_outlined,
                  label: 'Mercurio estimado',
                  value: '${registro.mercurioEstimadoKg!.toStringAsFixed(1)} kg',
                ),

              // Daño económico
              if (registro.danoEconomicoEstimado != null)
                _InfoRow(
                  icon: Icons.attach_money,
                  label: 'Daño económico',
                  value: 'Bs ${registro.danoEconomicoEstimado!.toStringAsFixed(0)}',
                ),

              // Zona protegida
              if (registro.zonaProtegida != null)
                _InfoRow(
                  icon: Icons.shield_outlined,
                  label: 'Zona protegida',
                  value: registro.zonaProtegida!.esZonaProtegida
                      ? 'Sí — ${registro.zonaProtegida!.nombre ?? 'Sin nombre'}'
                      : 'No',
                ),

              // Normativa
              if (registro.normativaCitada != null && registro.normativaCitada!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Normativa citada', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                ...registro.normativaCitada!.map((n) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.gavel, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text(n, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    )),
              ],

              // Estado del reporte
              if (registro.estadoReporte != null) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.flag_outlined,
                  label: 'Estado',
                  value: _estadoLabel(registro.estadoReporte!),
                ),
              ],
            ] else ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top_outlined, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pendiente de análisis', style: theme.textTheme.titleSmall),
                          Text(
                            'Se analizará automáticamente al sincronizar.',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Contacto
            if (registro.contacto != null && !registro.contacto!.isEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Text('Contacto registrado', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              if (registro.contacto!.alias != null)
                _InfoRow(icon: Icons.person_outlined, label: 'Alias', value: registro.contacto!.alias!),
              if (registro.contacto!.celular != null)
                _InfoRow(icon: Icons.phone_outlined, label: 'Celular', value: registro.contacto!.celular!),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.riesgo});

  final NivelRiesgo riesgo;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (riesgo) {
      NivelRiesgo.bajo => (Colors.green, 'Riesgo bajo'),
      NivelRiesgo.medio => (Colors.orange, 'Riesgo medio'),
      NivelRiesgo.alto => (Colors.red, 'Riesgo alto'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

String _formatDateTime(DateTime date) {
  final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

String _dragaLabel(TamanoDraga tamano) {
  return switch (tamano) {
    TamanoDraga.pequena => 'Pequeña',
    TamanoDraga.mediana => 'Mediana',
    TamanoDraga.grande => 'Grande',
  };
}

String _tiempoLabel(TiempoOperando tiempo) {
  return switch (tiempo) {
    TiempoOperando.menosUnDia => 'Menos de 1 día',
    TiempoOperando.variosDias => 'Varios días',
    TiempoOperando.masUnaSemana => 'Más de una semana',
  };
}

String _indicadoresLabel(IndicadoresVisibles indicadores) {
  final items = <String>[];
  if (indicadores.personasVisibles) items.add('Personas');
  if (indicadores.motobombasVisibles) items.add('Motobombas');
  return items.isEmpty ? 'Ninguno' : items.join(', ');
}

String _estadoLabel(EstadoReporte estado) {
  return switch (estado) {
    EstadoReporte.nuevo => 'Nuevo',
    EstadoReporte.revisado => 'Revisado',
    EstadoReporte.escalado => 'Escalado',
  };
}
