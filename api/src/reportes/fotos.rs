//! Subida y consulta de fotos de un reporte (evidencia fotográfica de la
//! Abeja). Las fotos se guardan en el filesystem local del servidor, en la
//! carpeta configurada por `CARPETA_ARCHIVOS`, y se registra su ruta en la
//! tabla débil `fotos`.
//!
//! ADVERTENCIA: en Render (free tier, que es donde corre esta API) el
//! filesystem del contenedor es efímero — cualquier archivo escrito se
//! pierde en cada redeploy o restart del servicio. Si se necesita
//! persistencia real de las fotos, hay que migrar a un object storage
//! externo (S3, Cloudflare R2, Backblaze B2, etc.). Se implementó en disco
//! porque es lo que se pidió explícitamente para esta etapa; el diseño
//! (rutas relativas guardadas en la tabla `fotos`, servidas por HTTP) no
//! cambia si más adelante se migra a un bucket.

use axum::extract::Multipart;
use sqlx::PgPool;
use uuid::Uuid;

use crate::error::ErrorApi;

/// Extensión aceptada según el tipo de contenido del archivo subido.
/// Solo se aceptan imágenes comunes, para no permitir subir cualquier tipo
/// de archivo a través de este endpoint.
fn extension_para_content_type(content_type: &str) -> Option<&'static str> {
    match content_type {
        "image/jpeg" | "image/jpg" => Some("jpg"),
        "image/png" => Some("png"),
        "image/webp" => Some("webp"),
        "image/heic" | "image/heif" => Some("heic"),
        _ => None,
    }
}

/// Procesa un `multipart/form-data` con uno o más campos de archivo,
/// guarda cada foto en disco y registra su ruta en la tabla `fotos`.
/// Devuelve las rutas relativas (relativas a `carpeta_archivos`) de las
/// fotos guardadas, en el orden en que se recibieron.
pub async fn guardar_fotos(
    pool: &PgPool,
    carpeta_archivos: &str,
    codigo_reporte: Uuid,
    mut multipart: Multipart,
) -> Result<Vec<String>, ErrorApi> {
    // Se verifica primero que el reporte exista, para no crear archivos
    // huérfanos en disco si el código no corresponde a ningún reporte.
    let existe: bool = sqlx::query_scalar("SELECT EXISTS(SELECT 1 FROM reportes WHERE codigo = $1)")
        .bind(codigo_reporte)
        .fetch_one(pool)
        .await?;
    if !existe {
        return Err(ErrorApi::NoEncontrado("reporte".to_string()));
    }

    // Siguiente número de secuencia disponible para este reporte (empieza
    // en 1 si todavía no tiene fotos), para no chocar con fotos ya subidas
    // en una petición anterior.
    let secuencia_inicial: i32 = sqlx::query_scalar(
        "SELECT COALESCE(MAX(secuencia), 0) + 1 FROM fotos WHERE reporte_codigo = $1",
    )
    .bind(codigo_reporte)
    .fetch_one(pool)
    .await?;

    let carpeta_reporte = std::path::Path::new(carpeta_archivos)
        .join("fotos")
        .join(codigo_reporte.to_string());
    tokio::fs::create_dir_all(&carpeta_reporte)
        .await
        .map_err(|error| ErrorApi::ErrorInterno(format!("no se pudo crear la carpeta de fotos: {error}")))?;

    let mut rutas_guardadas = Vec::new();
    let mut secuencia = secuencia_inicial;

    while let Some(campo) = multipart
        .next_field()
        .await
        .map_err(|error| ErrorApi::SolicitudInvalida(format!("multipart inválido: {error}")))?
    {
        // Solo se procesan campos que traigan un archivo (tengan filename);
        // otros campos de texto en el mismo multipart se ignoran.
        if campo.file_name().is_none() {
            continue;
        }

        let content_type = campo.content_type().unwrap_or("").to_string();
        let extension = extension_para_content_type(&content_type).ok_or_else(|| {
            ErrorApi::SolicitudInvalida(format!(
                "tipo de archivo no soportado: {content_type} (se aceptan jpg, png, webp, heic)"
            ))
        })?;

        let datos = campo
            .bytes()
            .await
            .map_err(|error| ErrorApi::SolicitudInvalida(format!("no se pudo leer el archivo: {error}")))?;

        let nombre_archivo = format!("{secuencia}.{extension}");
        let ruta_absoluta = carpeta_reporte.join(&nombre_archivo);

        tokio::fs::write(&ruta_absoluta, &datos)
            .await
            .map_err(|error| ErrorApi::ErrorInterno(format!("no se pudo guardar la foto en disco: {error}")))?;

        // Ruta relativa a `carpeta_archivos`, la misma que se sirve por
        // HTTP en `/archivos/...` (ver `rutas_estaticas` en `main.rs`).
        let ruta_relativa = format!("fotos/{codigo_reporte}/{nombre_archivo}");

        sqlx::query(
            r#"
            INSERT INTO fotos (reporte_codigo, secuencia, ruta_archivo)
            VALUES ($1, $2, $3)
            "#,
        )
        .bind(codigo_reporte)
        .bind(secuencia)
        .bind(&ruta_relativa)
        .execute(pool)
        .await?;

        rutas_guardadas.push(ruta_relativa);
        secuencia += 1;
    }

    if rutas_guardadas.is_empty() {
        return Err(ErrorApi::SolicitudInvalida(
            "no se recibió ningún archivo en la solicitud".to_string(),
        ));
    }

    Ok(rutas_guardadas)
}

/// Lista las rutas relativas de las fotos de un reporte, en orden de
/// secuencia. Devuelve una lista vacía si el reporte no tiene fotos.
pub async fn listar_fotos(pool: &PgPool, codigo_reporte: Uuid) -> Result<Vec<String>, sqlx::Error> {
    sqlx::query_scalar(
        r#"
        SELECT ruta_archivo
        FROM fotos
        WHERE reporte_codigo = $1
        ORDER BY secuencia
        "#,
    )
    .bind(codigo_reporte)
    .fetch_all(pool)
    .await
}
