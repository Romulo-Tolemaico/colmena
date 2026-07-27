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

    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Detalle del reporte', style: theme.textTheme.titleLarge),
                      Text(reporte.id, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Estado y tipo de contacto
                _DetailSection(
                  title: 'Estado y clasificación',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estado del reporte con botones para cambiar
                      Row(
                        children: [
                          Text('Estado: ', style: theme.textTheme.bodyMedium),
                          const SizedBox(width: 8),
                          _EstadoChip(estado: _estado),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Cambiar estado:', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          _EstadoButton(
                            label: 'Nuevo',
                            estado: EstadoReporte.nuevo,
                            currentEstado: _estado,
                            onPressed: () => _changeEstado(EstadoReporte.nuevo),
                          ),
                          _EstadoButton(
                            label: 'Revisado',
                            estado: EstadoReporte.revisado,
                            currentEstado: _estado,
                            onPressed: () => _changeEstado(EstadoReporte.revisado),
                          ),
                          _EstadoButton(
                            label: 'Escalado',
                            estado: EstadoReporte.escalado,
                            currentEstado: _estado,
                            onPressed: () => _changeEstado(EstadoReporte.escalado),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Tipo de contacto
                      Row(
                        children: [
                          Icon(
                            reporte.tipoContacto == TipoContacto.anonimo
                                ? Icons.visibility_off_outlined
                                : Icons.person_outlined,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            reporte.tipoContacto == TipoContacto.anonimo
                                ? 'Reporte anónimo'
                                : 'Con contacto: ${reporte.contacto?.alias ?? 'Sin alias'}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      if (reporte.contacto?.celular != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const SizedBox(width: 24),
                            Icon(Icons.phone_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(reporte.contacto!.celular!, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Ubicación y mapa
                _DetailSection(
                  title: 'Ubicación y contexto',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Latitud: ${reporte.ubicacion.lat.toStringAsFixed(4)}'),
                      Text('Longitud: ${reporte.ubicacion.lng.toStringAsFixed(4)}'),
                      const SizedBox(height: 8),
                      MiniMapWidget(reporte: reporte),
                    ],
                  ),
                ),

                // Impacto
                _DetailSection(
                  title: 'Impacto estimado',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ImpactRow(icon: Icons.science_outlined, label: 'Mercurio', value: '${reporte.mercurioEstimadoKg.toStringAsFixed(1)} kg'),
                      const SizedBox(height: 6),
                      _ImpactRow(icon: Icons.attach_money, label: 'Daño económico', value: 'Bs ${reporte.danoEconomicoEstimado.toStringAsFixed(0)}'),
                      const SizedBox(height: 6),
                      _ImpactRow(icon: Icons.warning_amber, label: 'Riesgo', value: _riskLabel(reporte.nivelRiesgo)),
                      const SizedBox(height: 6),
                      _ImpactRow(
                        icon: Icons.shield_outlined,
                        label: 'Zona protegida',
                        value: reporte.zonaProtegida.esZonaProtegida
                            ? 'Sí — ${reporte.zonaProtegida.nombre ?? ''}'
                            : 'No',
                      ),
                    ],
                  ),
                ),

                // Evidencia
                _DetailSection(
                  title: 'Evidencia',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_fotos.isNotEmpty)
                        SizedBox(
                          height: 160,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _fotos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) => ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(_fotos[index], height: 160, width: 220, fit: BoxFit.cover),
                            ),
                          ),
                        )
                      else if (reporte.fotos.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(reporte.fotos.first, fit: BoxFit.cover),
                          ),
                        )
                      else
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported_outlined, size: 32, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(height: 4),
                              Text('Sin fotos', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(reporte.notas ?? 'Sin notas adicionales.'),
                    ],
                  ),
                ),

                // Normativa citada
                if (reporte.normativaCitada.isNotEmpty)
                  _DetailSection(
                    title: 'Normativa citada',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: reporte.normativaCitada
                          .map((n) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.gavel, size: 14, color: theme.colorScheme.onSurfaceVariant),
                                    const SizedBox(width: 8),
                                    Text(n, style: theme.textTheme.bodyMedium),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),

                // Botón descargar PDF
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (widget.onGenerarPdf != null) {
                        final url = await widget.onGenerarPdf!(widget.reporte.id);
                        if (url != null && context.mounted) {
                          // Abrir PDF en nueva pestaña del navegador
                          _abrirUrl(url);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PDF generado. Abriendo en nueva pestaña...'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Generación de PDF no disponible.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Descargar reporte PDF'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

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

void _abrirUrl(String url) {
  html.window.open(url, '_blank');
}
