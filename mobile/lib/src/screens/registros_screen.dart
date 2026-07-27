import 'package:flutter/material.dart';

import '../data/api_service.dart';
import '../data/mock_registros.dart';
import '../models/registro.dart';
import '../widgets/sync_status_badge.dart';
import 'record_detail_screen.dart';

/// Pantalla de registros con tabs: Todos los registros y Mis registros.
class RegistrosScreen extends StatefulWidget {
  const RegistrosScreen({super.key, required this.api, required this.onConnectionChanged});

  final MobileApiService api;
  final ValueChanged<bool> onConnectionChanged;

  @override
  State<RegistrosScreen> createState() => RegistrosScreenState();
}

class RegistrosScreenState extends State<RegistrosScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<Registro> _todos = [];
  List<Registro> _mios = [];
  bool _loading = true;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadRegistros();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadRegistros() async {
    setState(() => _loading = true);

    final result = await widget.api.getReportes(porPagina: 50);
    if (result.isSuccess) {
      final registros = result.data!.map(_mapRegistro).toList();
      setState(() {
        _todos = registros;
        // "Mis registros" = los que están pendientes de sincronizar (creados localmente)
        // + los sincronizados más recientes (últimos 7 días)
        final hace7Dias = DateTime.now().subtract(const Duration(days: 7));
        _mios = registros.where((r) =>
            r.estadoSync == EstadoSync.pendiente ||
            r.fecha.isAfter(hace7Dias)).toList();
        _online = true;
        _loading = false;
      });
      widget.onConnectionChanged(true);
    } else {
      setState(() {
        _todos = mockRegistros;
        _mios = mockRegistros;
        _online = false;
        _loading = false;
      });
      widget.onConnectionChanged(false);
    }
  }

  void addLocalRegistro(Registro registro) {
    setState(() {
      _todos.insert(0, registro);
      _mios.insert(0, registro);
    });
  }

  Registro _mapRegistro(Map<String, dynamic> json) {
    // Combinar fecha_creacion + hora_creacion para obtener DateTime completo
    final fechaStr = json['fecha_creacion']?.toString() ?? '';
    final horaStr = json['hora_creacion']?.toString() ?? '00:00:00';
    DateTime fecha;
    try {
      fecha = DateTime.parse('${fechaStr}T$horaStr');
    } catch (_) {
      fecha = DateTime.tryParse(fechaStr) ?? DateTime.now();
    }

    return Registro(
      id: json['codigo'] as String? ?? '',
      fecha: fecha,
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
      contacto: (json['alias_informante'] != null || json['celular_informante'] != null)
          ? ContactoOpcional(
              alias: json['alias_informante'] as String?,
              celular: json['celular_informante'] as String?,
            )
          : null,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text('Registros', style: theme.textTheme.headlineSmall),
                const Spacer(),
                if (!_online)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Offline', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Todos (${_todos.length})'),
                  Tab(text: 'Mis registros (${_mios.length})'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _RegistrosList(registros: _todos, onRefresh: loadRegistros, api: widget.api),
                      _RegistrosList(registros: _mios, onRefresh: loadRegistros, api: widget.api),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RegistrosList extends StatelessWidget {
  const _RegistrosList({required this.registros, required this.onRefresh, required this.api});

  final List<Registro> registros;
  final Future<void> Function() onRefresh;
  final MobileApiService api;

  @override
  Widget build(BuildContext context) {
    if (registros.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('Sin registros', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Los reportes aparecerán aquí',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: registros.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final registro = registros[index];
          return _RegistroCard(
            registro: registro,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RecordDetailScreen(registro: registro, api: api)),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RegistroCard extends StatelessWidget {
  const _RegistroCard({required this.registro, required this.onTap});

  final Registro registro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final riskColor = switch (registro.nivelRiesgo) {
      NivelRiesgo.alto => Colors.red,
      NivelRiesgo.medio => Colors.orange,
      NivelRiesgo.bajo => Colors.green,
      null => theme.colorScheme.outline,
    };

    final riskLabel = switch (registro.nivelRiesgo) {
      NivelRiesgo.alto => 'Alto',
      NivelRiesgo.medio => 'Medio',
      NivelRiesgo.bajo => 'Bajo',
      null => null,
    };

    final dragaLabel = switch (registro.tamanoDraga) {
      TamanoDraga.pequena => 'Pequeña',
      TamanoDraga.mediana => 'Mediana',
      TamanoDraga.grande => 'Grande',
    };

    // Mostrar ID corto (últimos 8 caracteres)
    final shortId = registro.id.length > 8
        ? '...${registro.id.substring(registro.id.length - 8)}'
        : registro.id;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: fecha + estado sync
              Row(
                children: [
                  // Icono de riesgo
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      registro.nivelRiesgo == NivelRiesgo.alto
                          ? Icons.warning_rounded
                          : Icons.water_drop_outlined,
                      color: riskColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(registro.fecha),
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          shortId,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge sync
                  SyncStatusBadge(estado: registro.estadoSync),
                ],
              ),

              const SizedBox(height: 12),

              // Fila de datos: ubicación, draga, riesgo
              Row(
                children: [
                  // Ubicación
                  Expanded(
                    child: _MiniInfo(
                      icon: Icons.location_on_outlined,
                      label: '${registro.ubicacion.lat.toStringAsFixed(2)}, ${registro.ubicacion.lng.toStringAsFixed(2)}',
                    ),
                  ),
                  // Draga
                  _MiniInfo(
                    icon: Icons.directions_boat_outlined,
                    label: dragaLabel,
                  ),
                ],
              ),

              // Fila inferior: mercurio + riesgo
              if (registro.mercurioEstimadoKg != null || riskLabel != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (registro.mercurioEstimadoKg != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.science_outlined, size: 12, color: Colors.purple),
                            const SizedBox(width: 4),
                            Text(
                              'Hg: ${registro.mercurioEstimadoKg!.toStringAsFixed(1)} kg',
                              style: const TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    if (registro.mercurioEstimadoKg != null && riskLabel != null)
                      const SizedBox(width: 8),
                    if (riskLabel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, size: 12, color: riskColor),
                            const SizedBox(width: 4),
                            Text(
                              'Riesgo $riskLabel',
                              style: TextStyle(fontSize: 11, color: riskColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Pendiente de análisis',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
