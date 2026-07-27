//! Generación de un PDF simple con los datos de un reporte y su
//! evaluación. El PDF se guarda en disco (misma carpeta de archivos que
//! las fotos, ver advertencia sobre filesystem efímero de Render en
//! `reportes::fotos`) y su ruta se registra en la tabla `documento_pdf`.

use printpdf::{BuiltinFont, Mm, PdfDocument};
use sqlx::PgPool;
use uuid::Uuid;

use crate::error::ErrorApi;
use crate::evaluaciones::consultas as consultas_evaluaciones;
use crate::evaluaciones::modelo::Evaluacion;

use super::consultas as consultas_reportes;
use super::modelo::Reporte;

/// Genera el PDF de un reporte (con su evaluación, si ya existe), lo
/// guarda en disco y registra la ruta en `documento_pdf`. Devuelve la
/// ruta relativa del archivo generado (relativa a `carpeta_archivos`,
/// servida por HTTP en `/archivos/...`).
pub async fn generar_pdf_reporte(
    pool: &PgPool,
    carpeta_archivos: &str,
    codigo_reporte: Uuid,
) -> Result<String, ErrorApi> {
    let reporte = consultas_reportes::buscar_por_codigo(pool, codigo_reporte)
        .await?
        .ok_or_else(|| ErrorApi::NoEncontrado("reporte".to_string()))?;
    let evaluacion = consultas_evaluaciones::buscar_por_reporte(pool, codigo_reporte).await?;

    let bytes_pdf = construir_pdf(&reporte, evaluacion.as_ref());

    let carpeta = std::path::Path::new(carpeta_archivos).join("pdfs");
    tokio::fs::create_dir_all(&carpeta)
        .await
        .map_err(|error| ErrorApi::ErrorInterno(format!("no se pudo crear la carpeta de PDFs: {error}")))?;

    let nombre_archivo = format!("{codigo_reporte}.pdf");
    let ruta_absoluta = carpeta.join(&nombre_archivo);
    tokio::fs::write(&ruta_absoluta, &bytes_pdf)
        .await
        .map_err(|error| ErrorApi::ErrorInterno(format!("no se pudo guardar el PDF en disco: {error}")))?;

    let ruta_relativa = format!("pdfs/{nombre_archivo}");

    // `documento_pdf.reporte_codigo` referencia `evaluaciones`, por lo que
    // solo se puede registrar si el reporte ya fue evaluado.
    if evaluacion.is_some() {
        sqlx::query(
            r#"
            INSERT INTO documento_pdf (reporte_codigo, ruta_archivo)
            VALUES ($1, $2)
            ON CONFLICT (reporte_codigo) DO UPDATE SET ruta_archivo = EXCLUDED.ruta_archivo
            "#,
        )
        .bind(codigo_reporte)
        .bind(&ruta_relativa)
        .execute(pool)
        .await?;
    }

    Ok(ruta_relativa)
}

/// Construye el contenido del PDF (una sola página A4) con los datos
/// básicos del reporte y su evaluación, usando fuentes estándar (sin
/// necesidad de embeber archivos de fuente externos).
fn construir_pdf(reporte: &Reporte, evaluacion: Option<&Evaluacion>) -> Vec<u8> {
    let (doc, page1, layer1) = PdfDocument::new("Reporte Colmena", Mm(210.0), Mm(297.0), "Capa 1");
    let capa = doc.get_page(page1).get_layer(layer1);

    let fuente_titulo = doc
        .add_builtin_font(BuiltinFont::HelveticaBold)
        .expect("fuente estándar Helvetica-Bold siempre disponible");
    let fuente_texto = doc
        .add_builtin_font(BuiltinFont::Helvetica)
        .expect("fuente estándar Helvetica siempre disponible");

    let margen_izquierdo = Mm(20.0);
    let mut y = Mm(275.0);
    let alto_linea = Mm(8.0);

    let escribir_titulo = |texto: &str, y: &mut Mm| {
        capa.use_text(texto, 16.0, margen_izquierdo, *y, &fuente_titulo);
        *y = *y - alto_linea;
    };
    let escribir_linea = |texto: &str, y: &mut Mm| {
        capa.use_text(texto, 11.0, margen_izquierdo, *y, &fuente_texto);
        *y = *y - alto_linea;
    };

    escribir_titulo("Reporte Colmena — Evidencia de minería ilegal", &mut y);
    y = y - Mm(2.0);

    escribir_linea(&format!("Código de reporte: {}", reporte.codigo), &mut y);
    escribir_linea(
        &format!("Fecha: {} {}", reporte.fecha_creacion, reporte.hora_creacion),
        &mut y,
    );
    escribir_linea(
        &format!("Ubicación: lat {:.6}, lon {:.6}", reporte.latitud, reporte.longitud),
        &mut y,
    );
    escribir_linea(&format!("Estado: {}", reporte.estado_codigo), &mut y);
    escribir_linea(&format!("Tamaño de draga: {}", reporte.tamano_draga_codigo), &mut y);
    escribir_linea(
        &format!("Tiempo de operación: {}", reporte.tiempo_operacion_codigo),
        &mut y,
    );
    escribir_linea(
        &format!(
            "Personas visibles: {} | Motobombas visibles: {}",
            si_no(reporte.personas_visibles),
            si_no(reporte.motobombas_visibles)
        ),
        &mut y,
    );

    if let Some(nota) = &reporte.nota {
        escribir_linea(&format!("Nota: {nota}"), &mut y);
    }
    if let Some(alias) = &reporte.alias_informante {
        escribir_linea(&format!("Alias del informante: {alias}"), &mut y);
    }

    y = y - Mm(4.0);
    escribir_titulo("Evaluación del agente", &mut y);
    match evaluacion {
        Some(evaluacion) => {
            escribir_linea(&format!("Nivel de riesgo: {}", evaluacion.nivel_riesgo_codigo), &mut y);
            escribir_linea(
                &format!("Mercurio estimado: {:.2} kg", evaluacion.mercurio_estimado_kg),
                &mut y,
            );
            escribir_linea(&format!("Factor de mercurio: {:.2}", evaluacion.factor_mercurio), &mut y);
            match evaluacion.zona_codigo {
                Some(zona) => escribir_linea(&format!("Zona protegida afectada: {zona}"), &mut y),
                None => escribir_linea("Zona protegida afectada: ninguna", &mut y),
            }
        }
        None => {
            escribir_linea("Este reporte todavía no cuenta con evaluación.", &mut y);
        }
    }

    doc.save_to_bytes().unwrap_or_default()
}

fn si_no(valor: bool) -> &'static str {
    if valor { "sí" } else { "no" }
}
