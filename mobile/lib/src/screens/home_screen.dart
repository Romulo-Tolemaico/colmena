import 'package:flutter/material.dart';

import '../data/mock_registros.dart';
import '../models/registro.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/sync_status_badge.dart';
import 'camera_screen.dart';
import 'estimation_screen.dart';
import 'record_detail_screen.dart';
import 'report_result_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registros = mockRegistros;
    final pendientes = registros.where((r) => r.estadoSync == EstadoSync.pendiente).length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con logo e indicador de conexión
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.hive_outlined, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Colmena', style: theme.textTheme.titleLarge),
                        Text('Monitor comunitario', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const ConnectionIndicator(isOnline: true),
                ],
              ),

              const SizedBox(height: 24),

              // Barra de sincronización si hay pendientes
              if (pendientes > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_upload_outlined, color: Colors.orange, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$pendientes registro${pendientes > 1 ? 's' : ''} pendiente${pendientes > 1 ? 's' : ''}',
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text('Se sincronizarán cuando haya señal', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: const Text('Sincronizar', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),

              // Título de la lista
              Text('Mis registros', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '${registros.length} registro${registros.length != 1 ? 's' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),

              // Lista de registros
              Expanded(
                child: registros.isEmpty
                    ? _EmptyState()
                    : ListView.separated(
                        itemCount: registros.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final registro = registros[index];
                          return _RegistroCard(
                            registro: registro,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RecordDetailScreen(registro: registro),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),

      // Botón grande "Nuevo registro"
      floatingActionButton: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FloatingActionButton.extended(
            onPressed: () async {
              // Flujo: Cámara → Estimación → Resultado
              final photos = await Navigator.of(context).push<List<String>>(
                MaterialPageRoute(builder: (_) => const CameraScreen()),
              );
              if (photos == null || photos.isEmpty || !context.mounted) return;

              final estimation = await Navigator.of(context).push<Map<String, dynamic>>(
                MaterialPageRoute(builder: (_) => EstimationScreen(fotos: photos)),
              );
              if (estimation == null || !context.mounted) return;

              // Crear registro mock con resultado simulado del agente
              final mockResult = Registro(
                id: 'REG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                fecha: DateTime.now(),
                ubicacion: const Ubicacion(lat: -11.4162, lng: -67.5441),
                fotos: photos,
                tamanoDraga: estimation['tamanoDraga'] as TamanoDraga? ?? TamanoDraga.mediana,
                tiempoOperando: estimation['tiempoOperando'] as TiempoOperando? ?? TiempoOperando.variosDias,
                indicadores: IndicadoresVisibles(
                  personasVisibles: estimation['personasVisibles'] as bool? ?? false,
                  motobombasVisibles: estimation['motobombasVisibles'] as bool? ?? false,
                ),
                estadoSync: EstadoSync.pendiente,
                notas: estimation['notas'] as String?,
                // Simulación de resultado del agente
                mercurioEstimadoKg: 14.7,
                zonaProtegida: const ZonaProtegida(esZonaProtegida: true, nombre: 'Reserva Manuripi'),
                normativaCitada: const ['Ley 1333', 'D.S. 28592'],
                danoEconomicoEstimado: 52000,
                nivelRiesgo: NivelRiesgo.alto,
                estadoReporte: EstadoReporte.nuevo,
              );

              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ReportResultScreen(registro: mockResult)),
              );
            },
            icon: const Icon(Icons.camera_alt_outlined, size: 24),
            label: const Text('Nuevo registro', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            extendedPadding: const EdgeInsets.symmetric(horizontal: 32),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Sin registros aún', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Toca "Nuevo registro" para capturar\ntu primera evidencia',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _RegistroCard extends StatelessWidget {
  const _RegistroCard({required this.registro, required this.onTap});

  final Registro registro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Miniatura de foto (placeholder)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.image_outlined, color: theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 14),
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(registro.id, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        SyncStatusBadge(estado: registro.estadoSync),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(registro.fecha),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            registro.ubicacion.toString(),
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (registro.nivelRiesgo != null) ...[
                          const SizedBox(width: 8),
                          _RiskDot(riesgo: registro.nivelRiesgo!),
                        ],
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

class _RiskDot extends StatelessWidget {
  const _RiskDot({required this.riesgo});

  final NivelRiesgo riesgo;

  @override
  Widget build(BuildContext context) {
    final color = switch (riesgo) {
      NivelRiesgo.bajo => Colors.green,
      NivelRiesgo.medio => Colors.orange,
      NivelRiesgo.alto => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        switch (riesgo) {
          NivelRiesgo.bajo => 'Bajo',
          NivelRiesgo.medio => 'Medio',
          NivelRiesgo.alto => 'Alto',
        },
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
  return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
