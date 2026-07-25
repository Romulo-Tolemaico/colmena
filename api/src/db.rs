//! Creación del pool de conexiones a PostgreSQL usado por toda la aplicación.
//! El pool se crea una sola vez en `main.rs` y se comparte entre módulos
//! mediante `axum::extract::State`.

use sqlx::postgres::{PgPool, PgPoolOptions};

/// Crea el pool de conexiones de sqlx hacia PostgreSQL.
///
/// No ejecuta migraciones: eso lo hace `main.rs` explícitamente con
/// `sqlx::migrate!()` justo después de crear el pool.
pub async fn crear_pool(database_url: &str) -> Result<PgPool, sqlx::Error> {
    PgPoolOptions::new()
        .max_connections(10)
        .connect(database_url)
        .await
}
