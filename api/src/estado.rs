//! Estado compartido de la aplicación. Se construye una sola vez en
//! `main.rs` y se distribuye a todos los módulos mediante
//! `axum::extract::State<EstadoApp>`.

use sqlx::PgPool;

use crate::config::Configuracion;

/// Estado global compartido entre todos los handlers de la API.
#[derive(Clone)]
pub struct EstadoApp {
    /// Pool de conexiones a PostgreSQL.
    pub pool: PgPool,
    /// Configuración cargada desde variables de entorno.
    pub configuracion: Configuracion,
}
