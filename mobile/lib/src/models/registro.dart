/// Modelos de datos para la app mobile (Abeja).
/// Estos mismos modelos definen la interfaz que el backend debe implementar.

enum TamanoDraga { pequena, mediana, grande }

enum TiempoOperando { menosUnDia, variosDias, masUnaSemana }

enum NivelRiesgo { bajo, medio, alto }

enum EstadoSync { pendiente, sincronizado }

enum EstadoReporte { nuevo, revisado, escalado }

class Ubicacion {
  const Ubicacion({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  String toString() => '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
}

class IndicadoresVisibles {
  const IndicadoresVisibles({
    this.personasVisibles = false,
    this.motobombasVisibles = false,
  });

  final bool personasVisibles;
  final bool motobombasVisibles;
}

class ZonaProtegida {
  const ZonaProtegida({required this.esZonaProtegida, this.nombre});

  final bool esZonaProtegida;
  final String? nombre;
}

class ContactoOpcional {
  const ContactoOpcional({this.alias, this.celular});

  final String? alias;
  final String? celular;

  bool get isEmpty => alias == null && celular == null;
}

class Registro {
  const Registro({
    required this.id,
    required this.fecha,
    required this.ubicacion,
    required this.fotos,
    required this.tamanoDraga,
    required this.tiempoOperando,
    required this.indicadores,
    required this.estadoSync,
    this.notas,
    this.contacto,
    // Campos calculados por el agente (llegan después de sincronizar)
    this.mercurioEstimadoKg,
    this.zonaProtegida,
    this.normativaCitada,
    this.danoEconomicoEstimado,
    this.nivelRiesgo,
    this.estadoReporte,
  });

  final String id;
  final DateTime fecha;
  final Ubicacion ubicacion;
  final List<String> fotos; // Paths locales o URLs
  final TamanoDraga tamanoDraga;
  final TiempoOperando tiempoOperando;
  final IndicadoresVisibles indicadores;
  final EstadoSync estadoSync;
  final String? notas;
  final ContactoOpcional? contacto;

  // Generados por el backend/agente
  final double? mercurioEstimadoKg;
  final ZonaProtegida? zonaProtegida;
  final List<String>? normativaCitada;
  final double? danoEconomicoEstimado;
  final NivelRiesgo? nivelRiesgo;
  final EstadoReporte? estadoReporte;

  bool get fueAnalizado => mercurioEstimadoKg != null;
}
