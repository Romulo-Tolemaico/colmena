//! Handlers axum del módulo reportes: creación, sincronización offline,
//! listado con filtros/paginación, detalle y cambio de estado.
//!
//! Las rutas de creación y listado son públicas (pensadas para la app
//! mobile de la Abeja); el cambio de estado requiere JWT válido (uso de
//! la Colmena) y queda protegido con `route_layer` en `rutas()`.

use axum::{
    Extension, Json, Router,
    extract::{Path, Query, State},
    middleware,
    routing::{get, patch, post},
};
use uuid::Uuid;

use axum::extract::Multipart;

use crate::agent::reglas;
use crate::error::ErrorApi;
use crate::estado::EstadoApp;
use crate::evaluaciones::consultas as consultas_evaluaciones;
use crate::middleware::exigir_jwt;
use crate::respuesta::RespuestaExitosa;
use crate::usuarios::modelo::ClaimsJwt;

use super::consultas::{self, NuevoReporte};
use super::fotos;
use super::pdf;
use super::modelo::{
    CambiarEstadoPeticion, CrearReportePeticion, FiltrosListadoReportes, ListadoReportesRespuesta,
    ReporteDetalle, SincronizarReportesPeticion, SincronizarReportesRespuesta,
};

/// Página por defecto cuando no se indica `pagina` en la query.
const PAGINA_POR_DEFECTO: i64 = 1;
/// Tamaño de página por defecto cuando no se indica `por_pagina`.
const POR_PAGINA_POR_DEFECTO: i64 = 20;
/// Tamaño máximo de página permitido, para evitar consultas abusivas.
const POR_PAGINA_MAXIMO: i64 = 100;

/// Router del módulo reportes. Se anida bajo `/api/v1/reportes` en
/// `main.rs`. Solo el cambio de estado exige JWT.
pub fn rutas() -> Router<EstadoApp> {
    let rutas_protegidas = Router::new()
        .route("/{codigo}/estado", patch(cambiar_estado))
        .route_layer(middleware::from_fn(exigir_jwt));

    Router::new()
        .route("/", post(crear_reporte).get(listar_reportes))
        .route("/sync", post(sincronizar_reportes))
        .route("/{codigo}", get(obtener_detalle))
        .route("/{codigo}/fotos", post(subir_fotos).get(listar_fotos))
        .route("/{codigo}/pdf", post(generar_pdf))
        .merge(rutas_protegidas)
}

/// `POST /api/v1/reportes` — crea un reporte nuevo (sin autenticación de
/// usuario, pensado para la app mobile de la Abeja).
async fn crear_reporte(
    State(estado): State<EstadoApp>,
    Json(peticion): Json<CrearReportePeticion>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    use validator::Validate;
    peticion.validate()?;

    let reporte = consultas::crear_reporte(&estado.pool, datos_desde_peticion(&peticion)).await?;

    // El agente evalúa el reporte automáticamente al crearlo. Si la
    // evaluación falla, se registra el error pero no se revierte la
    // creación del reporte (el reporte queda sin evaluación por ahora).
    if let Err(error) = reglas::evaluar_reporte(&estado.pool, reporte.codigo).await {
        tracing::error!(?error, codigo = %reporte.codigo, "no se pudo evaluar el reporte automáticamente");
    }

    Ok(RespuestaExitosa::creado(reporte))
}

/// `POST /api/v1/reportes/sync` — recibe un lote de reportes guardados
/// offline y los crea uno por uno.
async fn sincronizar_reportes(
    State(estado): State<EstadoApp>,
    Json(peticion): Json<SincronizarReportesPeticion>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    use validator::Validate;
    peticion.validate()?;

    let mut creados = Vec::with_capacity(peticion.reportes.len());
    for item in &peticion.reportes {
        let reporte = consultas::crear_reporte(&estado.pool, datos_desde_peticion(item)).await?;
        if let Err(error) = reglas::evaluar_reporte(&estado.pool, reporte.codigo).await {
            tracing::error!(?error, codigo = %reporte.codigo, "no se pudo evaluar el reporte automáticamente");
        }
        creados.push(reporte.codigo);
    }

    Ok(RespuestaExitosa::creado(SincronizarReportesRespuesta { creados }))
}

/// `GET /api/v1/reportes` — lista reportes con filtros opcionales (estado,
/// zona, fecha) y paginación.
async fn listar_reportes(
    State(estado): State<EstadoApp>,
    Query(filtros): Query<FiltrosListadoReportes>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    let pagina = filtros.pagina.unwrap_or(PAGINA_POR_DEFECTO).max(1);
    let por_pagina = filtros
        .por_pagina
        .unwrap_or(POR_PAGINA_POR_DEFECTO)
        .clamp(1, POR_PAGINA_MAXIMO);

    let (reportes, total) = consultas::listar_reportes(
        &estado.pool,
        filtros.estado.as_deref(),
        filtros.zona,
        filtros.fecha,
        pagina,
        por_pagina,
    )
    .await?;

    Ok(RespuestaExitosa::ok(ListadoReportesRespuesta {
        reportes,
        pagina,
        por_pagina,
        total,
    }))
}

/// `GET /api/v1/reportes/:codigo` — detalle de un reporte, incluyendo su
/// evaluación si ya existe.
async fn obtener_detalle(
    State(estado): State<EstadoApp>,
    Path(codigo): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    let reporte = consultas::buscar_por_codigo(&estado.pool, codigo)
        .await?
        .ok_or_else(|| ErrorApi::NoEncontrado("reporte".to_string()))?;

    let evaluacion = consultas_evaluaciones::buscar_por_reporte(&estado.pool, codigo).await?;

    Ok(RespuestaExitosa::ok(ReporteDetalle { reporte, evaluacion }))
}

/// `PATCH /api/v1/reportes/:codigo/estado` — cambia el estado de un
/// reporte. Requiere JWT válido y registra el cambio en `logs_auditoria`.
async fn cambiar_estado(
    State(estado): State<EstadoApp>,
    Path(codigo): Path<Uuid>,
    Extension(claims): Extension<ClaimsJwt>,
    Json(peticion): Json<CambiarEstadoPeticion>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    use validator::Validate;
    peticion.validate()?;

    let codigo_usuario = Uuid::parse_str(&claims.sub)
        .map_err(|_| ErrorApi::ErrorInterno("el token contiene un código de usuario inválido".to_string()))?;

    let reporte = consultas::cambiar_estado(&estado.pool, codigo, &peticion.estado_codigo, codigo_usuario)
        .await?
        .ok_or_else(|| ErrorApi::NoEncontrado("reporte".to_string()))?;

    Ok(RespuestaExitosa::ok(reporte))
}

/// `POST /api/v1/reportes/:codigo/fotos` — sube una o más fotos de
/// evidencia para un reporte (multipart/form-data). Sin autenticación de
/// usuario, pensado para la app mobile de la Abeja. Las fotos se guardan
/// en el disco local del servidor (ver advertencia sobre filesystem
/// efímero de Render en `reportes::fotos`).
async fn subir_fotos(
    State(estado): State<EstadoApp>,
    Path(codigo): Path<Uuid>,
    multipart: Multipart,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    let rutas = fotos::guardar_fotos(&estado.pool, &estado.configuracion.carpeta_archivos, codigo, multipart).await?;

    Ok(RespuestaExitosa::creado(serde_json::json!({ "fotos": rutas })))
}

/// `GET /api/v1/reportes/:codigo/fotos` — lista las rutas de las fotos de
/// un reporte (relativas a `/archivos/`, servidas como archivos estáticos).
async fn listar_fotos(
    State(estado): State<EstadoApp>,
    Path(codigo): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    let rutas = fotos::listar_fotos(&estado.pool, codigo).await?;

    Ok(RespuestaExitosa::ok(serde_json::json!({ "fotos": rutas })))
}

/// `POST /api/v1/reportes/:codigo/pdf` — genera (o regenera) el PDF del
/// reporte con sus datos y evaluación, y devuelve la ruta relativa del
/// archivo (servido en `/archivos/...`).
async fn generar_pdf(
    State(estado): State<EstadoApp>,
    Path(codigo): Path<Uuid>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    let ruta = pdf::generar_pdf_reporte(&estado.pool, &estado.configuracion.carpeta_archivos, codigo).await?;

    Ok(RespuestaExitosa::creado(serde_json::json!({ "ruta_archivo": ruta })))
}

/// Traduce el DTO de entrada al struct interno usado por la capa de
/// consultas, evitando repetir este mapeo en creación y sincronización.
fn datos_desde_peticion(peticion: &CrearReportePeticion) -> NuevoReporte<'_> {
    NuevoReporte {
        longitud: peticion.longitud,
        latitud: peticion.latitud,
        tamano_draga_codigo: &peticion.tamano_draga_codigo,
        tiempo_operacion_codigo: &peticion.tiempo_operacion_codigo,
        personas_visibles: peticion.personas_visibles,
        motobombas_visibles: peticion.motobombas_visibles,
        alias_informante: peticion.alias_informante.as_deref(),
        celular_informante: peticion.celular_informante.as_deref(),
        nota: peticion.nota.as_deref(),
    }
}
