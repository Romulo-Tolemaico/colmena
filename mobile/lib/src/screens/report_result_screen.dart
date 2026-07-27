import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api_service.dart';
import '../models/registro.dart';

/// Pantalla de resultado después de generar el reporte.
/// Muestra impacto estimado, zona protegida, normativa, contacto opcional y PDF.
class ReportResultScreen extends StatefulWidget {
  const ReportResultScreen({super.key, required this.registro, required this.api});

  final Registro registro;
  final MobileApiService api;

  @override
  State<ReportResultScreen> createState() => _ReportResultScreenState();
}

class _ReportResultScreenState extends State<ReportResultScreen> {
  final _aliasController = TextEditingController();
  final _celularController = TextEditingController();
  bool _showContactForm = false;
  bool _downloadingPdf = false;

  @override
  void dispose() {
    _aliasController.dispose();
    _celularController.dispose();
    super.dispose();
  }

  Future<void> _downloadPdf() async {
    setState(() => _downloadingPdf = true);
    final result = await widget.api.generarPdf(widget.registro.id);
    setState(() => _downloadingPdf = false);

    if (!mounted) return;

    if (result.isSuccess && result.data!.isNotEmpty) {
      final uri = Uri.parse(result.data!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showSnack('PDF generado pero no se pudo abrir: ${result.data}');
      }
    } else {
      _showSnack(result.error ?? 'Error al generar el PDF');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _finish(BuildContext context, {required bool anonymous}) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registro = widget.registro;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte generado'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de éxito
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text('Reporte registrado', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${registro.id.length > 12 ? '${registro.id.substring(0, 12)}...' : registro.id}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Indicador de impacto (mercurio)
            if (registro.mercurioEstimadoKg != null) ...[
              Text('Impacto estimado', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _MercuryIndicator(kg: registro.mercurioEstimadoKg!),
              const SizedBox(height: 20),
            ],

            // Zona protegida
            if (registro.zonaProtegida != null && registro.zonaProtegida!.esZonaProtegida) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield, color: Colors.red, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zona protegida',
                            style: theme.textTheme.titleSmall?.copyWith(color: Colors.red.shade700),
                          ),
                          Text(
                            registro.zonaProtegida!.nombre ?? 'Territorio indígena / área protegida',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Normativa citada
            if (registro.normativaCitada != null && registro.normativaCitada!.isNotEmpty) ...[
              Text('Normativa aplicable', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              ...registro.normativaCitada!.map((n) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.gavel, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(n, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // Daño económico
            if (registro.danoEconomicoEstimado != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.attach_money, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Daño económico estimado', style: theme.textTheme.bodySmall),
                            Text(
                              'Bs ${registro.danoEconomicoEstimado!.toStringAsFixed(0)}',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Acciones
            const SizedBox(height: 24),

            // Botón PDF real
            FilledButton.icon(
              onPressed: _downloadingPdf ? null : _downloadPdf,
              icon: _downloadingPdf
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_downloadingPdf ? 'Generando PDF...' : 'Descargar reporte PDF'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _finish(context, anonymous: true),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Volver al inicio'),
            ),

            // Nota de metodología
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Esta estimación se basa en observación a distancia segura y no reemplaza una medición técnica de campo.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MercuryIndicator extends StatelessWidget {
  const _MercuryIndicator({required this.kg});

  final double kg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = (kg / 30).clamp(0.0, 1.0);
    final color = Color.lerp(Colors.orange, Colors.red, ratio)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science_outlined, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text('Mercurio estimado liberado', style: theme.textTheme.bodyMedium)),
                Text(
                  '${kg.toStringAsFixed(1)} kg',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ratio,
                backgroundColor: color.withValues(alpha: 0.12),
                color: color,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0 kg', style: theme.textTheme.bodySmall),
                Text('30+ kg', style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
