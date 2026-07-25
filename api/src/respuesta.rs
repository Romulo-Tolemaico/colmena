//! Struct genérico de respuesta JSON exitosa, usado por todos los handlers
//! para mantener un formato consistente: `{ "data": ... }`.
//! Las respuestas de error usan `ErrorApi` (ver `error.rs`), no este struct.

use axum::{Json, http::StatusCode, response::IntoResponse};
use serde::Serialize;

/// Envoltorio genérico para toda respuesta exitosa de la API.
#[derive(Serialize)]
pub struct RespuestaExitosa<T: Serialize> {
    data: T,
}

impl<T: Serialize> RespuestaExitosa<T> {
    /// Construye una respuesta exitosa con código HTTP 200 (OK).
    pub fn ok(data: T) -> impl IntoResponse {
        (StatusCode::OK, Json(RespuestaExitosa { data }))
    }

    /// Construye una respuesta exitosa con código HTTP 201 (Created),
    /// pensada para operaciones que crean un recurso nuevo.
    pub fn creado(data: T) -> impl IntoResponse {
        (StatusCode::CREATED, Json(RespuestaExitosa { data }))
    }
}
