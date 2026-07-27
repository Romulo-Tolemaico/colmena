//! Tipo de error común de la aplicación. Todos los handlers de axum devuelven
//! `Result<T, ErrorApi>`, y `ErrorApi` implementa `IntoResponse` para que
//! cualquier error se traduzca de forma consistente a JSON:
//!
//! ```json
//! { "error": { "codigo": "...", "mensaje": "..." } }
//! ```

use axum::{
    Json,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use serde::Serialize;
use validator::ValidationErrors;

/// Errores que puede producir cualquier capa de la aplicación (rutas,
/// consultas SQL, validaciones, autenticación, etc.).
#[derive(Debug)]
pub enum ErrorApi {
    /// El payload de entrada no pasó las validaciones de `validator`.
    ValidacionInvalida(ValidationErrors),
    /// Credenciales de login incorrectas.
    CredencialesInvalidas,
    /// El token JWT es inválido, expiró o no vino en la petición.
    NoAutenticado,
    /// El usuario autenticado no tiene permisos para la operación.
    NoAutorizado,
    /// No se encontró el recurso solicitado.
    NoEncontrado(String),
    /// Conflicto de datos (por ejemplo, correo ya registrado).
    Conflicto(String),
    /// Error al hablar con la base de datos.
    ErrorBaseDatos(sqlx::Error),
    /// Error interno no clasificado (hash de contraseñas, JWT, etc.).
    ErrorInterno(String),
    /// La solicitud está mal formada (por ejemplo, un multipart sin archivos
    /// válidos), distinto de una falla de validación de un campo puntual.
    SolicitudInvalida(String),
}

/// Estructura interna del cuerpo de error, serializada como
/// `{ "error": { "codigo": "...", "mensaje": "..." } }`.
#[derive(Serialize)]
struct CuerpoError {
    error: DetalleError,
}

#[derive(Serialize)]
struct DetalleError {
    codigo: String,
    mensaje: String,
}

impl ErrorApi {
    /// Traduce cada variante a un código HTTP y a un par (código, mensaje)
    /// legible para el cliente.
    fn a_respuesta(&self) -> (StatusCode, String, String) {
        match self {
            ErrorApi::ValidacionInvalida(errores) => (
                StatusCode::BAD_REQUEST,
                "VALIDACION_INVALIDA".to_string(),
                format!("los datos enviados no son válidos: {}", errores),
            ),
            ErrorApi::CredencialesInvalidas => (
                StatusCode::UNAUTHORIZED,
                "CREDENCIALES_INVALIDAS".to_string(),
                "el correo o la contraseña son incorrectos".to_string(),
            ),
            ErrorApi::NoAutenticado => (
                StatusCode::UNAUTHORIZED,
                "NO_AUTENTICADO".to_string(),
                "se requiere un token de autenticación válido".to_string(),
            ),
            ErrorApi::NoAutorizado => (
                StatusCode::FORBIDDEN,
                "NO_AUTORIZADO".to_string(),
                "no tiene permisos para realizar esta acción".to_string(),
            ),
            ErrorApi::NoEncontrado(recurso) => (
                StatusCode::NOT_FOUND,
                "NO_ENCONTRADO".to_string(),
                format!("no se encontró el recurso solicitado: {}", recurso),
            ),
            ErrorApi::Conflicto(mensaje) => (
                StatusCode::CONFLICT,
                "CONFLICTO".to_string(),
                mensaje.clone(),
            ),
            ErrorApi::ErrorBaseDatos(error) => {
                tracing::error!(%error, "error de base de datos");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "ERROR_BASE_DATOS".to_string(),
                    "ocurrió un error al acceder a la base de datos".to_string(),
                )
            }
            ErrorApi::ErrorInterno(mensaje) => {
                tracing::error!(%mensaje, "error interno");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "ERROR_INTERNO".to_string(),
                    "ocurrió un error interno en el servidor".to_string(),
                )
            }
            ErrorApi::SolicitudInvalida(mensaje) => (
                StatusCode::BAD_REQUEST,
                "SOLICITUD_INVALIDA".to_string(),
                mensaje.clone(),
            ),
        }
    }
}

impl IntoResponse for ErrorApi {
    fn into_response(self) -> Response {
        let (estado, codigo, mensaje) = self.a_respuesta();
        let cuerpo = CuerpoError {
            error: DetalleError { codigo, mensaje },
        };
        (estado, Json(cuerpo)).into_response()
    }
}

/// Convierte automáticamente los errores de sqlx en `ErrorApi`, para poder
/// usar `?` directamente sobre las llamadas a `sqlx::query(...)`.
impl From<sqlx::Error> for ErrorApi {
    fn from(error: sqlx::Error) -> Self {
        ErrorApi::ErrorBaseDatos(error)
    }
}

/// Convierte automáticamente los errores de validación de `validator`.
impl From<ValidationErrors> for ErrorApi {
    fn from(errores: ValidationErrors) -> Self {
        ErrorApi::ValidacionInvalida(errores)
    }
}
