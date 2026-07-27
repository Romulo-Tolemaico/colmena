import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/registro.dart';

/// Servicio API para la app mobile (Abeja).
/// Se conecta al backend de Colmena para enviar reportes, subir fotos,
/// consultar evaluaciones y sincronizar.
///
/// La URL base es configurable con --dart-define:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.42:3000/api/v1
class MobileApiService {
  MobileApiService({String? baseUrl})
      : _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:3000/api/v1',
            );

  final String _baseUrl;

  /// URL base del servidor (sin /api/v1) para construir URLs de archivos.
  String get _serverBase {
    final uri = Uri.parse(_baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  // ─────────────────────────────────────────────────────────────────────────
  // Reportes
  // ─────────────────────────────────────────────────────────────────────────

  /// Envía un reporte al API. Retorna el código del reporte creado.
  Future<ApiResult<String>> enviarReporte({
    required double latitud,
    required double longitud,
    required TamanoDraga tamanoDraga,
    required TiempoOperando tiempoOperando,
    required bool personasVisibles,
    required bool motobombasVisibles,
    String? alias,
    String? celular,
    String? nota,
  }) async {
    final body = {
      'latitud': latitud,
      'longitud': longitud,
      'tamano_draga_codigo': _dragaCodigo(tamanoDraga),
      'tiempo_operacion_codigo': _tiempoCodigo(tiempoOperando),
      'personas_visibles': personasVisibles,
      'motobombas_visibles': motobombasVisibles,
      if (alias != null && alias.isNotEmpty) 'alias_informante': alias,
      if (celular != null && celular.isNotEmpty) 'celular_informante': celular,
      if (nota != null && nota.isNotEmpty) 'nota': nota,
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reportes'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return _parseStringResponse(response, 'codigo');
    } catch (e) {
      return ApiResult.error('Sin conexión al servidor');
    }
  }

  /// Sincroniza un lote de reportes offline.
  Future<ApiResult<List<String>>> sincronizarLote(List<Map<String, dynamic>> reportes) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reportes/sync'),
        headers: _headers,
        body: jsonEncode({'reportes': reportes}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        final creados = (data?['creados'] as List<dynamic>?)?.cast<String>() ?? [];
        return ApiResult.success(creados);
      }
      return ApiResult.error(_extractError(response));
    } catch (e) {
      return ApiResult.error('Sin conexión al servidor');
    }
  }

  /// Obtiene la lista de reportes.
  Future<ApiResult<List<Map<String, dynamic>>>> getReportes({int pagina = 1, int porPagina = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reportes?pagina=$pagina&por_pagina=$porPagina'),
        headers: _headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        final reportes = (data?['reportes'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        return ApiResult.success(reportes);
      }
      return ApiResult.error(_extractError(response));
    } catch (e) {
      return ApiResult.error('Sin conexión al servidor');
    }
  }

  /// Obtiene el detalle completo de un reporte (con evaluación).
  Future<ApiResult<Map<String, dynamic>>> getReporteDetalle(String codigo) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reportes/$codigo'),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        return ApiResult.success(data ?? {});
      }
      return ApiResult.error(_extractError(response));
    } catch (e) {
      return ApiResult.error('Sin conexión al servidor');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fotos
  // ─────────────────────────────────────────────────────────────────────────

  /// Sube fotos de evidencia para un reporte (multipart/form-data).
  /// [paths] son las rutas locales de los archivos de imagen.
  Future<ApiResult<List<String>>> subirFotos(String codigoReporte, List<String> paths) async {
    try {
      final uri = Uri.parse('$_baseUrl/reportes/$codigoReporte/fotos');
      final request = http.MultipartRequest('POST', uri);

      for (final path in paths) {
        final file = File(path);
        if (await file.exists()) {
          final length = await file.length();
          if (length > 0) {
            request.files.add(await http.MultipartFile.fromPath('foto', path, filename: path.split('/').last));
          }
        }
      }

      if (request.files.isEmpty) {
        return ApiResult.error('No se encontraron fotos para subir');
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        final fotos = (data?['fotos'] as List<dynamic>?)?.cast<String>() ?? [];
        return ApiResult.success(fotos);
      }
      return ApiResult.error(_extractError(response));
    } catch (e) {
      return ApiResult.error('Error al subir fotos: $e');
    }
  }

  /// Lista las rutas de fotos de un reporte.
  Future<ApiResult<List<String>>> listarFotos(String codigoReporte) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reportes/$codigoReporte/fotos'),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        final fotos = (data?['fotos'] as List<dynamic>?)?.cast<String>() ?? [];
        // Convertir rutas relativas a URLs completas
        return ApiResult.success(fotos.map((f) => '$_serverBase/archivos/$f').toList());
      }
      return ApiResult.error(_extractError(response));
    } catch (e) {
      return ApiResult.error('Sin conexión');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PDF
  // ─────────────────────────────────────────────────────────────────────────

  /// Genera el PDF de un reporte. Retorna la URL del archivo.
  Future<ApiResult<String>> generarPdf(String codigoReporte) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reportes/$codigoReporte/pdf'),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        final ruta = data?['ruta_archivo'] as String? ?? '';
        return ApiResult.success('$_serverBase/archivos/$ruta');
      }
      return ApiResult.error(_extractError(response));
    } catch (e) {
      return ApiResult.error('Sin conexión');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  String _dragaCodigo(TamanoDraga t) => switch (t) {
        TamanoDraga.pequena => 'PEQUENA',
        TamanoDraga.mediana => 'MEDIANA',
        TamanoDraga.grande => 'GRANDE',
      };

  String _tiempoCodigo(TiempoOperando t) => switch (t) {
        TiempoOperando.menosUnDia => 'MENOS_1_DIA',
        TiempoOperando.variosDias => 'VARIOS_DIAS',
        TiempoOperando.masUnaSemana => 'MAS_1_SEMANA',
      };

  ApiResult<String> _parseStringResponse(http.Response response, String field) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>?;
      return ApiResult.success(data?[field]?.toString() ?? '');
    }
    return ApiResult.error(_extractError(response));
  }

  String _extractError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return error?['mensaje'] as String? ?? 'Error del servidor (${response.statusCode})';
    } catch (_) {
      return 'Error del servidor (${response.statusCode})';
    }
  }
}

class ApiResult<T> {
  ApiResult.success(this.data) : error = null;
  ApiResult.error(this.error) : data = null;

  final T? data;
  final String? error;

  bool get isSuccess => data != null;
  bool get isError => error != null;
}
