import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/reporte.dart';

class MapWidget extends StatelessWidget {
  const MapWidget({
    super.key,
    required this.reportes,
    this.center,
    this.zoom = 8.0,
    this.onMarkerTap,
    this.selectedReporteId,
    this.height,
    this.interactive = true,
    this.showZonas = true,
  });

  final List<Reporte> reportes;
  final LatLng? center;
  final double zoom;
  final ValueChanged<String>? onMarkerTap;
  final String? selectedReporteId;
  final double? height;
  final bool interactive;
  final bool showZonas;

  // Zonas protegidas reales de Bolivia (polígonos simplificados basados en coordenadas documentadas)
  static final List<_ZonaProtegida> _zonas = [
    _ZonaProtegida(
      nombre: 'Reserva Manuripi',
      color: Colors.green,
      // Pando: 67°11'W a 68°59'W, 11°17'S a 12°31'S
      puntos: [LatLng(-11.28, -68.98), LatLng(-11.28, -67.18), LatLng(-12.52, -67.18), LatLng(-12.52, -68.98)],
    ),
    _ZonaProtegida(
      nombre: 'Territorio Indígena Multiétnico II',
      color: Colors.purple,
      // Entre ríos Madre de Dios y Beni, norte de Bolivia (Beni/Pando)
      puntos: [LatLng(-11.0, -66.5), LatLng(-11.0, -65.2), LatLng(-12.2, -65.2), LatLng(-12.2, -66.5)],
    ),
    _ZonaProtegida(
      nombre: 'Parque Nacional Madidi',
      color: Colors.blue,
      // Noroeste La Paz: centro 13°48'S 67°38'W, aprox 18,958 km2
      puntos: [LatLng(-13.0, -68.8), LatLng(-13.0, -67.2), LatLng(-15.0, -67.2), LatLng(-15.0, -68.8)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Centro por defecto: región norte de Bolivia (zona de actividad minera)
    final mapCenter = center ?? const LatLng(-11.2, -68.2);

    final map = FlutterMap(
      options: MapOptions(
        initialCenter: mapCenter,
        initialZoom: zoom,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: isDark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
              : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: isDark ? const ['a', 'b', 'c'] : const [],
          userAgentPackageName: 'com.colmena.web',
        ),
        if (showZonas)
          PolygonLayer(
            polygons: _zonas.map((zona) => Polygon(
              points: zona.puntos,
              color: zona.color.withValues(alpha: 0.15),
              borderColor: zona.color.withValues(alpha: 0.6),
              borderStrokeWidth: 2,
              label: zona.nombre,
              labelStyle: TextStyle(color: zona.color, fontSize: 11, fontWeight: FontWeight.w600),
            )).toList(),
          ),
        MarkerLayer(
          markers: reportes.map((reporte) => _buildMarker(reporte, theme)).toList(),
        ),
      ],
    );

    if (height != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(height: height, child: map),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: map,
    );
  }

  Marker _buildMarker(Reporte reporte, ThemeData theme) {
    final isSelected = reporte.id == selectedReporteId;
    final color = _colorForRisk(reporte.nivelRiesgo, theme);

    return Marker(
      point: LatLng(reporte.ubicacion.lat, reporte.ubicacion.lng),
      width: isSelected ? 44 : 36,
      height: isSelected ? 44 : 36,
      child: GestureDetector(
        onTap: () => onMarkerTap?.call(reporte.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : color.withOpacity(0.6),
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: isSelected ? 12 : 6,
                spreadRadius: isSelected ? 2 : 0,
              ),
            ],
          ),
          child: Icon(
            _iconForRisk(reporte.nivelRiesgo),
            color: Colors.white,
            size: isSelected ? 20 : 16,
          ),
        ),
      ),
    );
  }

  Color _colorForRisk(NivelRiesgo risk, ThemeData theme) {
    switch (risk) {
      case NivelRiesgo.bajo:
        return const Color(0xFF4CAF50);
      case NivelRiesgo.medio:
        return const Color(0xFFFFA726);
      case NivelRiesgo.alto:
        return const Color(0xFFEF5350);
    }
  }

  IconData _iconForRisk(NivelRiesgo risk) {
    switch (risk) {
      case NivelRiesgo.bajo:
        return Icons.info_outline;
      case NivelRiesgo.medio:
        return Icons.report_outlined;
      case NivelRiesgo.alto:
        return Icons.warning_amber;
    }
  }
}

/// Mapa pequeño de solo lectura para usar en paneles de detalle
class MiniMapWidget extends StatelessWidget {
  const MiniMapWidget({super.key, required this.reporte});

  final Reporte reporte;

  @override
  Widget build(BuildContext context) {
    return MapWidget(
      reportes: [reporte],
      center: LatLng(reporte.ubicacion.lat, reporte.ubicacion.lng),
      zoom: 12.0,
      height: 160,
      interactive: false,
      showZonas: false,
    );
  }
}

class _ZonaProtegida {
  const _ZonaProtegida({required this.nombre, required this.color, required this.puntos});

  final String nombre;
  final Color color;
  final List<LatLng> puntos;
}
