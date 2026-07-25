//! Handlers axum del módulo dashboard: métricas acumuladas y GeoJSON del
//! mapa para la Colmena. Todas las rutas requieren JWT válido.

use axum::{Router, extract::State, middleware, routing::get};
use serde::Serialize;

use crate::error::ErrorApi;
use crate::estado::EstadoApp;
use crate::middleware::exigir_jwt;
use crate::respuesta::RespuestaExitosa;

use super::consultas;

/// Respuesta de `GET /api/v1/dashboard/metricas`.
#[derive(Debug, Serialize)]
struct MetricasRespuesta {
    total_reportes: i64,
    mercurio_acumulado_kg: f64,
    porcentaje_anonimos: f64,
    zonas_afectadas: i64,
}

/// Router del módulo dashboard. Todas las rutas exigen JWT válido.
pub fn rutas() -> Router<EstadoApp> {
    Router::new()
        .route("/metricas", get(obtener_metricas))
        .route("/mapa", get(obtener_mapa))
        .route_layer(middleware::from_fn(exigir_jwt))
}

/// `GET /api/v1/dashboard/metricas` — resumen acumulado (total reportes,
/// mercurio acumulado, % anónimos, zonas afectadas).
async fn obtener_metricas(
    State(estado): State<EstadoApp>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    let metricas = consultas::obtener_metricas(&estado.pool).await?;

    Ok(RespuestaExitosa::ok(MetricasRespuesta {
        total_reportes: metricas.total_reportes,
        mercurio_acumulado_kg: metricas.mercurio_acumulado_kg,
        porcentaje_anonimos: metricas.porcentaje_anonimos,
        zonas_afectadas: metricas.zonas_afectadas,
    }))
}

/// `GET /api/v1/dashboard/mapa` — GeoJSON de los puntos para el mapa.
async fn obtener_mapa(
    State(estado): State<EstadoApp>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    let geojson = consultas::obtener_geojson_mapa(&estado.pool).await?;

    Ok(RespuestaExitosa::ok(geojson))
}
