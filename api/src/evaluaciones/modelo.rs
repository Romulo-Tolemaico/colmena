//! Structs del módulo evaluaciones: resultado del análisis del agente sobre
//! un reporte (factor de mercurio, nivel de riesgo, zona y normativa
//! asociadas).

use chrono::{NaiveDate, NaiveTime};
use serde::Serialize;
use uuid::Uuid;

/// Fila de la tabla `evaluaciones`, resultado del análisis del agente para
/// un reporte determinado.
///
/// Nota: las columnas numéricas (`NUMERIC` en PostgreSQL) se leen como
/// `f64` porque el proyecto no usa la crate `rust_decimal`/`bigdecimal`;
/// las consultas SQL castean explícitamente esas columnas a
/// `double precision` para que sqlx pueda mapearlas sin macros.
#[derive(Debug, Clone, sqlx::FromRow, Serialize)]
pub struct Evaluacion {
    pub reporte_codigo: Uuid,
    pub factor_mercurio: f64,
    pub mercurio_estimado_kg: f64,
    pub zona_codigo: Option<Uuid>,
    pub normativa_codigo: Option<Uuid>,
    pub nivel_riesgo_codigo: String,
    pub fecha_creacion: NaiveDate,
    pub hora_creacion: NaiveTime,
}
