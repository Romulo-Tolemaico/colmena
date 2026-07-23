import 'package:flutter/material.dart';

/// Pantalla de captura de evidencia.
/// Simula la vista de cámara con controles de zoom, GPS automático,
/// y preview de la foto tomada. Sin funcionalidad real de cámara.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  double _zoom = 1.0;
  bool _photoTaken = false;
  final List<String> _photos = [];

  void _takePhoto() {
    setState(() {
      _photoTaken = true;
      _photos.add('foto_${_photos.length + 1}.jpg');
    });
  }

  void _addAnotherPhoto() {
    setState(() => _photoTaken = false);
  }

  void _continue() {
    Navigator.of(context).pop(_photos);
  }

  @override
  Widget build(BuildContext context) {
    if (_photoTaken) {
      return _PhotoPreview(
        photoCount: _photos.length,
        onAddAnother: _addAnotherPhoto,
        onContinue: _continue,
      );
    }

    return _CameraView(
      zoom: _zoom,
      onZoomChanged: (value) => setState(() => _zoom = value),
      onCapture: _takePhoto,
      onBack: () => Navigator.of(context).pop(null),
      photoCount: _photos.length,
    );
  }
}

class _CameraView extends StatelessWidget {
  const _CameraView({
    required this.zoom,
    required this.onZoomChanged,
    required this.onCapture,
    required this.onBack,
    required this.photoCount,
  });

  final double zoom;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onCapture;
  final VoidCallback onBack;
  final int photoCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Simulación de vista de cámara
            Positioned.fill(
              child: Container(
                color: const Color(0xFF1A1A1A),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt, size: 80, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Vista de cámara',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Zoom: ${zoom.toStringAsFixed(1)}x',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Spacer(),
                    if (photoCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$photoCount foto${photoCount > 1 ? 's' : ''}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Aviso de distancia segura
            Positioned(
              top: 70,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Captura a distancia segura. Usa el zoom.',
                        style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // GPS chip
            Positioned(
              bottom: 180,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        '-11.4162, -67.5441',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      'GPS detectado',
                      style: TextStyle(color: Colors.greenAccent.withValues(alpha: 0.8), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),

            // Controles inferiores
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Slider de zoom
                    Row(
                      children: [
                        const Icon(Icons.zoom_out, color: Colors.white70, size: 20),
                        Expanded(
                          child: Slider(
                            value: zoom,
                            min: 1.0,
                            max: 10.0,
                            divisions: 18,
                            activeColor: Colors.white,
                            inactiveColor: Colors.white30,
                            onChanged: onZoomChanged,
                          ),
                        ),
                        const Icon(Icons.zoom_in, color: Colors.white70, size: 20),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Botón de captura
                    GestureDetector(
                      onTap: onCapture,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.photoCount,
    required this.onAddAnother,
    required this.onContinue,
  });

  final int photoCount;
  final VoidCallback onAddAnother;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evidencia capturada'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(null),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Preview placeholder
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      '$photoCount foto${photoCount > 1 ? 's' : ''} capturada${photoCount > 1 ? 's' : ''}',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'GPS: -11.4162, -67.5441',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Ahora',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botones
            OutlinedButton.icon(
              onPressed: onAddAnother,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Adjuntar otra foto'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
