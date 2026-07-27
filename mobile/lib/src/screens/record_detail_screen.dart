import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api_service.dart';
import '../models/registro.dart';
import '../widgets/sync_status_badge.dart';

/// Pantalla de detalle de un registro.
/// Carga datos completos (evaluación + fotos) desde el servidor.
class RecordDetailScreen extends StatefulWidget {
  const RecordDetailScreen({super.key, required this.registro, required this.api});

  final Registro registro;
  final MobileApiService api;

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  late Registro _registro;
  List<String> _fotoUrls = [];
  bool _loadingDetail = true;
  bool _downloadingPdf = false;

  @override
  void initState() {
    super.initState();
    _registro = widget.registro;
    _loadFullDetail();
  }

  Future<void> _loadFullDetail() async {
    // Cargar detalle completo con evaluación
    final detailResult = await widget.api.getReporteDetalle(_registro.id);
    if (detailResult.isSuccess && mounted) {
      final d = detailResult.data!;
      final eval = d['evaluacion'] as Map<String, dynamic>?;

      final fechaStr = d['fecha_creacion']?.toString() ?? '';
      final horaStr = d['hora_creacion']?.toString() ?? '00:00:00';
      DateTime fecha;
      try {
        fecha = DateTime.parse('${fechaStr}T$horaStr');
      } catch (_) {
        fecha = _registro.fecha;
      }

      setState(() {
        _registro = Registro(
          id: d['codigo'] as String? ?? _registro.id,
          fecha: fecha,
          ubicacion: Ubicacion(
            lat: (d['latitud'] as num?)?.toDouble() ?? _registro.ubicacion.lat,
            lng: (d['longitud'] as num?)?.toDouble() ?? _registro.ubicacion.lng,
          ),
          fotos: _registro.fotos,
          tamanoDraga: _parseDraga(d['tamano_draga_codigo'] as String?),
          tiempoOperando: _parseTiempo(d['tiempo_operacion_codigo'] as String?),
          indicadores: IndicadoresVisibles(
            personasVisibles: d['personas_visibles'] as bool? ?? false,
            motobombasVisibles: d['motobombas_visibles'] as bool? ?? false,
          ),
          estadoSync: EstadoSync.sincronizado,
          notas: d['nota'] as String?,
          contacto: (d['alias_informante'] != null || d['celular_informante'] != null)
              ? ContactoOpcional(alias: d['alias_informante'] as String?, celular: d['celular_informante'] as String?)
              : null,
          mercurioEstimadoKg: (eval?['mercurio_estimado_kg'] as num?)?.toDouble(),
          zonaProtegida: eval?['zona_codigo'] != null
              ? ZonaProtegida(esZonaProtegida: true, nombre: eval!['zona_codigo'].toString())
              : null,
          normativaCitada: eval?['normativa_codigo'] != null ? [eval!['normativa_codigo'].toString()] : null,
          danoEconomicoEstimado: (eval?['dano_economico_estimado'] as num?)?.toDouble(),
          nivelRiesgo: _parseRiesgo(eval?['nivel_riesgo_codigo'] as String?),
          estadoReporte: _parseEstado(d['estado_codigo'] as String?),
        );
      });
    }

    // Cargar fotos
    final fotosResult = await widget.api.listarFotos(_registro.id);
    if (fotosResult.isSuccess && mounted) {
      setState(() => _fotoUrls = fotosResult.data!);
    }

    if (mounted) setState(() => _loadingDetail = false);
  }

  Future<void> _downloadPdf() async {
    setState(() => _downloadingPdf = true);
    final result = await widget.api.generarPdf(_registro.id);
    setState(() => _downloadingPdf = false);

    if (!mounted) return;
    if (result.isSuccess && result.data!.isNotEmpty) {
      final uri = Uri.parse(result.data!);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        try { await launchUrl(uri); } catch (_) {}
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Error al generar PDF'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  TamanoDraga _parseDraga(String? c) => switch (c) {
        'PEQUENA' => TamanoDraga.pequena,
        'GRANDE' => TamanoDraga.grande,
        _ => TamanoDraga.mediana,
      };
  TiempoOperando _parseTiempo(String? c) => switch (c) {
        'MENOS_1_DIA' => TiempoOperando.menosUnDia,
        'MAS_1_SEMANA' => TiempoOperando.masUnaSemana,
        _ => TiempoOperando.variosDias,
      };
  NivelRiesgo? _parseRiesgo(String? c) => switch (c) {
        'BAJO' => NivelRiesgo.bajo,
        'MEDIO' => NivelRiesgo.medio,
        'ALTO' => NivelRiesgo.alto,
        _ => null,
      };
  EstadoReporte? _parseEstado(String? c) => switch (c) {
        'nuevo' => EstadoReporte.nuevo,
        'revisado' => EstadoReporte.revisado,
        'escalado' => EstadoReporte.escalado,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = _registro;

    // ID corto para el AppBar
    final shortId = r.id.length > 12 ? '${r.id.substring(0, 8)}...' : r.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(shortId),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: SyncStatusBadge(estado: r.estadoSync)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mapa con ubicación
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(r.ubicacion.lat, r.ubicacion.lng),
                  initialZoom: 13,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.colmena.mobile',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(r.ubicacion.lat, r.ubicacion.lng),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.my_location, size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '${r.ubicacion.lat.toStringAsFixed(6)}, ${r.ubicacion.lng.toStringAsFixed(6)}',
                  style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Fotos
            if (_fotoUrls.isNotEmpty) ...[
              Text('Fotos de evidencia', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fotoUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _fotoUrls[index],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 120,
                          height: 120,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined, size: 32),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ] else if (_loadingDetail) ...[
              Container(
                height: 80,
                alignment: Alignment.center,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Cargando detalles...', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],

            const Divider(),
            const SizedBox(height: 12),

            // Info básica
            _InfoRow(icon: Icons.calendar_today_outlined, label: 'Fecha', value: _formatDateTime(r.fecha)),
            _InfoRow(icon: Icons.directions_boat_outlined, label: 'Tamaño de draga', value: _dragaLabel(r.tamanoDraga)),
            _InfoRow(icon: Icons.access_time_outlined, label: 'Tiempo operando', value: _tiempoLabel(r.tiempoOperando)),
            _InfoRow(icon: Icons.visibility_outlined, label: 'Indicadores', value: _indicadoresLabel(r.indicadores)),

            if (r.notas != null && r.notas!.isNotEmpty)
              _InfoRow(icon: Icons.notes_outlined, label: 'Notas', value: r.notas!),

            const SizedBox(height: 8),

            // Contacto
            _InfoRow(
              icon: Icons.person_outlined,
              label: 'Informante',
              value: (r.contacto != null && !r.contacto!.isEmpty)
                  ? '${r.contacto!.alias ?? ''} ${r.contacto!.celular != null ? '· ${r.contacto!.celular}' : ''}'.trim()
                  : 'Anónimo',
            ),

            // Evaluación / análisis
            if (r.fueAnalizado) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),

              Text('Resultado del análisis', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              if (r.nivelRiesgo != null) ...[
                _RiskBadge(riesgo: r.nivelRiesgo!),
                const SizedBox(height: 12),
              ],

              if (r.mercurioEstimadoKg != null)
                _InfoRow(icon: Icons.science_outlined, label: 'Mercurio estimado', value: '${r.mercurioEstimadoKg!.toStringAsFixed(1)} kg'),

              if (r.danoEconomicoEstimado != null)
                _InfoRow(icon: Icons.attach_money, label: 'Daño económico', value: 'Bs ${r.danoEconomicoEstimado!.toStringAsFixed(0)}'),

              if (r.zonaProtegida != null)
                _InfoRow(
                  icon: Icons.shield_outlined,
                  label: 'Zona protegida',
                  value: r.zonaProtegida!.esZonaProtegida ? 'Sí — ${r.zonaProtegida!.nombre ?? 'Sin nombre'}' : 'No',
                ),

              if (r.normativaCitada != null && r.normativaCitada!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Normativa citada', style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                ...r.normativaCitada!.map((n) => Padding(
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

              if (r.estadoReporte != null)
                _InfoRow(icon: Icons.flag_outlined, label: 'Estado', value: _estadoLabel(r.estadoReporte!)),
            ] else if (!_loadingDetail) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hourglass_top_outlined, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pendiente de análisis', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('Se analizará automáticamente.', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Botón descargar PDF
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _downloadingPdf ? null : _downloadPdf,
                icon: _downloadingPdf
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_downloadingPdf ? 'Generando...' : 'Descargar PDF'),
              ),
            ),
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

String _dragaLabel(TamanoDraga t) => switch (t) {
      TamanoDraga.pequena => 'Pequeña',
      TamanoDraga.mediana => 'Mediana',
      TamanoDraga.grande => 'Grande',
    };

String _tiempoLabel(TiempoOperando t) => switch (t) {
      TiempoOperando.menosUnDia => 'Menos de 1 día',
      TiempoOperando.variosDias => 'Varios días',
      TiempoOperando.masUnaSemana => 'Más de una semana',
    };

String _indicadoresLabel(IndicadoresVisibles i) {
  final items = <String>[];
  if (i.personasVisibles) items.add('Personas');
  if (i.motobombasVisibles) items.add('Motobombas');
  return items.isEmpty ? 'Ninguno reportado' : items.join(', ');
}

String _estadoLabel(EstadoReporte e) => switch (e) {
      EstadoReporte.nuevo => 'Nuevo',
      EstadoReporte.revisado => 'Revisado',
      EstadoReporte.escalado => 'Escalado',
    };
