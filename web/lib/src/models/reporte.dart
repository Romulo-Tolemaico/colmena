enum TamanoDraga { pequena, mediana, grande }

enum TiempoOperando { menosUnDia, variosDias, masUnaSemana }

enum NivelRiesgo { bajo, medio, alto }

enum EstadoReporte { nuevo, revisado, escalado }

enum TipoContacto { anonimo, conContacto }

class Ubicacion {
  const Ubicacion({required this.lat, required this.lng});

  final double lat;
  final double lng;
}

class IndicadoresVisibles {
  const IndicadoresVisibles({required this.personasVisibles, required this.motobombasVisibles});

  final bool personasVisibles;
  final bool motobombasVisibles;
}

class ZonaProtegida {
  const ZonaProtegida({required this.esZonaProtegida, this.nombre});

  final bool esZonaProtegida;
  final String? nombre;
}

class ContactoReporte {
  const ContactoReporte({this.alias, this.celular});

  final String? alias;
  final String? celular;
}

class Reporte {
  const Reporte({
    required this.id,
    required this.fecha,
    required this.ubicacion,
    required this.fotos,
    required this.tamanoDraga,
    required this.tiempoOperando,
    required this.indicadores,
    required this.mercurioEstimadoKg,
    required this.zonaProtegida,
    required this.normativaCitada,
    required this.danoEconomicoEstimado,
    required this.nivelRiesgo,
    required this.estado,
    required this.tipoContacto,
    this.notas,
    this.contacto,
  });

  final String id;
  final DateTime fecha;
  final Ubicacion ubicacion;
  final List<String> fotos;
  final TamanoDraga tamanoDraga;
  final TiempoOperando tiempoOperando;
  final IndicadoresVisibles indicadores;
  final String? notas;
  final double mercurioEstimadoKg;
  final ZonaProtegida zonaProtegida;
  final List<String> normativaCitada;
  final double danoEconomicoEstimado;
  final NivelRiesgo nivelRiesgo;
  final EstadoReporte estado;
  final TipoContacto tipoContacto;
  final ContactoReporte? contacto;
}
