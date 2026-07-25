//! Structs del módulo reportes: entidad de base de datos y DTOs de
//! entrada/salida para creación, sincronización, listado y detalle de
//! reportes de la app mobile (la Abeja).

use chrono::{NaiveDate, NaiveTime};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use validator::Validate;

use crate::evaluaciones::modelo::Evaluacion;

/// Fila de la tabla `reportes`. La ubicación se maneja como longitud/latitud
/// por separado en los DTOs, pero en la base de datos vive en la columna
/// `ubicacion GEOGRAPHY(POINT, 4326)`.
#[derive(Debug, Clone, sqlx::FromRow, Serialize)]
pub struct Reporte {
    pub codigo: Uuid,
    pub longitud: f64,
    pub latitud: f64,
    pub tamano_draga_codigo: String,
    pub tiempo_operacion_codigo: String,
    pub personas_visibles: bool,
    pub motobombas_visibles: bool,
    pub estado_codigo: String,
    pub fecha_creacion: NaiveDate,
    pub hora_creacion: NaiveTime,
}

/// Detalle completo de un reporte, incluyendo su evaluación si ya existe.
#[derive(Debug, Serialize)]
pub struct ReporteDetalle {
    #[serde(flatten)]
    pub reporte: Reporte,
    pub evaluacion: Option<Evaluacion>,
}

/// Payload de entrada para `POST /api/v1/reportes`.
#[derive(Debug, Deserialize, Validate)]
pub struct CrearReportePeticion {
    #[validate(range(min = -180.0, max = 180.0, message = "longitud fuera de rango"))]
    pub longitud: f64,
    #[validate(range(min = -90.0, max = 90.0, message = "latitud fuera de rango"))]
    pub latitud: f64,
    #[validate(length(min = 1, message = "el tamaño de draga es obligatorio"))]
    pub tamano_draga_codigo: String,
    #[validate(length(min = 1, message = "el tiempo de operación es obligatorio"))]
    pub tiempo_operacion_codigo: String,
    pub personas_visibles: bool,
    pub motobombas_visibles: bool,
    /// Alias opcional del informante (dato de contacto, tabla débil).
    pub alias_informante: Option<String>,
    /// Celular opcional del informante (dato de contacto, tabla débil).
    pub celular_informante: Option<String>,
    /// Nota libre opcional sobre el reporte.
    pub nota: Option<String>,
}

/// Un lote de reportes guardados offline por la app mobile, enviado en
/// `POST /api/v1/reportes/sync`.
#[derive(Debug, Deserialize, Validate)]
pub struct SincronizarReportesPeticion {
    #[validate(nested)]
    pub reportes: Vec<CrearReportePeticion>,
}

/// Resultado de sincronizar un lote: cuántos se guardaron y sus códigos.
#[derive(Debug, Serialize)]
pub struct SincronizarReportesRespuesta {
    pub creados: Vec<Uuid>,
}

/// Filtros y paginación para `GET /api/v1/reportes`.
#[derive(Debug, Deserialize)]
pub struct FiltrosListadoReportes {
    pub estado: Option<String>,
    pub zona: Option<Uuid>,
    pub fecha: Option<NaiveDate>,
    pub pagina: Option<i64>,
    pub por_pagina: Option<i64>,
}

/// Respuesta paginada de reportes.
#[derive(Debug, Serialize)]
pub struct ListadoReportesRespuesta {
    pub reportes: Vec<Reporte>,
    pub pagina: i64,
    pub por_pagina: i64,
    pub total: i64,
}

/// Payload de entrada para `PATCH /api/v1/reportes/:codigo/estado`.
#[derive(Debug, Deserialize, Validate)]
pub struct CambiarEstadoPeticion {
    #[validate(length(min = 1, message = "el estado es obligatorio"))]
    pub estado_codigo: String,
}
