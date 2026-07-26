import 'package:flutter/material.dart';

import '../data/api_service.dart';
import '../data/mock_registros.dart';
import '../models/registro.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/sync_status_badge.dart';
import 'camera_screen.dart';
import 'estimation_screen.dart';
import 'record_detail_screen.dart';
import 'report_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MobileApiService _api = MobileApiService(
    // IP local de tu PC en WiFi — celular y PC deben estar en la misma red.
    // Si usas emulador Android, cambia a: http://10.0.2.2:3000/api/v1
    baseUrl: 'http://192.168.100.160:3000/api/v1',
  );

  List<Registro> _registros = [];
  bool _loading = true;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _loadRegistros();
  }

  Future<void> _loadRegistros() async {
    setState(() => _loading = true);

    final result = await _api.getReportes(porPagina: 50);
    if (result.isSuccess) {
      setState(() {
        _registros = result.data!.map(_mapRegistro).toList();
        _online = true;
        _loading = false;
      });
    } else {
      // Sin conexión — usar datos locales mock
      setState(() {
        _registros = mockRegistros;
        _online = false;
        _loading = false;
      });
    }
  }

  Registro _mapRegistro(Map<String, dynamic> json) {
    return Registro(
      id: json['codigo'] as String? ?? '',
      fecha: DateTime.tryParse(json['fecha_creacion']?.toString() ?? '') ?? DateTime.now(),
      ubicacion: Ubicacion(
        lat: (json['latitud'] as num?)?.toDouble() ?? 0.0,
        lng: (json['longitud'] as num?)?.toDouble() ?? 0.0,
      ),
      fotos: const [],
      tamanoDraga: _parseDraga(json['tamano_draga_codigo'] as String?),
      tiempoOperando: _parseTiempo(json['tiempo_operacion_codigo'] as String?),
      indicadores: IndicadoresVisibles(
        personasVisibles: json['personas_visibles'] as bool? ?? false,
        motobombasVisibles: json['motobombas_visibles'] as bool? ?? false,
      ),
      estadoSync: EstadoSync.sincronizado,
      notas: json['nota'] as String?,
      mercurioEstimadoKg: (json['evaluacion'] != null)
          ? (json['evaluacion']['mercurio_estimado_kg'] as num?)?.toDouble()
          : null,
      zonaProtegida: (json['evaluacion']?['zona_codigo'] != null)
          ? ZonaProtegida(esZonaProtegida: true, nombre: json['evaluacion']['zona_codigo'] as String?)
          : null,
      normativaCitada: json['evaluacion']?['normativa_codigo'] != null
          ? [json['evaluacion']['normativa_codigo'] as String]
          : null,
      danoEconomicoEstimado: null,
      nivelRiesgo: _parseRiesgo(json['evaluacion']?['nivel_riesgo_codigo'] as String?),
      estadoReporte: _parseEstado(json['estado_codigo'] as String?),
    );
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

  Future<void> _startNewReport() async {
    // Flujo: Cámara → Estimación → Enviar al API → Resultado
    final cameraResult = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (cameraResult == null || !mounted) return;

    final photos = (cameraResult['photos'] as List<dynamic>?)?.cast<String>() ?? [];
    if (photos.isEmpty) return;

    final lat = cameraResult['lat'] as double?;
    final lng = cameraResult['lng'] as double?;

    if (!mounted) return;
    final estimation = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => EstimationScreen(fotos: photos)),
    );
    if (estimation == null || !mounted) return;

    final tamanoDraga = estimation['tamanoDraga'] as TamanoDraga? ?? TamanoDraga.mediana;
    final tiempoOperando = estimation['tiempoOperando'] as TiempoOperando? ?? TiempoOperando.variosDias;
    final personasVisibles = estimation['personasVisibles'] as bool? ?? false;
    final motobombasVisibles = estimation['motobombasVisibles'] as bool? ?? false;
    final notas = estimation['notas'] as String?;

    // Enviar al API
    final result = await _api.enviarReporte(
      latitud: lat ?? -11.4162,
      longitud: lng ?? -67.5441,
      tamanoDraga: tamanoDraga,
      tiempoOperando: tiempoOperando,
      personasVisibles: personasVisibles,
      motobombasVisibles: motobombasVisibles,
      nota: notas,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      // Mostrar resultado con datos mock del agente (el análisis real es asíncrono)
      final mockResult = Registro(
        id: result.data!,
        fecha: DateTime.now(),
        ubicacion: Ubicacion(lat: lat ?? -11.4162, lng: lng ?? -67.5441),
        fotos: photos,
        tamanoDraga: tamanoDraga,
        tiempoOperando: tiempoOperando,
        indicadores: IndicadoresVisibles(
          personasVisibles: personasVisibles,
          motobombasVisibles: motobombasVisibles,
        ),
        estadoSync: EstadoSync.sincronizado,
        notas: notas,
        mercurioEstimadoKg: 14.7,
        zonaProtegida: const ZonaProtegida(esZonaProtegida: true, nombre: 'Reserva Manuripi'),
        normativaCitada: const ['Ley 1333', 'D.S. 28592'],
        danoEconomicoEstimado: 52000,
        nivelRiesgo: NivelRiesgo.alto,
        estadoReporte: EstadoReporte.nuevo,
      );

      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReportResultScreen(registro: mockResult)),
      );

      // Recargar lista
      _loadRegistros();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Error al enviar'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pendientes = _registros.where((r) => r.estadoSync == EstadoSync.pendiente).length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                  ConnectionIndicator(isOnline: _online),
                ],
              ),

              const SizedBox(height: 24),

              // Sync banner
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
                        onPressed: _loadRegistros,
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 14)),
                        child: const Text('Sincronizar', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),

              // Title
              Text('Mis registros', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                _loading ? 'Cargando...' : '${_registros.length} registro${_registros.length != 1 ? 's' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),

              // List
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _registros.isEmpty
                        ? _EmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadRegistros,
                            child: ListView.separated(
                              itemCount: _registros.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final registro = _registros[index];
                                return _RegistroCard(
                                  registro: registro,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => RecordDetailScreen(registro: registro)),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),

      // FAB
      floatingActionButton: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: FloatingActionButton.extended(
            onPressed: _startNewReport,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            registro.id.length > 8 ? registro.id.substring(0, 8) : registro.id,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
