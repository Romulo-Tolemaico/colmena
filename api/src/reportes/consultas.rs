//! Consultas SQL del módulo reportes. Todo el SQL se escribe a mano como
//! texto y se ejecuta con las funciones `sqlx::query` / `sqlx::query_as`
//! (sin macros `query!`/`query_as!`).
//!
//! La columna `ubicacion` es `GEOGRAPHY(POINT, 4326)` (PostGIS). Al insertar
//! se construye con `ST_SetSRID(ST_MakePoint(lon, lat), 4326)::geography` y
//! al leer se descompone con `ST_X`/`ST_Y` sobre el `::geometry` para
//! obtener longitud y latitud como columnas planas.
//!
//! Las columnas `alias_informante`, `celular_informante` y `nota` viven en
//! las tablas débiles `contacto_informante` y `notas_reporte`, por lo que
//! las consultas de lectura las traen con `LEFT JOIN` (son opcionales).

use chrono::{NaiveDate, NaiveTime};
use sqlx::PgPool;
use uuid::Uuid;

use super::modelo::Reporte;

/// Columnas de `reportes` más los datos opcionales de sus tablas débiles
/// (contacto del informante y nota), usadas en las consultas de lectura.
const COLUMNAS_REPORTE_CON_DEBILES: &str = r#"
    r.codigo,
    ST_X(r.ubicacion::geometry) AS longitud,
    ST_Y(r.ubicacion::geometry) AS latitud,
    r.tamano_draga_codigo,
    r.tiempo_operacion_codigo,
    r.personas_visibles,
    r.motobombas_visibles,
    r.estado_codigo,
    r.fecha_creacion,
    r.hora_creacion,
    c.alias AS alias_informante,
    c.celular AS celular_informante,
    n.texto AS nota
"#;

/// `FROM`/`JOIN` comunes para las consultas que usan
/// `COLUMNAS_REPORTE_CON_DEBILES`.
const JOINS_REPORTE_DEBILES: &str = r#"
    FROM reportes r
    LEFT JOIN contacto_informante c ON c.reporte_codigo = r.codigo
    LEFT JOIN notas_reporte n ON n.reporte_codigo = r.codigo
"#;

/// Fila mínima de `reportes`, sin las tablas débiles. Se usa justo después
/// de un `INSERT`/`UPDATE` (vía `RETURNING`), donde todavía no tiene sentido
/// hacer `JOIN` porque esos datos se manejan aparte.
#[derive(sqlx::FromRow)]
struct FilaReporteBase {
    codigo: Uuid,
    longitud: f64,
    latitud: f64,
    tamano_draga_codigo: String,
    tiempo_operacion_codigo: String,
    personas_visibles: bool,
    motobombas_visibles: bool,
    estado_codigo: String,
    fecha_creacion: NaiveDate,
    hora_creacion: NaiveTime,
}

const COLUMNAS_REPORTE_BASE: &str = r#"
    codigo,
    ST_X(ubicacion::geometry) AS longitud,
    ST_Y(ubicacion::geometry) AS latitud,
    tamano_draga_codigo,
    tiempo_operacion_codigo,
    personas_visibles,
    motobombas_visibles,
    estado_codigo,
    fecha_creacion,
    hora_creacion
"#;

/// Datos necesarios para insertar un reporte nuevo.
pub struct NuevoReporte<'a> {
    pub longitud: f64,
    pub latitud: f64,
    pub tamano_draga_codigo: &'a str,
    pub tiempo_operacion_codigo: &'a str,
    pub personas_visibles: bool,
    pub motobombas_visibles: bool,
    pub alias_informante: Option<&'a str>,
    pub celular_informante: Option<&'a str>,
    pub nota: Option<&'a str>,
}

/// Inserta un reporte nuevo junto con sus entidades débiles opcionales
/// (contacto del informante y nota), todo dentro de una misma transacción.
pub async fn crear_reporte(pool: &PgPool, datos: NuevoReporte<'_>) -> Result<Reporte, sqlx::Error> {
    let mut tx = pool.begin().await?;

    let fila = sqlx::query_as::<_, FilaReporteBase>(&format!(
        r#"
        INSERT INTO reportes (
            ubicacion, tamano_draga_codigo, tiempo_operacion_codigo,
            personas_visibles, motobombas_visibles
        )
        VALUES (
            ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography, $3, $4, $5, $6
        )
        RETURNING {COLUMNAS_REPORTE_BASE}
        "#
    ))
    .bind(datos.longitud)
    .bind(datos.latitud)
    .bind(datos.tamano_draga_codigo)
    .bind(datos.tiempo_operacion_codigo)
    .bind(datos.personas_visibles)
    .bind(datos.motobombas_visibles)
    .fetch_one(&mut *tx)
    .await?;

    if datos.alias_informante.is_some() || datos.celular_informante.is_some() {
        sqlx::query(
            r#"
            INSERT INTO contacto_informante (reporte_codigo, alias, celular)
            VALUES ($1, $2, $3)
            "#,
        )
        .bind(fila.codigo)
        .bind(datos.alias_informante)
        .bind(datos.celular_informante)
        .execute(&mut *tx)
        .await?;
    }

    if let Some(texto) = datos.nota {
        sqlx::query(
            r#"
            INSERT INTO notas_reporte (reporte_codigo, texto)
            VALUES ($1, $2)
            "#,
        )
        .bind(fila.codigo)
        .bind(texto)
        .execute(&mut *tx)
        .await?;
    }

    tx.commit().await?;

    // Los datos de las tablas débiles ya se conocen (vienen del payload de
    // entrada), así que se combinan directamente sin volver a consultar.
    Ok(Reporte {
        codigo: fila.codigo,
        longitud: fila.longitud,
        latitud: fila.latitud,
        tamano_draga_codigo: fila.tamano_draga_codigo,
        tiempo_operacion_codigo: fila.tiempo_operacion_codigo,
        personas_visibles: fila.personas_visibles,
        motobombas_visibles: fila.motobombas_visibles,
        estado_codigo: fila.estado_codigo,
        fecha_creacion: fila.fecha_creacion,
        hora_creacion: fila.hora_creacion,
        alias_informante: datos.alias_informante.map(str::to_string),
        celular_informante: datos.celular_informante.map(str::to_string),
        nota: datos.nota.map(str::to_string),
    })
}

/// Busca un reporte por su código. Devuelve `None` si no existe.
pub async fn buscar_por_codigo(pool: &PgPool, codigo: Uuid) -> Result<Option<Reporte>, sqlx::Error> {
    sqlx::query_as::<_, Reporte>(&format!(
        r#"
        SELECT {COLUMNAS_REPORTE_CON_DEBILES}
        {JOINS_REPORTE_DEBILES}
        WHERE r.codigo = $1
        "#
    ))
    .bind(codigo)
    .fetch_optional(pool)
    .await
}

/// Lista reportes con filtros opcionales (estado, zona, fecha) y
/// paginación. El filtro de zona verifica si el punto del reporte cae
/// dentro del polígono de la zona protegida indicada, usando `ST_Within`.
pub async fn listar_reportes(
    pool: &PgPool,
    estado: Option<&str>,
    zona: Option<Uuid>,
    fecha: Option<NaiveDate>,
    pagina: i64,
    por_pagina: i64,
) -> Result<(Vec<Reporte>, i64), sqlx::Error> {
    let offset = (pagina - 1) * por_pagina;

    let reportes = sqlx::query_as::<_, Reporte>(&format!(
        r#"
        SELECT {COLUMNAS_REPORTE_CON_DEBILES}
        {JOINS_REPORTE_DEBILES}
        WHERE ($1::TEXT IS NULL OR r.estado_codigo = $1)
          AND ($2::UUID IS NULL OR EXISTS (
                SELECT 1 FROM zonas_protegidas z
                WHERE z.codigo = $2 AND ST_Within(r.ubicacion::geometry, z.geom::geometry)
              ))
          AND ($3::DATE IS NULL OR r.fecha_creacion = $3)
        ORDER BY r.fecha_creacion DESC, r.hora_creacion DESC
        LIMIT $4 OFFSET $5
        "#
    ))
    .bind(estado)
    .bind(zona)
    .bind(fecha)
    .bind(por_pagina)
    .bind(offset)
    .fetch_all(pool)
    .await?;

    let total: i64 = sqlx::query_scalar(
        r#"
        SELECT COUNT(*)
        FROM reportes r
        WHERE ($1::TEXT IS NULL OR r.estado_codigo = $1)
          AND ($2::UUID IS NULL OR EXISTS (
                SELECT 1 FROM zonas_protegidas z
                WHERE z.codigo = $2 AND ST_Within(r.ubicacion::geometry, z.geom::geometry)
              ))
          AND ($3::DATE IS NULL OR r.fecha_creacion = $3)
        "#,
    )
    .bind(estado)
    .bind(zona)
    .bind(fecha)
    .fetch_one(pool)
    .await?;

    Ok((reportes, total))
}

/// Cambia el estado de un reporte y registra el cambio en `logs_auditoria`,
/// todo dentro de una misma transacción.
pub async fn cambiar_estado(
    pool: &PgPool,
    codigo_reporte: Uuid,
    nuevo_estado: &str,
    codigo_usuario: Uuid,
) -> Result<Option<Reporte>, sqlx::Error> {
    let mut tx = pool.begin().await?;

    let actualizado = sqlx::query_scalar::<_, Uuid>(
        r#"
        UPDATE reportes
        SET estado_codigo = $1
        WHERE codigo = $2
        RETURNING codigo
        "#,
    )
    .bind(nuevo_estado)
    .bind(codigo_reporte)
    .fetch_optional(&mut *tx)
    .await?;

    let Some(codigo) = actualizado else {
        tx.rollback().await?;
        return Ok(None);
    };

    sqlx::query(
        r#"
        INSERT INTO logs_auditoria (
            usuario_codigo, tipo_accion_codigo, entidad_codigo,
            entidad_afectada_codigo, detalle
        )
        VALUES ($1, 'CAMBIO_ESTADO', 'REPORTE', $2, $3)
        "#,
    )
    .bind(codigo_usuario)
    .bind(codigo_reporte)
    .bind(serde_json::json!({ "estado_nuevo": nuevo_estado }))
    .execute(&mut *tx)
    .await?;

    // Se reconsulta con los joins de las tablas débiles para devolver el
    // reporte completo (alias/celular/nota), dentro de la misma transacción.
    let reporte = sqlx::query_as::<_, Reporte>(&format!(
        r#"
        SELECT {COLUMNAS_REPORTE_CON_DEBILES}
        {JOINS_REPORTE_DEBILES}
        WHERE r.codigo = $1
        "#
    ))
    .bind(codigo)
    .fetch_one(&mut *tx)
    .await?;

    tx.commit().await?;

    Ok(Some(reporte))
}
