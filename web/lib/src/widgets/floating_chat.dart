import 'package:flutter/material.dart';

/// Widget de chat flotante tipo burbuja.
/// Muestra solo un ícono FAB. Al hacer clic se abre el panel de chat como overlay.
class FloatingChat extends StatefulWidget {
  const FloatingChat({super.key});

  @override
  State<FloatingChat> createState() => _FloatingChatState();
}

class _FloatingChatState extends State<FloatingChat> {
  bool _isOpen = false;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(author: 'Colmena', text: '¡Hola! Soy el asistente de Colmena. ¿En qué puedo ayudarte?', isBot: true),
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

    // Simular respuesta del bot
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _messages.add(const _ChatMessage(
            author: 'Colmena',
            text: 'Mensaje recibido. Queda registrado en seguimiento.',
            isBot: true,
          ));
        });
        _scrollToBottom();
      }
    });

    _scrollToBottom();
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

    // Solo el FAB cuando está cerrado
    if (!_isOpen) {
      return FloatingActionButton(
        onPressed: _toggle,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        child: const Icon(Icons.chat_bubble_outline),
      );
    }

    // Panel de chat abierto (tamaño fijo, no usa Stack)
    return SizedBox(
      width: 360,
      height: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Panel de chat
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
                    // Header del chat
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                      ),
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
                                Text('En línea', style: theme.textTheme.bodySmall?.copyWith(color: Colors.green, fontSize: 11)),
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

                    // Mensajes
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _ChatBubble(message: message);
                        },
                      ),
                    ),

                    // Sugerencias de preguntas rápidas
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _SuggestionChip(label: '¿Zona con más denuncias?', onTap: () => _sendSuggestion('¿Qué zona tuvo más denuncias este mes?')),
                            const SizedBox(width: 6),
                            _SuggestionChip(label: 'Mercurio total', onTap: () => _sendSuggestion('¿Cuánto mercurio se ha estimado en total?')),
                            const SizedBox(width: 6),
                            _SuggestionChip(label: 'Resumen semanal', onTap: () => _sendSuggestion('Dame un resumen de esta semana')),
                            const SizedBox(width: 6),
                            _SuggestionChip(label: 'Alertas activas', onTap: () => _sendSuggestion('¿Cuántas alertas activas hay?')),
                          ],
                        ),
                      ),
                    ),

                    // Input
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              minLines: 1,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Escribe un mensaje...',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                                ),
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
                            style: IconButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
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

          // FAB para cerrar
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
              Text(
                message.author,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isBot ? colorScheme.primary : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                message.text,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isBot ? colorScheme.onSurface : colorScheme.onPrimaryContainer,
                ),
              ),
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
