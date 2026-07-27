//! Reglas del agente: orquesta la evaluación de un reporte combinando
//! reglas locales determinísticas con (en el futuro) llamadas a
//! herramientas del servidor MCP y/o un LLM.
//!
//! Por ahora el cálculo de mercurio/riesgo es 100% determinístico (sin
//! LLM ni MCP): se basa en tablas fijas de factores según el tamaño de la
//! draga, el tiempo de operación y los indicadores visibles del reporte.
//! La verificación de zona protegida sí usa PostGIS real (`ST_Within`)
//! contra `zonas_protegidas`.

use uuid::Uuid;

use crate::error::ErrorApi;
use crate::evaluaciones::consultas as consultas_evaluaciones;
use crate::reportes::consultas as consultas_reportes;

/// Factor base de mercurio (kg de mercurio usado por día de operación,
/// aproximado) según el tamaño de la draga. Valores de referencia usados
/// en estudios de minería aurífera artesanal con mercurio en la región.
fn factor_por_tamano_draga(tamano_draga_codigo: &str) -> f64 {
    match tamano_draga_codigo {
        "PEQUENA" => 0.5,
        "MEDIANA" => 1.5,
        "GRANDE" => 3.0,
        _ => 1.0,
    }
}

/// Multiplicador según el tiempo que la draga lleva operando, para pasar
/// de "mercurio por día" a una estimación acumulada del reporte.
fn dias_por_tiempo_operacion(tiempo_operacion_codigo: &str) -> f64 {
    match tiempo_operacion_codigo {
        "MENOS_1_DIA" => 1.0,
        "VARIOS_DIAS" => 4.0,
        "MAS_1_SEMANA" => 10.0,
        _ => 1.0,
    }
}

/// Puntaje de riesgo agregado a partir de los indicadores visibles
/// (presencia de personas y de motobombas operando), que sugieren una
/// operación activa y de mayor escala.
fn puntaje_indicadores(personas_visibles: bool, motobombas_visibles: bool) -> f64 {
    let mut puntaje = 0.0;
    if personas_visibles {
        puntaje += 0.5;
    }
    if motobombas_visibles {
        puntaje += 0.5;
    }
    puntaje
}

/// Determina el nivel de riesgo (`BAJO`/`MEDIO`/`ALTO`) a partir del
/// mercurio estimado y si el reporte cae dentro de una zona protegida.
/// Estar en zona protegida escala automáticamente el riesgo, sin importar
/// el mercurio estimado, porque el daño ambiental allí es más grave.
fn nivel_riesgo(mercurio_estimado_kg: f64, en_zona_protegida: bool) -> &'static str {
    if en_zona_protegida {
        return if mercurio_estimado_kg >= 3.0 { "ALTO" } else { "MEDIO" };
    }
    if mercurio_estimado_kg >= 6.0 {
        "ALTO"
    } else if mercurio_estimado_kg >= 2.0 {
        "MEDIO"
    } else {
        "BAJO"
    }
}

/// Evalúa un reporte: calcula el factor y estimado de mercurio, determina
/// el nivel de riesgo, y verifica si cae dentro de una zona protegida
/// (usando PostGIS), asociando la normativa general si corresponde.
/// Persiste el resultado en la tabla `evaluaciones`.
///
/// Se dispara automáticamente después de crear un reporte nuevo (ver
/// `reportes::rutas::crear_reporte`). Si falla, no revierte la creación
/// del reporte: el reporte queda creado sin evaluación y puede
/// reintentarse más adelante (por ejemplo, llamando de nuevo a este
/// mismo endpoint de creación de evaluación, si se expone en el futuro).
pub async fn evaluar_reporte(pool: &sqlx::PgPool, codigo_reporte: Uuid) -> Result<(), ErrorApi> {
    let reporte = consultas_reportes::buscar_por_codigo(pool, codigo_reporte)
        .await?
        .ok_or_else(|| ErrorApi::NoEncontrado("reporte".to_string()))?;

    let factor_mercurio = factor_por_tamano_draga(&reporte.tamano_draga_codigo);
    let dias = dias_por_tiempo_operacion(&reporte.tiempo_operacion_codigo);
    let ajuste_indicadores =
        1.0 + puntaje_indicadores(reporte.personas_visibles, reporte.motobombas_visibles);
    let mercurio_estimado_kg = factor_mercurio * dias * ajuste_indicadores;

    let zona_codigo =
        consultas_evaluaciones::buscar_zona_protegida_del_reporte(pool, codigo_reporte).await?;
    let normativa_codigo = if zona_codigo.is_some() {
        consultas_evaluaciones::buscar_normativa_general(pool).await?
    } else {
        None
    };

    let nivel_riesgo_codigo =
        nivel_riesgo(mercurio_estimado_kg, zona_codigo.is_some()).to_string();

    consultas_evaluaciones::insertar_evaluacion(
        pool,
        consultas_evaluaciones::NuevaEvaluacion {
            reporte_codigo: codigo_reporte,
            factor_mercurio,
            mercurio_estimado_kg,
            zona_codigo,
            normativa_codigo,
            nivel_riesgo_codigo,
        },
    )
    .await?;

    Ok(())
}

/// Invoca una herramienta específica del servidor MCP con los parámetros
/// dados y devuelve su resultado en bruto (JSON).
///
/// TODO: implementar la llamada real al servidor MCP (transporte, auth,
/// manejo de errores) y registrar la invocación en `trazabilidad_mcp`.
/// Todavía no se usa desde ningún endpoint; queda como firma para cuando
/// se integre un LLM/MCP real.
pub async fn invocar_herramienta_mcp(
    _herramienta_codigo: &str,
    _parametros: serde_json::Value,
) -> Result<serde_json::Value, ErrorApi> {
    todo!("integración con el servidor MCP: se implementará después")
}
