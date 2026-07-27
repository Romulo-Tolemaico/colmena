//! Handlers axum del módulo dashboard: métricas acumuladas y GeoJSON del
//! mapa para la Colmena. Todas las rutas requieren JWT válido.

use axum::{Json, Router, extract::State, middleware, routing::get};
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
    denuncias_por_mes: Vec<super::consultas::DenunciasPorMes>,
}

/// Payload de entrada para `POST /api/v1/dashboard/chat`.
#[derive(Debug, serde::Deserialize)]
struct ChatPeticion {
    mensaje: String,
}

/// Respuesta de `POST /api/v1/dashboard/chat`.
#[derive(Debug, Serialize)]
struct ChatRespuesta {
    respuesta: String,
}

/// Router del módulo dashboard. Todas las rutas exigen JWT válido.
pub fn rutas() -> Router<EstadoApp> {
    Router::new()
        .route("/metricas", get(obtener_metricas))
        .route("/mapa", get(obtener_mapa))
        .route("/chat", axum::routing::post(chat))
        .route_layer(middleware::from_fn(exigir_jwt))
}

/// `GET /api/v1/dashboard/metricas` — resumen acumulado (total reportes,
/// mercurio acumulado, % anónimos, zonas afectadas).
async fn obtener_metricas(
    State(estado): State<EstadoApp>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    let metricas = consultas::obtener_metricas(&estado.pool).await?;
    let denuncias_por_mes = consultas::obtener_denuncias_por_mes(&estado.pool).await?;

    Ok(RespuestaExitosa::ok(MetricasRespuesta {
        total_reportes: metricas.total_reportes,
        mercurio_acumulado_kg: metricas.mercurio_acumulado_kg,
        porcentaje_anonimos: metricas.porcentaje_anonimos,
        zonas_afectadas: metricas.zonas_afectadas,
        denuncias_por_mes,
    }))
}

/// `GET /api/v1/dashboard/mapa` — GeoJSON de los puntos para el mapa.
async fn obtener_mapa(
    State(estado): State<EstadoApp>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    let geojson = consultas::obtener_geojson_mapa(&estado.pool).await?;

    Ok(RespuestaExitosa::ok(geojson))
}

/// `POST /api/v1/dashboard/chat` — responde preguntas simples sobre los
/// datos del sistema usando reglas por palabra clave (sin LLM real todavía;
/// queda documentado en `agent::reglas` como integración futura).
async fn chat(
    State(estado): State<EstadoApp>,
    Json(peticion): Json<ChatPeticion>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    let mensaje_normalizado = peticion.mensaje.to_lowercase();
    let metricas = consultas::obtener_metricas(&estado.pool).await?;

    let respuesta = if mensaje_normalizado.contains("mercurio") {
        format!(
            "Se estima un total acumulado de {:.2} kg de mercurio en los reportes registrados.",
            metricas.mercurio_acumulado_kg
        )
    } else if mensaje_normalizado.contains("zona") {
        format!(
            "Hay {} zona(s) protegida(s) afectadas por reportes registrados.",
            metricas.zonas_afectadas
        )
    } else if mensaje_normalizado.contains("anonim") {
        format!(
            "El {:.1}% de los reportes fueron enviados de forma anónima (sin datos de contacto).",
            metricas.porcentaje_anonimos
        )
    } else if mensaje_normalizado.contains("total")
        || mensaje_normalizado.contains("cuant")
        || mensaje_normalizado.contains("cuánt")
    {
        format!("Actualmente hay {} reporte(s) registrados en el sistema.", metricas.total_reportes)
    } else {
        format!(
            "Puedo responder sobre el total de reportes ({}), el mercurio acumulado estimado ({:.2} kg), \
             el porcentaje de reportes anónimos ({:.1}%) o las zonas protegidas afectadas ({}). \
             Probá preguntando por alguno de esos temas.",
            metricas.total_reportes, metricas.mercurio_acumulado_kg, metricas.porcentaje_anonimos, metricas.zonas_afectadas
        )
    };

    Ok(RespuestaExitosa::ok(ChatRespuesta { respuesta }))
}
