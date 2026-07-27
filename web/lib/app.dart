import 'dart:convert';

import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/data/api_service.dart';
import 'src/data/session_service.dart';
import 'src/models/metricas_dashboard.dart';
import 'src/models/reporte.dart';
import 'src/screens/alertas_screen.dart';
import 'src/screens/dashboard_screen.dart';
import 'src/screens/historial_screen.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/register_screen.dart';
import 'src/widgets/app_shell.dart';
import 'src/widgets/report_detail_panel.dart';

enum AuthState { loading, login, register, authenticated }

class ColmenaApp extends StatefulWidget {
  const ColmenaApp({super.key});

  @override
  State<ColmenaApp> createState() => _ColmenaAppState();
}

class _ColmenaAppState extends State<ColmenaApp> {
  final ApiService _api = ApiService();
  final SessionService _session = SessionService();

  List<Reporte> _reportes = [];
  MetricasDashboard? _metricas;
  bool _loading = true;
  String _language = 'es';
  ThemeMode _themeMode = ThemeMode.light;
  bool _sidebarCollapsed = false;
  AppView _view = AppView.dashboard;
  String? _selectedReporteId;

  AuthState _authState = AuthState.loading;
  String? _authError;

  String _userName = '';
  String _userRol = '';

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final session = await _session.restore();
    if (session != null) {
      _api.setToken(session.token);
      setState(() {
        _userName = session.nombre;
        _userRol = session.rol;
        _authState = AuthState.authenticated;
      });
      // Obtener datos reales del usuario si hay conexión
      _fetchUserProfile();
      _loadData();
    } else {
      setState(() => _authState = AuthState.login);
    }
  }

  Future<void> _loadData({String? estado, String? fecha}) async {
    setState(() => _loading = true);

    MetricasDashboard? metricasBase;
    final metricasResult = await _api.getMetricas();
    if (metricasResult.isSuccess) {
      final d = metricasResult.data!;
      // Parsear denuncias_por_mes del API si viene
      final denunciasPorMesRaw = (d['denuncias_por_mes'] as List<dynamic>?) ?? [];
      final seriesFromApi = denunciasPorMesRaw.map((item) {
        final m = item as Map<String, dynamic>;
        return SerieMensual(
          mes: m['mes'] as String? ?? '',
          cantidad: (m['cantidad'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      metricasBase = MetricasDashboard(
        totalDenuncias: (d['total_reportes'] as num?)?.toInt() ?? 0,
        mercurioAcumuladoKg: (d['mercurio_acumulado_kg'] as num?)?.toDouble() ?? 0.0,
        zonasProtegidasAfectadas: (d['zonas_afectadas'] as num?)?.toInt() ?? 0,
        porcentajeAnonimas: (d['porcentaje_anonimos'] as num?)?.toInt() ?? 0,
        denunciasPorMes: seriesFromApi,
      );
    }

    final reportesResult = await _api.getReportes(porPagina: 50, estado: estado, fecha: fecha);
    if (reportesResult.isSuccess) {
      final data = reportesResult.data!;
      final lista = (data['reportes'] as List<dynamic>?) ?? [];
      _reportes = lista.map((r) => _mapReporte(r as Map<String, dynamic>)).toList();
    }

    // Si la API no devolvió denuncias_por_mes, calcular localmente
    if (metricasBase != null && metricasBase.denunciasPorMes.isEmpty && _reportes.isNotEmpty) {
      final porMes = <String, int>{};
      final mesesNombres = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      for (final r in _reportes) {
        final key = '${mesesNombres[r.fecha.month - 1]} ${r.fecha.year}';
        porMes[key] = (porMes[key] ?? 0) + 1;
      }
      _metricas = MetricasDashboard(
        totalDenuncias: metricasBase.totalDenuncias,
        mercurioAcumuladoKg: metricasBase.mercurioAcumuladoKg,
        zonasProtegidasAfectadas: metricasBase.zonasProtegidasAfectadas,
        porcentajeAnonimas: metricasBase.porcentajeAnonimas,
        denunciasPorMes: porMes.entries.map((e) => SerieMensual(mes: e.key, cantidad: e.value)).toList(),
      );
    } else {
      _metricas = metricasBase;
    }

    setState(() => _loading = false);
  }

  Future<void> _fetchUserProfile() async {
    final result = await _api.getUsuarioActual();
    if (result.isSuccess) {
      final user = result.data!;
      setState(() {
        _userName = user.nombre;
        _userRol = user.rolCodigo;
      });
      // Actualizar sesión persistida con nombre real
      await _session.save(UserSession(
        token: _api.token!,
        nombre: user.nombre,
        correo: user.correo,
        rol: user.rolCodigo,
      ));
    }
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
      nivelRiesgo: _parseNivelRiesgo(json['evaluacion']?['nivel_riesgo_codigo'] as String?)
          ?? _riesgoDesdeEstado(json['estado_codigo'] as String?),
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

  TamanoDraga _parseTamanoDraga(String? codigo) => switch (codigo) {
        'PEQUENA' => TamanoDraga.pequena,
        'MEDIANA' => TamanoDraga.mediana,
        'GRANDE' => TamanoDraga.grande,
        _ => TamanoDraga.mediana,
      };

  TiempoOperando _parseTiempoOperando(String? codigo) => switch (codigo) {
        'MENOS_1_DIA' => TiempoOperando.menosUnDia,
        'VARIOS_DIAS' => TiempoOperando.variosDias,
        'MAS_1_SEMANA' => TiempoOperando.masUnaSemana,
        _ => TiempoOperando.variosDias,
      };

  NivelRiesgo? _parseNivelRiesgo(String? codigo) => switch (codigo) {
        'BAJO' => NivelRiesgo.bajo,
        'MEDIO' => NivelRiesgo.medio,
        'ALTO' => NivelRiesgo.alto,
        _ => null,
      };

  NivelRiesgo _riesgoDesdeEstado(String? estado) => switch (estado) {
        'escalado' => NivelRiesgo.alto,
        'revisado' => NivelRiesgo.medio,
        _ => NivelRiesgo.bajo,
      };

  EstadoReporte _parseEstado(String? codigo) => switch (codigo) {
        'nuevo' => EstadoReporte.nuevo,
        'revisado' => EstadoReporte.revisado,
        'escalado' => EstadoReporte.escalado,
        _ => EstadoReporte.nuevo,
      };

  void _toggleTheme() => setState(() {
        _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      });

  void _toggleSidebar() => setState(() => _sidebarCollapsed = !_sidebarCollapsed);

  void _openReporte(String id) => setState(() => _selectedReporteId = id);

  void _clearReporteSelection() => setState(() => _selectedReporteId = null);

  Future<void> _handleLogin(String correo, String contrasena) async {
    final result = await _api.login(correo, contrasena);
    if (result.isSuccess) {
      final token = result.data!.token;

      // Decodificar JWT para extraer nombre
      String nombre = correo.split('@').first;
      String rol = 'Analista';
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
          final claims = jsonDecode(payload) as Map<String, dynamic>;
          if (claims['nombre'] != null) nombre = claims['nombre'] as String;
          if (claims['rol'] != null) rol = claims['rol'] as String;
        }
      } catch (_) {}

      await _session.save(UserSession(
        token: token,
        nombre: nombre,
        correo: correo,
        rol: rol,
      ));

      setState(() {
        _userName = nombre;
        _userRol = rol;
        _authState = AuthState.authenticated;
        _authError = null;
      });
      _fetchUserProfile();
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

  Future<void> _handleLogout() async {
    await _session.clear();
    _api.setToken(null);
    setState(() {
      _authState = AuthState.login;
      _selectedReporteId = null;
      _view = AppView.dashboard;
      _reportes = [];
      _metricas = null;
      _authError = null;
      _userName = '';
      _userRol = '';
    });
  }

  Future<void> _handleCambiarEstado(String codigo, String nuevoEstado) async {
    final result = await _api.cambiarEstado(codigo, nuevoEstado);
    if (result.isSuccess) {
      _loadData();
    }
  }

  Reporte? get _selectedReporte {
    for (final reporte in _reportes) {
      if (reporte.id == _selectedReporteId) return reporte;
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
      case AuthState.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
          onChangeView: (view) => setState(() {
            _view = view;
            _selectedReporteId = null;
          }),
          sidebarCollapsed: _sidebarCollapsed,
          onToggleSidebar: _toggleSidebar,
          language: _language,
          onLanguageChange: (language) => setState(() => _language = language),
          themeMode: _themeMode,
          onToggleTheme: _toggleTheme,
          onLogout: _handleLogout,
          userName: _userName,
          userRol: _userRol,
          reportes: _reportes,
          onChatMessage: (mensaje) async {
            final result = await _api.chatDashboard(mensaje);
            return result.isSuccess ? result.data : null;
          },
          detailPane: _selectedReporte == null
              ? null
              : ReportDetailPanel(
                  reporte: _selectedReporte!,
                  onClose: _clearReporteSelection,
                  onCambiarEstado: _handleCambiarEstado,
                  onGenerarPdf: (codigo) async {
                    final result = await _api.generarPdf(codigo);
                    return result.isSuccess ? result.data : null;
                  },
                  onCargarFotos: (codigo) async {
                    final result = await _api.listarFotos(codigo);
                    return result.isSuccess ? result.data! : [];
                  },
                ),
          child: switch (_view) {
            AppView.dashboard => DashboardScreen(
              reportes: _reportes,
              metricas: _metricas,
              loading: _loading,
              onOpenReporte: _openReporte,
              selectedReporteId: _selectedReporteId,
              onFilter: ({String? estado, String? fecha}) => _loadData(estado: estado, fecha: fecha),
              onVerTodos: () => setState(() => _view = AppView.historial),
              onVerAlertas: () => setState(() => _view = AppView.alertas),
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
