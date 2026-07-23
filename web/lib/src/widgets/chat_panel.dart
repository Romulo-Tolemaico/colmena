import 'package:flutter/material.dart';

import '../models/reporte.dart';

class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key, required this.reporte});

  final Reporte reporte;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final List<_Message> _messages = [
    const _Message(author: 'Sistema', text: 'Reporte recibido y listo para revisión.'),
    const _Message(author: 'Colmena', text: '¿Deseas priorizar este caso para validación?'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(_Message(author: 'Tú', text: text));
      _messages.add(const _Message(author: 'Colmena', text: 'Mensaje recibido. Queda registrado en seguimiento.'));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chat del reporte ${widget.reporte.id}', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        ..._messages.map((message) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Align(
                alignment: message.author == 'Tú' ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.author == 'Tú' ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message.author, style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(message.text),
                    ],
                  ),
                ),
              ),
            )),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Escribe una nota o instrucción',
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _send,
              child: const Text('Enviar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Message {
  const _Message({required this.author, required this.text});

  final String author;
  final String text;
}