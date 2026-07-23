class SerieMensual {
  const SerieMensual({required this.mes, required this.cantidad});

  final String mes;
  final int cantidad;
}

class MetricasDashboard {
  const MetricasDashboard({
    required this.totalDenuncias,
    required this.mercurioAcumuladoKg,
    required this.zonasProtegidasAfectadas,
    required this.porcentajeAnonimas,
    required this.denunciasPorMes,
  });

  final int totalDenuncias;
  final double mercurioAcumuladoKg;
  final int zonasProtegidasAfectadas;
  final int porcentajeAnonimas;
  final List<SerieMensual> denunciasPorMes;
}
