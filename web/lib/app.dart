import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/data/api_service.dart';
import 'src/models/metricas_dashboard.dart';
import 'src/models/reporte.dart';
import 'src/screens/alertas_screen.dart';
import 'src/screens/dashboard_screen.dart';
import 'src/screens/historial_screen.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/register_screen.dart';
import 'src/widgets/app_shell.dart';
import 'src/widgets/report_detail_panel.dart';

enum AuthState { login, register, authenticated }

class ColmenaApp extends StatefulWidget {
  const ColmenaApp({super.key});

  @override
  State<ColmenaApp> createState() => _ColmenaAppState();
}

class _ColmenaAppState extends State<ColmenaApp> {
  final ApiService _api = ApiService();
  List<Reporte> _reportes = [];
  MetricasDashboard? _metricas;
  bool _loading = true;
  String _language = 'es';
  ThemeMode _themeMode = ThemeMode.light;
  bool _sidebarCollapsed = false;
  AppView _view = AppView.dashboard;
  String? _selectedReporteId;

  AuthState _authState = AuthState.login;
  String? _authError;

  Future<void> _loadData() async {
    setState(() => _loading = true);

    // Cargar métricas
    final metricasResult = await _api.getMetricas();
    if (metricasResult.isSuccess) {
      final d = metricasResult.data!;
      _metricas = MetricasDashboard(
        totalDenuncias: (d['total_reportes'] as num?)?.toInt() ?? 0,
        mercurioAcumuladoKg: (d['mercurio_acumulado_kg'] as num?)?.toDouble() ?? 0.0,
        zonasProtegidasAfectadas: (d['zonas_afectadas'] as num?)?.toInt() ?? 0,
        porcentajeAnonimas: (d['porcentaje_anonimos'] as num?)?.toInt() ?? 0,
        denunciasPorMes: const [],
      );
    }

    // Cargar reportes
    final reportesResult = await _api.getReportes(porPagina: 50);
    if (reportesResult.isSuccess) {
      final data = reportesResult.data!;
      final lista = (data['reportes'] as List<dynamic>?) ?? [];
      _reportes = lista.map((r) => _mapReporte(r as Map<String, dynamic>)).toList();
    }

    setState(() => _loading = false);
  }

  Reporte _mapReporte(Map<String, dynamic> json) {
    return Reporte(
      id: json['codigo'] as String? ?? '',
      fecha: DateTime.tryParse(json['fecha_creacion']?.toString() ?? '') ?? DateTime.now(),
      ubicacion: Ubicacion(
        lat: (json['latitud'] as num?)?.toDouble() ?? 0.0,
        lng: (json['longitud'] as num?)?.toDouble() ?? 0.0,
      ),
      fotos: const [],
      tamanoDraga: _parseTamanoDraga(json['tamano_draga_codigo'] as String?),
      tiempoOperando: _parseTiempoOperando(json['tiempo_operacion_codigo'] as String?),
      indicadores: IndicadoresVisibles(
        personasVisibles: json['personas_visibles'] as bool? ?? false,
        motobombasVisibles: json['motobombas_visibles'] as bool? ?? false,
      ),
      notas: json['nota'] as String?,
      mercurioEstimadoKg: (json['evaluacion'] != null)
          ? (json['evaluacion']['mercurio_estimado_kg'] as num?)?.toDouble() ?? 0.0
          : 0.0,
      zonaProtegida: ZonaProtegida(
        esZonaProtegida: json['evaluacion']?['zona_codigo'] != null,
        nombre: json['evaluacion']?['zona_codigo'] as String?,
      ),
      normativaCitada: json['evaluacion']?['normativa_codigo'] != null
          ? [json['evaluacion']['normativa_codigo'] as String]
          : const [],
      danoEconomicoEstimado: 0,
      nivelRiesgo: _parseNivelRiesgo(json['evaluacion']?['nivel_riesgo_codigo'] as String?),
      estado: _parseEstado(json['estado_codigo'] as String?),
      tipoContacto: (json['alias_informante'] != null || json['celular_informante'] != null)
          ? TipoContacto.conContacto
          : TipoContacto.anonimo,
      contacto: (json['alias_informante'] != null || json['celular_informante'] != null)
          ? ContactoReporte(
              alias: json['alias_informante'] as String?,
              celular: json['celular_informante'] as String?,
            )
          : null,
    );
  }

  TamanoDraga _parseTamanoDraga(String? codigo) {
    return switch (codigo) {
      'PEQUENA' => TamanoDraga.pequena,
      'MEDIANA' => TamanoDraga.mediana,
      'GRANDE' => TamanoDraga.grande,
      _ => TamanoDraga.mediana,
    };
  }

  TiempoOperando _parseTiempoOperando(String? codigo) {
    return switch (codigo) {
      'MENOS_1_DIA' => TiempoOperando.menosUnDia,
      'VARIOS_DIAS' => TiempoOperando.variosDias,
      'MAS_1_SEMANA' => TiempoOperando.masUnaSemana,
      _ => TiempoOperando.variosDias,
    };
  }

  NivelRiesgo _parseNivelRiesgo(String? codigo) {
    return switch (codigo) {
      'BAJO' => NivelRiesgo.bajo,
      'MEDIO' => NivelRiesgo.medio,
      'ALTO' => NivelRiesgo.alto,
      _ => NivelRiesgo.bajo,
    };
  }

  EstadoReporte _parseEstado(String? codigo) {
    return switch (codigo) {
      'nuevo' => EstadoReporte.nuevo,
      'revisado' => EstadoReporte.revisado,
      'escalado' => EstadoReporte.escalado,
      _ => EstadoReporte.nuevo,
    };
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _sidebarCollapsed = !_sidebarCollapsed;
    });
  }

  void _openReporte(String id) {
    setState(() {
      _selectedReporteId = id;
    });
  }

  void _clearReporteSelection() {
    setState(() {
      _selectedReporteId = null;
    });
  }

  Future<void> _handleLogin(String correo, String contrasena) async {
    final result = await _api.login(correo, contrasena);
    if (result.isSuccess) {
      setState(() {
        _authState = AuthState.authenticated;
        _authError = null;
      });
      _loadData();
    } else {
      setState(() => _authError = result.error);
    }
  }

  Future<void> _handleRegister(String nombre, String correo, String contrasena, String rol) async {
    final result = await _api.register(
      nombre: nombre,
      correo: correo,
      contrasena: contrasena,
      rolCodigo: rol,
    );
    if (result.isSuccess) {
      setState(() {
        _authState = AuthState.login;
        _authError = null;
      });
    } else {
      setState(() => _authError = result.error);
    }
  }

  void _handleLogout() {
    _api.setToken(null);
    setState(() {
      _authState = AuthState.login;
      _selectedReporteId = null;
      _view = AppView.dashboard;
      _reportes = [];
      _metricas = null;
      _authError = null;
    });
  }

  Future<void> _handleCambiarEstado(String codigo, String nuevoEstado) async {
    final result = await _api.cambiarEstado(codigo, nuevoEstado);
    if (result.isSuccess) {
      _loadData(); // Recargar datos
    }
  }

  Reporte? get _selectedReporte {
    for (final reporte in _reportes) {
      if (reporte.id == _selectedReporteId) {
        return reporte;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Colmena',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D7341), brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF5F1E8),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8EA36F), brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF11150F),
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    switch (_authState) {
      case AuthState.login:
        return LoginScreen(
          onLogin: _handleLogin,
          onGoToRegister: () => setState(() {
            _authState = AuthState.register;
            _authError = null;
          }),
          errorMessage: _authError,
        );
      case AuthState.register:
        return RegisterScreen(
          onRegister: _handleRegister,
          onGoToLogin: () => setState(() {
            _authState = AuthState.login;
            _authError = null;
          }),
          errorMessage: _authError,
        );
      case AuthState.authenticated:
        return AppShell(
          view: _view,
          onChangeView: (view) => setState(() => _view = view),
          sidebarCollapsed: _sidebarCollapsed,
          onToggleSidebar: _toggleSidebar,
          language: _language,
          onLanguageChange: (language) => setState(() => _language = language),
          themeMode: _themeMode,
          onToggleTheme: _toggleTheme,
          onLogout: _handleLogout,
          detailPane: _selectedReporte == null
              ? null
              : ReportDetailPanel(
                  reporte: _selectedReporte!,
                  onClose: _clearReporteSelection,
                  onCambiarEstado: _handleCambiarEstado,
                ),
          child: switch (_view) {
            AppView.dashboard => DashboardScreen(
              reportes: _reportes,
              metricas: _metricas,
              loading: _loading,
              onOpenReporte: _openReporte,
              selectedReporteId: _selectedReporteId,
            ),
            AppView.historial => HistorialScreen(
              reportes: _reportes,
              loading: _loading,
              onOpenReporte: _openReporte,
            ),
            AppView.alertas => AlertasScreen(
              reportes: _reportes,
              onOpenReporte: _openReporte,
            ),
          },
        );
    }
  }
}
