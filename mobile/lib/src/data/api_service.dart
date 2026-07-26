import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/registro.dart';

/// Servicio API para la app mobile (Abeja).
/// Se conecta al backend de Colmena para enviar reportes y sincronizar.
class MobileApiService {
  MobileApiService({String? baseUrl})
      : _baseUrl = baseUrl ?? 'http://10.0.2.2:3000/api/v1'; // 10.0.2.2 es localhost desde emulador Android

  final String _baseUrl;

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  /// Envía un reporte al API.
  /// Retorna el código del reporte creado o un error.
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

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        final codigo = data?['codigo'] as String? ?? '';
        return ApiResult.success(codigo);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return ApiResult.error(error?['mensaje'] as String? ?? 'Error al enviar reporte');
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

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return ApiResult.error(error?['mensaje'] as String? ?? 'Error al sincronizar');
    } catch (e) {
      return ApiResult.error('Sin conexión al servidor');
    }
  }

  /// Obtiene la lista de reportes desde el API.
  Future<ApiResult<List<Map<String, dynamic>>>> getReportes({int pagina = 1, int porPagina = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reportes?pagina=$pagina&por_pagina=$porPagina'),
        headers: _headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = json['data'] as Map<String, dynamic>?;
        final reportes = (data?['reportes'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
        return ApiResult.success(reportes);
      }

      return ApiResult.error('Error al cargar reportes');
    } catch (e) {
      return ApiResult.error('Sin conexión al servidor');
    }
  }

  // Helpers de mapeo
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
}

class ApiResult<T> {
  ApiResult.success(this.data) : error = null;
  ApiResult.error(this.error) : data = null;

  final T? data;
  final String? error;

  bool get isSuccess => data != null;
  bool get isError => error != null;
}
