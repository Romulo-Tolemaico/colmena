//! Consultas SQL del módulo evaluaciones. Todo el SQL se escribe a mano
//! como texto y se ejecuta con las funciones `sqlx::query_as` (sin macros).

use sqlx::PgPool;
use uuid::Uuid;

use super::modelo::Evaluacion;

/// Busca la evaluación asociada a un reporte. Devuelve `None` si el
/// reporte todavía no fue evaluado por el agente.
pub async fn buscar_por_reporte(
    pool: &PgPool,
    codigo_reporte: Uuid,
) -> Result<Option<Evaluacion>, sqlx::Error> {
    sqlx::query_as::<_, Evaluacion>(
        r#"
        SELECT
            reporte_codigo,
            factor_mercurio::DOUBLE PRECISION AS factor_mercurio,
            mercurio_estimado_kg::DOUBLE PRECISION AS mercurio_estimado_kg,
            zona_codigo,
            normativa_codigo,
            nivel_riesgo_codigo,
            fecha_creacion,
            hora_creacion
        FROM evaluaciones
        WHERE reporte_codigo = $1
        "#,
    )
    .bind(codigo_reporte)
    .fetch_optional(pool)
    .await
}

/// Busca la zona protegida cuyo polígono contiene la ubicación del
/// reporte indicado, usando `ST_Within` de PostGIS. Devuelve `None` si el
/// punto no cae dentro de ninguna zona protegida registrada.
pub async fn buscar_zona_protegida_del_reporte(
    pool: &PgPool,
    codigo_reporte: Uuid,
) -> Result<Option<Uuid>, sqlx::Error> {
    sqlx::query_scalar(
        r#"
        SELECT z.codigo
        FROM zonas_protegidas z
        JOIN reportes r ON ST_Within(r.ubicacion::geometry, z.geom::geometry)
        WHERE r.codigo = $1
        LIMIT 1
        "#,
    )
    .bind(codigo_reporte)
    .fetch_optional(pool)
    .await
}

/// Busca una normativa asociada al tipo de zona indicado (heurística
/// simple: la primera normativa registrada; el esquema no vincula
/// normativa con tipo de zona de forma explícita, así que esto es lo
/// mejor que se puede hacer sin ampliar el modelo de datos).
pub async fn buscar_normativa_general(pool: &PgPool) -> Result<Option<Uuid>, sqlx::Error> {
    sqlx::query_scalar("SELECT codigo FROM normativa ORDER BY codigo LIMIT 1")
        .fetch_optional(pool)
        .await
}

/// Datos necesarios para insertar el resultado de la evaluación del agente.
pub struct NuevaEvaluacion {
    pub reporte_codigo: Uuid,
    pub factor_mercurio: f64,
    pub mercurio_estimado_kg: f64,
    pub zona_codigo: Option<Uuid>,
    pub normativa_codigo: Option<Uuid>,
    pub nivel_riesgo_codigo: String,
}

/// Inserta la evaluación de un reporte. Si ya existía una evaluación para
/// ese reporte, la reemplaza (un reporte solo tiene una evaluación vigente
/// a la vez, según el esquema: `evaluaciones.reporte_codigo` es PK).
pub async fn insertar_evaluacion(pool: &PgPool, datos: NuevaEvaluacion) -> Result<Evaluacion, sqlx::Error> {
    sqlx::query_as::<_, Evaluacion>(
        r#"
        INSERT INTO evaluaciones (
            reporte_codigo, factor_mercurio, mercurio_estimado_kg,
            zona_codigo, normativa_codigo, nivel_riesgo_codigo
        )
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (reporte_codigo) DO UPDATE SET
            factor_mercurio = EXCLUDED.factor_mercurio,
            mercurio_estimado_kg = EXCLUDED.mercurio_estimado_kg,
            zona_codigo = EXCLUDED.zona_codigo,
            normativa_codigo = EXCLUDED.normativa_codigo,
            nivel_riesgo_codigo = EXCLUDED.nivel_riesgo_codigo
        RETURNING
            reporte_codigo,
            factor_mercurio::DOUBLE PRECISION AS factor_mercurio,
            mercurio_estimado_kg::DOUBLE PRECISION AS mercurio_estimado_kg,
            zona_codigo,
            normativa_codigo,
            nivel_riesgo_codigo,
            fecha_creacion,
            hora_creacion
        "#,
    )
    .bind(datos.reporte_codigo)
    .bind(datos.factor_mercurio)
    .bind(datos.mercurio_estimado_kg)
    .bind(datos.zona_codigo)
    .bind(datos.normativa_codigo)
    .bind(datos.nivel_riesgo_codigo)
    .fetch_one(pool)
    .await
}
