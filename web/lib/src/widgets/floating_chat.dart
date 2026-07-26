import 'package:flutter/material.dart';

import '../models/reporte.dart';

/// Widget de chat flotante tipo burbuja.
/// Responde preguntas basándose en los datos de reportes cargados.
class FloatingChat extends StatefulWidget {
  const FloatingChat({super.key, this.reportes = const []});

  final List<Reporte> reportes;

  @override
  State<FloatingChat> createState() => _FloatingChatState();
}

class _FloatingChatState extends State<FloatingChat> {
  bool _isOpen = false;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(author: 'Colmena', text: '¡Hola! Soy el asistente de Colmena. Pregúntame sobre los reportes, zonas o mercurio estimado.', isBot: true),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(author: 'Tú', text: text, isBot: false));
      _controller.clear();
    });

    // Generar respuesta inteligente basada en los datos
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        final response = _generateResponse(text);
        setState(() {
          _messages.add(_ChatMessage(author: 'Colmena', text: response, isBot: true));
        });
        _scrollToBottom();
      }
    });

    _scrollToBottom();
  }

  String _generateResponse(String query) {
    final q = query.toLowerCase();
    final reportes = widget.reportes;

    if (reportes.isEmpty) {
      return 'No tengo datos cargados aún. Intenta recargar el dashboard.';
    }

    // Zona con más denuncias
    if (q.contains('zona') && (q.contains('más') || q.contains('mayor'))) {
      final zonas = <String, int>{};
      for (final r in reportes) {
        final zona = r.zonaProtegida.nombre ?? 'Sin zona';
        zonas[zona] = (zonas[zona] ?? 0) + 1;
      }
      if (zonas.isEmpty) return 'No hay datos de zonas protegidas en los reportes actuales.';
      final top = zonas.entries.reduce((a, b) => a.value >= b.value ? a : b);
      return 'La zona con más denuncias es "${top.key}" con ${top.value} reporte${top.value > 1 ? 's' : ''}. En total hay ${zonas.length} zonas afectadas.';
    }

    // Mercurio total
    if (q.contains('mercurio') || q.contains('hg')) {
      final total = reportes.fold(0.0, (sum, r) => sum + r.mercurioEstimadoKg);
      final promedio = reportes.isNotEmpty ? total / reportes.length : 0.0;
      return 'El mercurio total estimado es ${total.toStringAsFixed(1)} kg en ${reportes.length} reportes. Promedio por reporte: ${promedio.toStringAsFixed(1)} kg.';
    }

    // Resumen / esta semana
    if (q.contains('resumen') || q.contains('semana') || q.contains('general')) {
      final nuevos = reportes.where((r) => r.estado == EstadoReporte.nuevo).length;
      final revisados = reportes.where((r) => r.estado == EstadoReporte.revisado).length;
      final escalados = reportes.where((r) => r.estado == EstadoReporte.escalado).length;
      final mercurio = reportes.fold(0.0, (sum, r) => sum + r.mercurioEstimadoKg);
      return 'Resumen: ${reportes.length} reportes totales.\n• Nuevos: $nuevos\n• En revisión: $revisados\n• Escalados: $escalados\n• Mercurio estimado: ${mercurio.toStringAsFixed(1)} kg';
    }

    // Alertas activas
    if (q.contains('alerta') || q.contains('activa') || q.contains('nuevo')) {
      final alertas = reportes.where((r) => r.estado == EstadoReporte.nuevo || r.nivelRiesgo == NivelRiesgo.alto).length;
      return 'Hay $alertas reportes que requieren atención (estado nuevo o riesgo alto).';
    }

    // Riesgo alto
    if (q.contains('riesgo') || q.contains('alto') || q.contains('crítico')) {
      final altos = reportes.where((r) => r.nivelRiesgo == NivelRiesgo.alto).length;
      return '$altos de ${reportes.length} reportes tienen nivel de riesgo ALTO.';
    }

    // Total / cuántos
    if (q.contains('total') || q.contains('cuántos') || q.contains('cuantos')) {
      return 'En total hay ${reportes.length} reportes registrados en el sistema.';
    }

    // Anónimos
    if (q.contains('anónimo') || q.contains('anonimo') || q.contains('contacto')) {
      final anonimos = reportes.where((r) => r.tipoContacto == TipoContacto.anonimo).length;
      final conContacto = reportes.length - anonimos;
      return 'Reportes anónimos: $anonimos (${(anonimos * 100 / reportes.length).toStringAsFixed(0)}%)\nCon contacto: $conContacto';
    }

    // Default
    return 'Tengo ${reportes.length} reportes cargados. Puedo darte información sobre:\n• Zonas más afectadas\n• Mercurio estimado\n• Alertas activas\n• Resumen general\n• Reportes anónimos vs con contacto';
  }

  void _sendSuggestion(String text) {
    _controller.text = text;
    _send();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_isOpen) {
      return FloatingActionButton(
        onPressed: _toggle,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        child: const Icon(Icons.chat_bubble_outline),
      );
    }

    return SizedBox(
      width: 360,
      height: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: colorScheme.primaryContainer),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: colorScheme.primary,
                            child: const Icon(Icons.hive_outlined, size: 18, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Asistente Colmena', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                Text('${widget.reportes.length} reportes cargados', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontSize: 11)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _toggle,
                            icon: const Icon(Icons.close, size: 20),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) => _ChatBubble(message: _messages[index]),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _SuggestionChip(label: '¿Zona con más denuncias?', onTap: () => _sendSuggestion('¿Qué zona tuvo más denuncias?')),
                            const SizedBox(width: 6),
                            _SuggestionChip(label: 'Mercurio total', onTap: () => _sendSuggestion('¿Cuánto mercurio se ha estimado en total?')),
                            const SizedBox(width: 6),
                            _SuggestionChip(label: 'Resumen general', onTap: () => _sendSuggestion('Dame un resumen general')),
                            const SizedBox(width: 6),
                            _SuggestionChip(label: 'Alertas activas', onTap: () => _sendSuggestion('¿Cuántas alertas activas hay?')),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      decoration: BoxDecoration(border: Border(top: BorderSide(color: colorScheme.outlineVariant))),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Pregunta sobre los datos...',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: colorScheme.outlineVariant)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                isDense: true,
                              ),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _send,
                            icon: const Icon(Icons.send, size: 18),
                            style: IconButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 4,
            child: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBot = message.isBot;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isBot ? colorScheme.surfaceContainerHighest : colorScheme.primaryContainer,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isBot ? const Radius.circular(4) : const Radius.circular(16),
              bottomRight: isBot ? const Radius.circular(16) : const Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message.author, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: isBot ? colorScheme.primary : colorScheme.onPrimaryContainer)),
              const SizedBox(height: 3),
              Text(message.text, style: theme.textTheme.bodySmall?.copyWith(color: isBot ? colorScheme.onSurface : colorScheme.onPrimaryContainer)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.author, required this.text, required this.isBot});
  final String author;
  final String text;
  final bool isBot;
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
      ),
    );
  }
}
