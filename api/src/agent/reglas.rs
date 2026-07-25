//! Reglas del agente: orquesta la evaluación de un reporte combinando
//! reglas locales con llamadas a herramientas del servidor MCP y/o un LLM.
//!
//! NOTA: este módulo todavía no tiene lógica real de conexión con el MCP
//! ni con el LLM. Las firmas quedan definidas para que otros módulos
//! (por ejemplo, un futuro handler que dispare la evaluación de un
//! reporte recién creado) puedan integrarse más adelante sin tener que
//! rediseñar la interfaz.

use uuid::Uuid;

use crate::error::ErrorApi;

/// Evalúa un reporte: calcula el factor y estimado de mercurio, determina
/// el nivel de riesgo, y consulta zona protegida y normativa aplicable.
///
/// TODO: implementar la orquestación real. Debe:
/// 1. Reunir los datos del reporte (tamaño de draga, tiempo de operación,
///    ubicación, etc.).
/// 2. Invocar las herramientas correspondientes del servidor MCP
///    (`UBICACION`, `NORMATIVA`, `ESTIMACION_ECONOMICA`, `REPORTE_PDF`).
/// 3. Combinar los resultados con las reglas locales de negocio para
///    producir el nivel de riesgo final.
/// 4. Persistir la evaluación resultante (tabla `evaluaciones`) y
///    registrar la traza en `trazabilidad_mcp`.
pub async fn evaluar_reporte(_codigo_reporte: Uuid) -> Result<(), ErrorApi> {
    todo!("orquestación de reglas + llamadas al MCP/LLM: se implementará después")
}

/// Invoca una herramienta específica del servidor MCP con los parámetros
/// dados y devuelve su resultado en bruto (JSON).
///
/// TODO: implementar la llamada real al servidor MCP (transporte, auth,
/// manejo de errores) y registrar la invocación en `trazabilidad_mcp`.
pub async fn invocar_herramienta_mcp(
    _herramienta_codigo: &str,
    _parametros: serde_json::Value,
) -> Result<serde_json::Value, ErrorApi> {
    todo!("integración con el servidor MCP: se implementará después")
}
