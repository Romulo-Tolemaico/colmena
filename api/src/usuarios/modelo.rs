//! Structs del módulo usuarios: entidades de base de datos y DTOs de
//! entrada/salida para las rutas de creación de usuario, login y refresh.

use chrono::{NaiveDate, NaiveTime};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

/// Fila de la tabla `usuarios`, tal cual se guarda en la base de datos.
#[derive(Debug, Clone, sqlx::FromRow, Serialize)]
pub struct Usuario {
    pub codigo: Uuid,
    pub nombre: String,
    pub correo: String,
    /// El hash nunca debe salir en las respuestas JSON de la API.
    #[serde(skip_serializing)]
    pub contrasena_hash: String,
    pub rol_codigo: String,
    pub fecha_creacion: NaiveDate,
    pub hora_creacion: NaiveTime,
}

/// Datos públicos de un usuario, seguros para devolver al cliente.
#[derive(Debug, Serialize)]
pub struct UsuarioPublico {
    pub codigo: Uuid,
    pub nombre: String,
    pub correo: String,
    pub rol_codigo: String,
}

impl From<Usuario> for UsuarioPublico {
    fn from(usuario: Usuario) -> Self {
        UsuarioPublico {
            codigo: usuario.codigo,
            nombre: usuario.nombre,
            correo: usuario.correo,
            rol_codigo: usuario.rol_codigo,
        }
    }
}

/// Payload de entrada para `POST /api/v1/usuarios`.
#[derive(Debug, Deserialize, Validate)]
pub struct CrearUsuarioPeticion {
    #[validate(length(min = 1, message = "el nombre no puede estar vacío"))]
    pub nombre: String,
    #[validate(email(message = "el correo no tiene un formato válido"))]
    pub correo: String,
    #[validate(length(min = 8, message = "la contraseña debe tener al menos 8 caracteres"))]
    pub contrasena: String,
    #[validate(length(min = 1, message = "el rol es obligatorio"))]
    pub rol_codigo: String,
}

/// Payload de entrada para `POST /api/v1/auth/login`.
#[derive(Debug, Deserialize, Validate)]
pub struct LoginPeticion {
    #[validate(email(message = "el correo no tiene un formato válido"))]
    pub correo: String,
    #[validate(length(min = 1, message = "la contraseña es obligatoria"))]
    pub contrasena: String,
}

/// Respuesta de login/refresh: el JWT emitido y su tipo.
#[derive(Debug, Serialize)]
pub struct TokenRespuesta {
    pub token: String,
    pub tipo: String,
}

/// Payload de entrada para `POST /api/v1/auth/refresh`.
#[derive(Debug, Deserialize, Validate)]
pub struct RefrescarTokenPeticion {
    #[validate(length(min = 1, message = "el token es obligatorio"))]
    pub token: String,
}

/// Claims (contenido) del JWT emitido por la API.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ClaimsJwt {
    /// Código (UUID) del usuario, como subject del token.
    pub sub: String,
    /// Rol del usuario, para autorización basada en roles si se necesita.
    pub rol: String,
    /// Fecha de expiración del token (timestamp UNIX).
    pub exp: usize,
}
