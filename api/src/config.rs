//! Carga centralizada de la configuración de la aplicación a partir de
//! variables de entorno. El archivo `.env` se lee una sola vez en `main.rs`
//! (con `dotenvy::dotenv()`), este módulo solo se encarga de leer y validar
//! las variables ya presentes en el entorno del proceso.

use std::env;

/// Configuración global de la aplicación, construida una sola vez al
/// arrancar el servidor y compartida a través del `EstadoApp`.
#[derive(Debug, Clone)]
pub struct Configuracion {
    /// Cadena de conexión a PostgreSQL.
    pub database_url: String,
    /// Secreto usado para firmar y verificar los JWT.
    pub jwt_secret: String,
    /// Puerto en el que escucha el servidor HTTP.
    pub puerto: u16,
    /// Orígenes permitidos para CORS (app web y app mobile).
    pub cors_origenes: Vec<String>,
    /// Carpeta local donde se guardan archivos subidos (fotos, PDFs).
    /// Vive en el filesystem del contenedor: en Render (free tier) es
    /// efímero y se pierde en cada redeploy/restart. Ver README para más
    /// detalles y alternativas (S3, R2, etc.) si se necesita persistencia.
    pub carpeta_archivos: String,
}

impl Configuracion {
    /// Lee todas las variables de entorno necesarias y construye la
    /// configuración. Falla rápido (panic) si falta alguna variable
    /// obligatoria o si tiene un formato inválido, ya que sin ellas el
    /// servidor no puede operar de forma segura.
    pub fn desde_entorno() -> Self {
        let database_url = env::var("DATABASE_URL")
            .expect("la variable de entorno DATABASE_URL es obligatoria");

        let jwt_secret = env::var("JWT_SECRET")
            .expect("la variable de entorno JWT_SECRET es obligatoria");

        let puerto = env::var("PORT")
            .expect("la variable de entorno PORT es obligatoria")
            .parse::<u16>()
            .expect("PORT debe ser un número de puerto válido (0-65535)");

        let cors_origenes = env::var("CORS_ORIGENES")
            .expect("la variable de entorno CORS_ORIGENES es obligatoria")
            .split(',')
            .map(|origen| origen.trim().to_string())
            .filter(|origen| !origen.is_empty())
            .collect();

        // Opcional: por defecto "./uploads" si no se especifica.
        let carpeta_archivos = env::var("CARPETA_ARCHIVOS").unwrap_or_else(|_| "./uploads".to_string());

        Configuracion {
            database_url,
            jwt_secret,
            puerto,
            cors_origenes,
            carpeta_archivos,
        }
    }
}
