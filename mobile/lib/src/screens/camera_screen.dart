import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Pantalla de captura de evidencia.
/// Permite tomar fotos con la cámara del dispositivo o elegir de la galería.
/// Muestra GPS automático y preview de las fotos tomadas.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _photos = [];

  Future<void> _takePhoto() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (photo != null) {
        setState(() => _photos.add(photo));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir la cámara: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
      );
      if (images.isNotEmpty) {
        setState(() => _photos.addAll(images));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir la galería: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _continue() {
    if (_photos.isEmpty) return;
    Navigator.of(context).pop(_photos.map((f) => f.path).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capturar evidencia'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(null),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aviso de distancia segura
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Colors.amber, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Captura a distancia segura',
                          style: theme.textTheme.titleSmall?.copyWith(color: Colors.amber.shade800),
                        ),
                        Text(
                          'Usa el zoom de tu cámara. No te acerques a la operación.',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // GPS automático
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'GPS: -11.4162, -67.5441',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Detectado', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Botones de captura
            Text('Agregar fotos', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _CaptureButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Tomar foto',
                    onTap: _takePhoto,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CaptureButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Galería',
                    onTap: _pickFromGallery,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Preview de fotos
            if (_photos.isNotEmpty) ...[
              Row(
                children: [
                  Text(
                    '${_photos.length} foto${_photos.length > 1 ? 's' : ''} seleccionada${_photos.length > 1 ? 's' : ''}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _takePhoto,
                    child: const Text('+ Agregar más'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    return _PhotoThumbnail(
                      file: File(_photos[index].path),
                      onRemove: () => _removePhoto(index),
                    );
                  },
                ),
              ),
            ] else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'Toma una foto o elige de la galería',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),

            // Botón continuar
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _photos.isNotEmpty ? _continue : null,
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(icon, size: 36, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({required this.file, required this.onRemove});

  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(file, fit: BoxFit.cover),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
