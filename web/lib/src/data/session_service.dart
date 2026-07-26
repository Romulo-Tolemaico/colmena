import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Datos del usuario autenticado.
class UserSession {
  const UserSession({
    required this.token,
    required this.nombre,
    required this.correo,
    required this.rol,
  });

  final String token;
  final String nombre;
  final String correo;
  final String rol;

  Map<String, dynamic> toJson() => {
        'token': token,
        'nombre': nombre,
        'correo': correo,
        'rol': rol,
      };

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        token: json['token'] as String,
        nombre: json['nombre'] as String,
        correo: json['correo'] as String,
        rol: json['rol'] as String,
      );
}

/// Servicio que persiste la sesión del usuario en localStorage.
class SessionService {
  static const _key = 'colmena_session';

  /// Guarda la sesión.
  Future<void> save(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  /// Recupera la sesión guardada (null si no hay).
  Future<UserSession?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserSession.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Borra la sesión (logout).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
