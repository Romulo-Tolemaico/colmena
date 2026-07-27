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

/// `POST /api/v1/dashboard/chat` — responde preguntas usando Groq (Llama 3)
/// con contexto de los datos del sistema. Si no hay API key configurada o
/// falla la llamada, cae a un fallback local por keywords.
async fn chat(
    State(estado): State<EstadoApp>,
    Json(peticion): Json<ChatPeticion>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    let metricas = consultas::obtener_metricas(&estado.pool).await?;

    // Intentar Groq si hay API key
    if let Some(api_key) = &estado.configuracion.groq_api_key {
        if !api_key.is_empty() {
            let contexto = format!(
                "Eres el asistente IA de Colmena, un sistema de monitoreo comunitario contra la minería ilegal en ríos de Bolivia. \
                 Datos actuales del sistema:\n\
                 - Total de reportes: {}\n\
                 - Mercurio acumulado estimado: {:.2} kg\n\
                 - Zonas protegidas afectadas: {}\n\
                 - Porcentaje de reportes anónimos: {:.1}%\n\n\
                 Responde de forma concisa y útil en español. Si preguntan algo fuera del tema ambiental/minería, redirige amablemente.",
                metricas.total_reportes, metricas.mercurio_acumulado_kg,
                metricas.zonas_afectadas, metricas.porcentaje_anonimos
            );

            match llamar_groq(api_key, &contexto, &peticion.mensaje).await {
                Ok(respuesta) => return Ok(RespuestaExitosa::ok(ChatRespuesta { respuesta })),
                Err(e) => {
                    tracing::warn!("Groq falló, usando fallback: {e}");
                }
            }
        }
    }

    // Fallback local por keywords
    let mensaje_normalizado = peticion.mensaje.to_lowercase();
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
            "El {:.1}% de los reportes fueron enviados de forma anónima.",
            metricas.porcentaje_anonimos
        )
    } else if mensaje_normalizado.contains("total")
        || mensaje_normalizado.contains("cuant")
        || mensaje_normalizado.contains("cuánt")
    {
        format!("Actualmente hay {} reporte(s) registrados en el sistema.", metricas.total_reportes)
    } else {
        format!(
            "Puedo responder sobre reportes ({}), mercurio ({:.2} kg), \
             reportes anónimos ({:.1}%) o zonas afectadas ({}).",
            metricas.total_reportes, metricas.mercurio_acumulado_kg,
            metricas.porcentaje_anonimos, metricas.zonas_afectadas
        )
    };

    Ok(RespuestaExitosa::ok(ChatRespuesta { respuesta }))
}

/// Llama a la API de Groq con el modelo Llama 3.3.
async fn llamar_groq(api_key: &str, contexto: &str, mensaje: &str) -> Result<String, String> {
    let body = serde_json::json!({
        "model": "llama-3.3-70b-versatile",
        "messages": [
            {"role": "system", "content": contexto},
            {"role": "user", "content": mensaje}
        ],
        "temperature": 0.7,
        "max_tokens": 500
    });

    let client = reqwest::Client::new();
    let response = client
        .post("https://api.groq.com/openai/v1/chat/completions")
        .header("Authorization", format!("Bearer {api_key}"))
        .header("Content-Type", "application/json")
        .json(&body)
        .send()
        .await
        .map_err(|e| format!("Error de conexión a Groq: {e}"))?;

    if !response.status().is_success() {
        let status = response.status();
        let text = response.text().await.unwrap_or_default();
        return Err(format!("Groq respondió {status}: {text}"));
    }

    let json: serde_json::Value = response
        .json()
        .await
        .map_err(|e| format!("Error al parsear respuesta de Groq: {e}"))?;

    json["choices"][0]["message"]["content"]
        .as_str()
        .map(|s| s.to_string())
        .ok_or_else(|| "Respuesta de Groq sin contenido".to_string())
}
