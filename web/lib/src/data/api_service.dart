import 'dart:convert';

import 'package:http/http.dart' as http;

/// Servicio central para comunicarse con la API de Colmena (Panel Web).
/// Maneja la URL base, el token JWT, y todas las llamadas HTTP.
class ApiService {
  ApiService({String? baseUrl})
      : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'https://colmena-1mlk.onrender.com/api/v1',
            );

  final String _baseUrl;
  String? _token;

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  /// URL base del servidor (sin /api/v1) para construir URLs de archivos.
  String get serverBase {
    final uri = Uri.parse(_baseUrl);
    if (uri.port == 443 || uri.port == 80 || uri.scheme == 'https') {
      return '${uri.scheme}://${uri.host}';
    }
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ─────────────────────────────────────────────────────────────────────────
  // Auth
  // ─────────────────────────────────────────────────────────────────────────

  Future<ApiResult<LoginResponse>> login(String correo, String contrasena) async {
    final res = await _post('/auth/login', {
      'correo': correo,
      'contrasena': contrasena,
    });

    if (res.ok) {
      final data = res.data!;
      _token = data['token'] as String;
      return ApiResult.success(LoginResponse(token: _token!, tipo: data['tipo'] as String));
    }
    return ApiResult.error(res.errorMessage ?? 'Error al iniciar sesión');
  }

  Future<ApiResult<UserResponse>> register({
    required String nombre,
    required String correo,
    required String contrasena,
    required String rolCodigo,
  }) async {
    final res = await _post('/usuarios', {
      'nombre': nombre,
      'correo': correo,
      'contrasena': contrasena,
      'rol_codigo': rolCodigo,
    });

    if (res.ok) {
      final data = res.data!;
      return ApiResult.success(UserResponse(
        codigo: data['codigo'] as String,
        nombre: data['nombre'] as String,
        correo: data['correo'] as String,
        rolCodigo: data['rol_codigo'] as String,
      ));
    }
    return ApiResult.error(res.errorMessage ?? 'Error al registrar');
  }

  /// Obtiene los datos del usuario autenticado (GET /usuarios/me).
  Future<ApiResult<UserResponse>> getUsuarioActual() async {
    final res = await _get('/usuarios/me');
    if (res.ok) {
      final data = res.data!;
      return ApiResult.success(UserResponse(
        codigo: data['codigo'] as String? ?? '',
        nombre: data['nombre'] as String? ?? '',
        correo: data['correo'] as String? ?? '',
        rolCodigo: data['rol_codigo'] as String? ?? '',
      ));
    }
    return ApiResult.error(res.errorMessage ?? 'Error al obtener usuario');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Dashboard
  // ─────────────────────────────────────────────────────────────────────────

  Future<ApiResult<Map<String, dynamic>>> getMetricas() async {
    final res = await _get('/dashboard/metricas');
    if (res.ok) return ApiResult.success(res.data!);
    return ApiResult.error(res.errorMessage ?? 'Error al cargar métricas');
  }

  Future<ApiResult<Map<String, dynamic>>> getMapa() async {
    final res = await _get('/dashboard/mapa');
    if (res.ok) return ApiResult.success(res.data!);
    return ApiResult.error(res.errorMessage ?? 'Error al cargar mapa');
  }

  /// Chat del dashboard: envía una pregunta y recibe respuesta del servidor.
  Future<ApiResult<String>> chatDashboard(String mensaje) async {
    final res = await _post('/dashboard/chat', {'mensaje': mensaje});
    if (res.ok) {
      final respuesta = res.data?['respuesta'] as String? ?? '';
      return ApiResult.success(respuesta);
    }
    return ApiResult.error(res.errorMessage ?? 'Error en el chat');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Reportes
  // ─────────────────────────────────────────────────────────────────────────

  Future<ApiResult<Map<String, dynamic>>> getReportes({
    int pagina = 1,
    int porPagina = 20,
    String? estado,
    String? zona,
    String? fecha,
  }) async {
    final params = <String, String>{
      'pagina': pagina.toString(),
      'por_pagina': porPagina.toString(),
      if (estado != null) 'estado': estado,
      if (zona != null) 'zona': zona,
      if (fecha != null) 'fecha': fecha,
    };
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final res = await _get('/reportes?$query');
    if (res.ok) return ApiResult.success(res.data!);
    return ApiResult.error(res.errorMessage ?? 'Error al cargar reportes');
  }

  Future<ApiResult<Map<String, dynamic>>> getReporte(String codigo) async {
    final res = await _get('/reportes/$codigo');
    if (res.ok) return ApiResult.success(res.data!);
    return ApiResult.error(res.errorMessage ?? 'Error al cargar reporte');
  }

  Future<ApiResult<Map<String, dynamic>>> cambiarEstado(String codigo, String estadoCodigo) async {
    final res = await _patch('/reportes/$codigo/estado', {
      'estado_codigo': estadoCodigo,
    });
    if (res.ok) return ApiResult.success(res.data!);
    return ApiResult.error(res.errorMessage ?? 'Error al cambiar estado');
  }

  /// Lista las fotos de un reporte. Retorna URLs completas.
  Future<ApiResult<List<String>>> listarFotos(String codigoReporte) async {
    final res = await _get('/reportes/$codigoReporte/fotos');
    if (res.ok) {
      final fotos = (res.data?['fotos'] as List<dynamic>?)?.cast<String>() ?? [];
      return ApiResult.success(fotos.map((f) => '$serverBase/archivos/$f').toList());
    }
    return ApiResult.error(res.errorMessage ?? 'Error al cargar fotos');
  }

  /// Genera el PDF de un reporte. Retorna la URL del archivo.
  Future<ApiResult<String>> generarPdf(String codigoReporte) async {
    final res = await _post('/reportes/$codigoReporte/pdf', {});
    if (res.ok) {
      final ruta = res.data?['ruta_archivo'] as String? ?? '';
      return ApiResult.success('$serverBase/archivos/$ruta');
    }
    return ApiResult.error(res.errorMessage ?? 'Error al generar PDF');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HTTP helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<_RawResponse> _get(String path) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$path'), headers: _headers);
      return _parseResponse(response);
    } catch (e) {
      return _RawResponse(ok: false, errorMessage: 'Sin conexión al servidor');
    }
  }

  Future<_RawResponse> _post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _parseResponse(response);
    } catch (e) {
      return _RawResponse(ok: false, errorMessage: 'Sin conexión al servidor');
    }
  }

  Future<_RawResponse> _patch(String path, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _parseResponse(response);
    } catch (e) {
      return _RawResponse(ok: false, errorMessage: 'Sin conexión al servidor');
    }
  }

  _RawResponse _parseResponse(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _RawResponse(ok: true, data: json['data'] as Map<String, dynamic>?);
      }

      final error = json['error'] as Map<String, dynamic>?;
      final mensaje = error?['mensaje'] as String? ?? 'Error desconocido';
      return _RawResponse(ok: false, errorMessage: mensaje);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _RawResponse(ok: true);
      }
      return _RawResponse(ok: false, errorMessage: 'Error del servidor (${response.statusCode})');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _RawResponse {
  const _RawResponse({required this.ok, this.data, this.errorMessage});
  final bool ok;
  final Map<String, dynamic>? data;
  final String? errorMessage;
}

class ApiResult<T> {
  ApiResult.success(this.data) : error = null;
  ApiResult.error(this.error) : data = null;
  final T? data;
  final String? error;
  bool get isSuccess => data != null;
  bool get isError => error != null;
}

class LoginResponse {
  const LoginResponse({required this.token, required this.tipo});
  final String token;
  final String tipo;
}

class UserResponse {
  const UserResponse({required this.codigo, required this.nombre, required this.correo, required this.rolCodigo});
  final String codigo;
  final String nombre;
  final String correo;
  final String rolCodigo;
}
