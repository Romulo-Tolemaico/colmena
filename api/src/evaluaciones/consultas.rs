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
