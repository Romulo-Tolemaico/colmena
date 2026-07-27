//! Consultas SQL del módulo dashboard: métricas acumuladas y GeoJSON de
//! puntos para el mapa. Todo el SQL se escribe a mano como texto.

use serde_json::Value;
use sqlx::PgPool;

/// Métricas acumuladas: total de reportes, mercurio acumulado estimado,
/// porcentaje de reportes anónimos (sin contacto de informante) y cantidad
/// de zonas protegidas afectadas.
pub struct MetricasCrudo {
    pub total_reportes: i64,
    pub mercurio_acumulado_kg: f64,
    pub porcentaje_anonimos: f64,
    pub zonas_afectadas: i64,
}

/// Un punto de la serie "denuncias por mes": mes (`YYYY-MM`) y cantidad de
/// reportes creados en ese mes.
#[derive(Debug, sqlx::FromRow, serde::Serialize)]
pub struct DenunciasPorMes {
    pub mes: String,
    pub cantidad: i64,
}

/// Calcula el resumen acumulado para `GET /api/v1/dashboard/metricas`.
pub async fn obtener_metricas(pool: &PgPool) -> Result<MetricasCrudo, sqlx::Error> {
    let total_reportes: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM reportes")
        .fetch_one(pool)
        .await?;

    let mercurio_acumulado_kg: f64 = sqlx::query_scalar(
        "SELECT COALESCE(SUM(mercurio_estimado_kg), 0)::DOUBLE PRECISION FROM evaluaciones",
    )
    .fetch_one(pool)
    .await?;

    let total_anonimos: i64 = sqlx::query_scalar(
        r#"
        SELECT COUNT(*)
        FROM reportes r
        WHERE NOT EXISTS (
            SELECT 1 FROM contacto_informante c WHERE c.reporte_codigo = r.codigo
        )
        "#,
    )
    .fetch_one(pool)
    .await?;

    let porcentaje_anonimos = if total_reportes > 0 {
        (total_anonimos as f64 / total_reportes as f64) * 100.0
    } else {
        0.0
    };

    let zonas_afectadas: i64 = sqlx::query_scalar(
        r#"
        SELECT COUNT(DISTINCT z.codigo)
        FROM zonas_protegidas z
        JOIN reportes r ON ST_Within(r.ubicacion::geometry, z.geom::geometry)
        "#,
    )
    .fetch_one(pool)
    .await?;

    Ok(MetricasCrudo {
        total_reportes,
        mercurio_acumulado_kg,
        porcentaje_anonimos,
        zonas_afectadas,
    })
}

/// Cantidad de reportes creados por mes, agrupados con
/// `date_trunc('month', ...)`, ordenados cronológicamente.
pub async fn obtener_denuncias_por_mes(pool: &PgPool) -> Result<Vec<DenunciasPorMes>, sqlx::Error> {
    sqlx::query_as::<_, DenunciasPorMes>(
        r#"
        SELECT
            to_char(date_trunc('month', fecha_creacion), 'YYYY-MM') AS mes,
            COUNT(*) AS cantidad
        FROM reportes
        GROUP BY date_trunc('month', fecha_creacion)
        ORDER BY date_trunc('month', fecha_creacion)
        "#,
    )
    .fetch_all(pool)
    .await
}

/// Construye el GeoJSON (`FeatureCollection`) de los puntos de reportes
/// para `GET /api/v1/dashboard/mapa`, usando `ST_AsGeoJSON` de PostGIS
/// para no tener que armar la geometría a mano en Rust.
pub async fn obtener_geojson_mapa(pool: &PgPool) -> Result<Value, sqlx::Error> {
    let filas: Vec<(String, uuid::Uuid, String)> = sqlx::query_as(
        r#"
        SELECT
            ST_AsGeoJSON(ubicacion::geometry) AS geometria,
            codigo,
            estado_codigo
        FROM reportes
        "#,
    )
    .fetch_all(pool)
    .await?;

    let features: Vec<Value> = filas
        .into_iter()
        .map(|(geometria, codigo, estado_codigo)| {
            let geometria: Value = serde_json::from_str(&geometria).unwrap_or(Value::Null);
            serde_json::json!({
                "type": "Feature",
                "geometry": geometria,
                "properties": {
                    "codigo": codigo,
                    "estado": estado_codigo,
                }
            })
        })
        .collect();

    Ok(serde_json::json!({
        "type": "FeatureCollection",
        "features": features,
    }))
}
