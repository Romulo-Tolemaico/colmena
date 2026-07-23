import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/data/data_service.dart';
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
  final DataService _dataService = MockDataService();
  List<Reporte> _reportes = [];
  MetricasDashboard? _metricas;
  bool _loading = true;
  String _language = 'es';
  ThemeMode _themeMode = ThemeMode.light;
  bool _sidebarCollapsed = false;
  AppView _view = AppView.dashboard;
  String? _selectedReporteId;

  // Estado de autenticación (sin backend, solo UI)
  AuthState _authState = AuthState.login;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final result = await _dataService.loadDashboard();
    setState(() {
      _reportes = result.reportes;
      _metricas = result.metricas;
      _loading = false;
    });
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
      _view = AppView.dashboard;
    });
  }

  void _clearReporteSelection() {
    setState(() {
      _selectedReporteId = null;
    });
  }

  void _handleLogin() {
    setState(() => _authState = AuthState.authenticated);
  }

  void _handleRegister() {
    // Después de registrarse, ir al login para que inicie sesión
    setState(() => _authState = AuthState.login);
  }

  void _handleLogout() {
    setState(() {
      _authState = AuthState.login;
      _selectedReporteId = null;
      _view = AppView.dashboard;
    });
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
          onGoToRegister: () => setState(() => _authState = AuthState.register),
        );
      case AuthState.register:
        return RegisterScreen(
          onRegister: _handleRegister,
          onGoToLogin: () => setState(() => _authState = AuthState.login),
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
