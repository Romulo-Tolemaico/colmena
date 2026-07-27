import 'dart:html' as html;

import 'package:flutter/material.dart';

import '../models/reporte.dart';
import 'map_widget.dart';

class ReportDetailPanel extends StatefulWidget {
  const ReportDetailPanel({
    super.key,
    required this.reporte,
    required this.onClose,
    this.onCambiarEstado,
    this.onGenerarPdf,
    this.onCargarFotos,
  });

  final Reporte reporte;
  final VoidCallback onClose;
  final Future<void> Function(String codigo, String nuevoEstado)? onCambiarEstado;
  final Future<String?> Function(String codigo)? onGenerarPdf;
  final Future<List<String>> Function(String codigo)? onCargarFotos;

  @override
  State<ReportDetailPanel> createState() => _ReportDetailPanelState();
}

class _ReportDetailPanelState extends State<ReportDetailPanel> {
  late EstadoReporte _estado;
  List<String> _fotos = [];

  @override
  void initState() {
    super.initState();
    _estado = widget.reporte.estado;
    _cargarFotos();
  }

  @override
  void didUpdateWidget(covariant ReportDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reporte.id != widget.reporte.id) {
      _estado = widget.reporte.estado;
      _cargarFotos();
    }
  }

  Future<void> _cargarFotos() async {
    if (widget.onCargarFotos != null) {
      final fotos = await widget.onCargarFotos!(widget.reporte.id);
      if (mounted) setState(() => _fotos = fotos);
    }
  }

  void _changeEstado(EstadoReporte nuevoEstado) {
    setState(() => _estado = nuevoEstado);
    final estadoCodigo = switch (nuevoEstado) {
      EstadoReporte.nuevo => 'nuevo',
      EstadoReporte.revisado => 'revisado',
      EstadoReporte.escalado => 'escalado',
    };
    widget.onCambiarEstado?.call(widget.reporte.id, estadoCodigo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reporte = widget.reporte;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Volver',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Detalle del reporte', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      Text(reporte.id, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                _EstadoChip(estado: _estado),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () async {
                    if (widget.onGenerarPdf != null) {
                      final url = await widget.onGenerarPdf!(widget.reporte.id);
                      if (url != null && context.mounted) {
                        _abrirUrl(url);
                      }
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('PDF'),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: isWide ? _buildWideLayout(theme, reporte) : _buildNarrowLayout(theme, reporte),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout(ThemeData theme, Reporte reporte) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna izquierda: mapa + evidencia
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mapa grande
                Text('Ubicación', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('${reporte.ubicacion.lat.toStringAsFixed(6)}, ${reporte.ubicacion.lng.toStringAsFixed(6)}', style: theme.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(height: 280, child: MiniMapWidget(reporte: reporte)),
                const SizedBox(height: 24),

                // Evidencia fotográfica
                Text('Evidencia fotográfica', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildFotosSection(theme, reporte),
                const SizedBox(height: 24),

                // Notas
                if (reporte.notas != null && reporte.notas!.isNotEmpty) ...[
                  Text('Notas del monitor', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(reporte.notas!, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Divider vertical
        Container(width: 1, color: theme.colorScheme.outlineVariant),

        // Columna derecha: datos + acciones
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildDetailsColumn(theme, reporte),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(ThemeData theme, Reporte reporte) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 200, child: MiniMapWidget(reporte: reporte)),
          const SizedBox(height: 20),
          _buildFotosSection(theme, reporte),
          const SizedBox(height: 20),
          _buildDetailsColumn(theme, reporte),
        ],
      ),
    );
  }

  Widget _buildFotosSection(ThemeData theme, Reporte reporte) {
    if (_fotos.isNotEmpty) {
      return SizedBox(
        height: 180,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _fotos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) => ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(_fotos[index], height: 180, width: 260, fit: BoxFit.cover),
          ),
        ),
      );
    }
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 36, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 6),
          Text('Sin fotos adjuntas', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildDetailsColumn(ThemeData theme, Reporte reporte) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estado y cambio
        Text('Estado y clasificación', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text('Cambiar estado:', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _EstadoButton(label: 'Nuevo', estado: EstadoReporte.nuevo, currentEstado: _estado, onPressed: () => _changeEstado(EstadoReporte.nuevo)),
            _EstadoButton(label: 'Revisado', estado: EstadoReporte.revisado, currentEstado: _estado, onPressed: () => _changeEstado(EstadoReporte.revisado)),
            _EstadoButton(label: 'Escalado', estado: EstadoReporte.escalado, currentEstado: _estado, onPressed: () => _changeEstado(EstadoReporte.escalado)),
          ],
        ),
        const SizedBox(height: 20),

        // Contacto
        Row(
          children: [
            Icon(
              reporte.tipoContacto == TipoContacto.anonimo ? Icons.visibility_off_outlined : Icons.person_outlined,
              size: 18, color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              reporte.tipoContacto == TipoContacto.anonimo ? 'Reporte anónimo' : 'Con contacto: ${reporte.contacto?.alias ?? ''}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        if (reporte.contacto?.celular != null)
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 4),
            child: Text('Tel: ${reporte.contacto!.celular}', style: theme.textTheme.bodySmall),
          ),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 16),

        // Impacto
        Text('Impacto estimado', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _ImpactRow(icon: Icons.science_outlined, label: 'Mercurio', value: '${reporte.mercurioEstimadoKg.toStringAsFixed(1)} kg'),
        _ImpactRow(icon: Icons.attach_money, label: 'Daño económico', value: 'Bs ${reporte.danoEconomicoEstimado.toStringAsFixed(0)}'),
        _ImpactRow(icon: Icons.warning_amber, label: 'Riesgo', value: _riskLabel(reporte.nivelRiesgo)),
        _ImpactRow(icon: Icons.shield_outlined, label: 'Zona protegida', value: reporte.zonaProtegida.esZonaProtegida ? 'Sí — ${reporte.zonaProtegida.nombre ?? ''}' : 'No'),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 16),

        // Datos capturados
        Text('Datos capturados', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _ImpactRow(icon: Icons.directions_boat_outlined, label: 'Tamaño draga', value: _dragaLabel(reporte.tamanoDraga)),
        _ImpactRow(icon: Icons.access_time, label: 'Tiempo operando', value: _tiempoLabel(reporte.tiempoOperando)),
        _ImpactRow(icon: Icons.people_outlined, label: 'Personas visibles', value: reporte.indicadores.personasVisibles ? 'Sí' : 'No'),
        _ImpactRow(icon: Icons.engineering_outlined, label: 'Motobombas', value: reporte.indicadores.motobombasVisibles ? 'Sí' : 'No'),

        // Normativa
        if (reporte.normativaCitada.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Text('Normativa citada', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...reporte.normativaCitada.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.gavel, size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Flexible(child: Text(n, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});

  final EstadoReporte estado;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (estado) {
      EstadoReporte.nuevo => (const Color(0xFF4CAF50), 'Nuevo'),
      EstadoReporte.revisado => (const Color(0xFFFFA726), 'Revisado'),
      EstadoReporte.escalado => (const Color(0xFFEF5350), 'Escalado'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _EstadoButton extends StatelessWidget {
  const _EstadoButton({required this.label, required this.estado, required this.currentEstado, required this.onPressed});

  final String label;
  final EstadoReporte estado;
  final EstadoReporte currentEstado;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final isActive = estado == currentEstado;
    return OutlinedButton(
      onPressed: isActive ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(0, 32),
        backgroundColor: isActive ? Theme.of(context).colorScheme.primaryContainer : null,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _ImpactRow extends StatelessWidget {
  const _ImpactRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text('$label: ', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Flexible(child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
      ],
    );
  }
}

String _riskLabel(NivelRiesgo risk) {
  return switch (risk) {
    NivelRiesgo.bajo => 'Bajo',
    NivelRiesgo.medio => 'Medio',
    NivelRiesgo.alto => 'Alto',
  };
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

void _abrirUrl(String url) {
  html.window.open(url, '_blank');
}
