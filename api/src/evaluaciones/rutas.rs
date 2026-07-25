//! Handlers axum del módulo evaluaciones: consulta del resultado del
//! agente para un reporte determinado.

use axum::{Router, extract::Path, extract::State, routing::get};
use uuid::Uuid;

use crate::error::ErrorApi;
use crate::estado::EstadoApp;
use crate::respuesta::RespuestaExitosa;

use super::consultas;

/// Router del módulo evaluaciones. Se anida bajo `/reportes` en
/// `main.rs`, por lo que la ruta final queda
/// `/api/v1/reportes/:codigo/evaluacion`.
pub fn rutas() -> Router<EstadoApp> {
    Router::new().route("/{codigo}/evaluacion", get(obtener_evaluacion))
}

/// `GET /api/v1/reportes/:codigo/evaluacion` — devuelve el resultado del
/// agente para el reporte indicado.
async fn obtener_evaluacion(
    State(estado): State<EstadoApp>,
    Path(codigo): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    let evaluacion = consultas::buscar_por_reporte(&estado.pool, codigo)
        .await?
        .ok_or_else(|| ErrorApi::NoEncontrado("evaluación del reporte".to_string()))?;

    Ok(RespuestaExitosa::ok(evaluacion))
}
