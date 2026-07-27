import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/data/api_service.dart';
import 'src/models/registro.dart';
import 'src/screens/ajustes_screen.dart';
import 'src/screens/camera_screen.dart';
import 'src/screens/estimation_screen.dart';
import 'src/screens/inicio_screen.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/screens/registros_screen.dart';
import 'src/screens/report_result_screen.dart';
import 'src/theme.dart';

class ColmenaMobileApp extends StatefulWidget {
  const ColmenaMobileApp({super.key});

  @override
  State<ColmenaMobileApp> createState() => _ColmenaMobileAppState();
}

class _ColmenaMobileAppState extends State<ColmenaMobileApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Colmena',
      theme: ColmenaTheme.light,
      darkTheme: ColmenaTheme.dark,
      themeMode: _themeMode,
      home: _AppEntry(onThemeModeChanged: _setThemeMode, themeMode: _themeMode),
    );
  }
}

/// Controla si mostrar onboarding (primera vez) o la app principal.
class _AppEntry extends StatefulWidget {
  const _AppEntry({required this.onThemeModeChanged, required this.themeMode});

  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ThemeMode themeMode;

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool? _showOnboarding;

  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_complete') ?? false;
    setState(() => _showOnboarding = !seen);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_showOnboarding!) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }
    return _MainShell(
      onThemeModeChanged: widget.onThemeModeChanged,
      themeMode: widget.themeMode,
    );
  }
}

class _MainShell extends StatefulWidget {
  const _MainShell({required this.onThemeModeChanged, required this.themeMode});

  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ThemeMode themeMode;

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _currentIndex = 0;
  bool _online = true;

  final MobileApiService _api = MobileApiService(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://192.168.100.160:3000/api/v1',
    ),
  );

  final GlobalKey<RegistrosScreenState> _registrosKey = GlobalKey();

  void _onConnectionChanged(bool online) {
    if (mounted) setState(() => _online = online);
  }

  Future<void> _startNewReport() async {
    final cameraResult = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (cameraResult == null || !mounted) return;

    final photos = (cameraResult['photos'] as List<dynamic>?)?.cast<String>() ?? [];
    if (photos.isEmpty) return;

    final lat = cameraResult['lat'] as double?;
    final lng = cameraResult['lng'] as double?;

    if (!mounted) return;
    final estimation = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => EstimationScreen(fotos: photos)),
    );
    if (estimation == null || !mounted) return;

    final tamanoDraga = estimation['tamanoDraga'] as TamanoDraga? ?? TamanoDraga.mediana;
    final tiempoOperando = estimation['tiempoOperando'] as TiempoOperando? ?? TiempoOperando.variosDias;
    final personasVisibles = estimation['personasVisibles'] as bool? ?? false;
    final motobombasVisibles = estimation['motobombasVisibles'] as bool? ?? false;
    final notas = estimation['notas'] as String?;
    final alias = estimation['alias'] as String?;
    final celular = estimation['celular'] as String?;

    final result = await _api.enviarReporte(
      latitud: lat ?? -11.4162,
      longitud: lng ?? -67.5441,
      tamanoDraga: tamanoDraga,
      tiempoOperando: tiempoOperando,
      personasVisibles: personasVisibles,
      motobombasVisibles: motobombasVisibles,
      nota: notas,
      alias: (alias != null && alias.isNotEmpty) ? alias : null,
      celular: (celular != null && celular.isNotEmpty) ? celular : null,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      final codigoReporte = result.data!;
      await _api.subirFotos(codigoReporte, photos);
      final detalleResult = await _api.getReporteDetalle(codigoReporte);

      Registro registroResultado;
      if (detalleResult.isSuccess) {
        final d = detalleResult.data!;
        final eval = d['evaluacion'] as Map<String, dynamic>?;
        registroResultado = Registro(
          id: codigoReporte,
          fecha: DateTime.now(),
          ubicacion: Ubicacion(lat: lat ?? -11.4162, lng: lng ?? -67.5441),
          fotos: photos,
          tamanoDraga: tamanoDraga,
          tiempoOperando: tiempoOperando,
          indicadores: IndicadoresVisibles(
            personasVisibles: personasVisibles,
            motobombasVisibles: motobombasVisibles,
          ),
          estadoSync: EstadoSync.sincronizado,
          notas: notas,
          mercurioEstimadoKg: (eval?['mercurio_estimado_kg'] as num?)?.toDouble(),
          zonaProtegida: eval?['zona_codigo'] != null
              ? ZonaProtegida(esZonaProtegida: true, nombre: eval!['zona_codigo'].toString())
              : const ZonaProtegida(esZonaProtegida: false),
          normativaCitada: eval?['normativa_codigo'] != null ? [eval!['normativa_codigo'].toString()] : null,
          nivelRiesgo: _parseRiesgo(eval?['nivel_riesgo_codigo'] as String?),
          estadoReporte: EstadoReporte.nuevo,
        );
      } else {
        registroResultado = Registro(
          id: codigoReporte,
          fecha: DateTime.now(),
          ubicacion: Ubicacion(lat: lat ?? -11.4162, lng: lng ?? -67.5441),
          fotos: photos,
          tamanoDraga: tamanoDraga,
          tiempoOperando: tiempoOperando,
          indicadores: IndicadoresVisibles(
            personasVisibles: personasVisibles,
            motobombasVisibles: motobombasVisibles,
          ),
          estadoSync: EstadoSync.sincronizado,
          notas: notas,
        );
      }

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReportResultScreen(registro: registroResultado, api: _api)),
      );
      _registrosKey.currentState?.loadRegistros();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Error al enviar'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  NivelRiesgo? _parseRiesgo(String? c) => switch (c) {
        'BAJO' => NivelRiesgo.bajo,
        'MEDIO' => NivelRiesgo.medio,
        'ALTO' => NivelRiesgo.alto,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          InicioScreen(isOnline: _online),
          RegistrosScreen(
            key: _registrosKey,
            api: _api,
            onConnectionChanged: _onConnectionChanged,
          ),
          AjustesScreen(
            isDarkMode: widget.themeMode == ThemeMode.dark,
            onThemeChanged: (dark) {
              widget.onThemeModeChanged(dark ? ThemeMode.dark : ThemeMode.light);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startNewReport,
        icon: const Icon(Icons.camera_alt_outlined),
        label: const Text('Nuevo registro', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        height: 70,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Registros',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
