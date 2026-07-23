import '../models/metricas_dashboard.dart';
import '../models/reporte.dart';

class DashboardData {
  const DashboardData({required this.reportes, required this.metricas});

  final List<Reporte> reportes;
  final MetricasDashboard metricas;
}

abstract class DataService {
  Future<DashboardData> loadDashboard();
  Future<Reporte?> getReportePorId(String id);
}

class MockDataService implements DataService {
  @override
  Future<DashboardData> loadDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return DashboardData(reportes: _reportes, metricas: _metricas);
  }

  @override
  Future<Reporte?> getReportePorId(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    for (final reporte in _reportes) {
      if (reporte.id == id) return reporte;
    }
    return null;
  }

  final List<Reporte> _reportes = [
    Reporte(
      id: 'COL-001',
      fecha: DateTime.parse('2026-06-03T09:20:00.000Z'),
      ubicacion: const Ubicacion(lat: -11.4162, lng: -67.5441),
      fotos: const ['https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=1200&q=80'],
      tamanoDraga: TamanoDraga.mediana,
      tiempoOperando: TiempoOperando.variosDias,
      indicadores: const IndicadoresVisibles(personasVisibles: true, motobombasVisibles: true),
      notas: 'Actividad sobre margen del río con remoción visible de sedimentos.',
      mercurioEstimadoKg: 18.4,
      zonaProtegida: const ZonaProtegida(esZonaProtegida: true, nombre: 'Reserva Manuripi'),
      normativaCitada: const ['Ley 1333', 'D.S. 28592'],
      danoEconomicoEstimado: 78000,
      nivelRiesgo: NivelRiesgo.alto,
      estado: EstadoReporte.nuevo,
      tipoContacto: TipoContacto.anonimo,
    ),
    Reporte(
      id: 'COL-002',
      fecha: DateTime.parse('2026-06-07T14:05:00.000Z'),
      ubicacion: const Ubicacion(lat: -11.1587, lng: -68.7604),
      fotos: const ['https://images.unsplash.com/photo-1512343879780-a960bf40e7f2?auto=format&fit=crop&w=1200&q=80'],
      tamanoDraga: TamanoDraga.pequena,
      tiempoOperando: TiempoOperando.menosUnDia,
      indicadores: const IndicadoresVisibles(personasVisibles: false, motobombasVisibles: true),
      mercurioEstimadoKg: 6.2,
      zonaProtegida: const ZonaProtegida(esZonaProtegida: false),
      normativaCitada: const ['Ley 1333', 'Código Penal art. 216'],
      danoEconomicoEstimado: 21400,
      nivelRiesgo: NivelRiesgo.medio,
      estado: EstadoReporte.revisado,
      tipoContacto: TipoContacto.conContacto,
      contacto: const ContactoReporte(alias: 'Río Claro', celular: '725-11445'),
    ),
    Reporte(
      id: 'COL-003',
      fecha: DateTime.parse('2026-06-11T07:45:00.000Z'),
      ubicacion: const Ubicacion(lat: -10.9823, lng: -68.3372),
      fotos: const ['https://images.unsplash.com/photo-1544198365-f5d60b6f5b39?auto=format&fit=crop&w=1200&q=80'],
      tamanoDraga: TamanoDraga.grande,
      tiempoOperando: TiempoOperando.masUnaSemana,
      indicadores: const IndicadoresVisibles(personasVisibles: true, motobombasVisibles: true),
      notas: 'Flujo constante de maquinaria sobre cauce secundario.',
      mercurioEstimadoKg: 22.8,
      zonaProtegida: const ZonaProtegida(esZonaProtegida: true, nombre: 'Bajo Madidi'),
      normativaCitada: const ['Ley 1333', 'Ley 1330'],
      danoEconomicoEstimado: 124500,
      nivelRiesgo: NivelRiesgo.alto,
      estado: EstadoReporte.escalado,
      tipoContacto: TipoContacto.anonimo,
    ),
    Reporte(
      id: 'COL-004',
      fecha: DateTime.parse('2026-06-15T18:30:00.000Z'),
      ubicacion: const Ubicacion(lat: -11.7210, lng: -67.8701),
      fotos: const ['https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?auto=format&fit=crop&w=1200&q=80'],
      tamanoDraga: TamanoDraga.mediana,
      tiempoOperando: TiempoOperando.variosDias,
      indicadores: const IndicadoresVisibles(personasVisibles: false, motobombasVisibles: true),
      mercurioEstimadoKg: 10.1,
      zonaProtegida: const ZonaProtegida(esZonaProtegida: false),
      normativaCitada: const ['Ley 1333'],
      danoEconomicoEstimado: 36200,
      nivelRiesgo: NivelRiesgo.medio,
      estado: EstadoReporte.nuevo,
      tipoContacto: TipoContacto.conContacto,
      contacto: const ContactoReporte(alias: 'Luz Sur', celular: '711-22331'),
    ),
  ];

  final MetricasDashboard _metricas = const MetricasDashboard(
    totalDenuncias: 4,
    mercurioAcumuladoKg: 57.5,
    zonasProtegidasAfectadas: 2,
    porcentajeAnonimas: 50,
    denunciasPorMes: [
      SerieMensual(mes: 'mar 2026', cantidad: 1),
      SerieMensual(mes: 'abr 2026', cantidad: 2),
      SerieMensual(mes: 'may 2026', cantidad: 3),
      SerieMensual(mes: 'jun 2026', cantidad: 4),
    ],
  );
}


