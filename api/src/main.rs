//! Punto de entrada de la API de Colmena. Arranca el servidor, compone el
//! router de todos los módulos y corre las migraciones al inicio.

mod agent;
mod config;
mod dashboard;
mod db;
mod error;
mod estado;
mod evaluaciones;
mod middleware;
mod reportes;
mod respuesta;
mod usuarios;

use axum::{Extension, Router, http::Method, routing::get};
use tower_http::cors::CorsLayer;
use tower_http::trace::TraceLayer;

use config::Configuracion;
use estado::EstadoApp;

#[tokio::main]
async fn main() {
    // El archivo .env se lee una sola vez, aquí, al inicio de main.rs.
    dotenvy::dotenv().ok();

    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    let configuracion = Configuracion::desde_entorno();

    let pool = db::crear_pool(&configuracion.database_url)
        .await
        .expect("no se pudo conectar a la base de datos");

    // Las migraciones (migrations/0001_init.sql, etc.) se ejecutan
    // automáticamente al arrancar el servidor.
    sqlx::migrate!()
        .run(&pool)
        .await
        .expect("no se pudieron ejecutar las migraciones");

    let puerto = configuracion.puerto;
    let cors = construir_cors(&configuracion.cors_origenes);

    let estado = EstadoApp {
        pool,
        configuracion,
    };

    // El módulo usuarios expone rutas bajo dos prefijos distintos
    // (`/usuarios` y `/auth/...`), por lo que su router ya incluye esos
    // segmentos completos y se anida directamente bajo `/api/v1`.
    let app = Router::new()
        .route("/health", get(salud))
        .nest("/api/v1", usuarios::rutas::rutas())
        .nest("/api/v1/reportes", reportes::rutas::rutas())
        .nest("/api/v1/reportes", evaluaciones::rutas::rutas())
        .nest("/api/v1/dashboard", dashboard::rutas::rutas())
        .with_state(estado.clone())
        // El estado se expone también como `Extension` para que el
        // middleware de autenticación (que se aplica selectivamente con
        // `middleware::from_fn`, sin estado) pueda leerlo.
        .layer(Extension(estado))
        .layer(cors)
        .layer(TraceLayer::new_for_http());

    let direccion = format!("0.0.0.0:{puerto}");
    let listener = tokio::net::TcpListener::bind(&direccion)
        .await
        .expect("no se pudo enlazar el puerto del servidor");

    tracing::info!(%direccion, "servidor escuchando");

    axum::serve(listener, app)
        .await
        .expect("el servidor terminó con un error");
}

/// `GET /health` — health check simple, sin autenticación.
async fn salud() -> &'static str {
    "ok"
}

/// Construye la capa de CORS a partir de la lista de orígenes permitidos
/// configurada por variable de entorno (`CORS_ORIGENES`).
fn construir_cors(origenes: &[String]) -> CorsLayer {
    let origenes_validos: Vec<_> = origenes
        .iter()
        .filter_map(|origen| origen.parse().ok())
        .collect();

    CorsLayer::new()
        .allow_origin(origenes_validos)
        .allow_methods([Method::GET, Method::POST, Method::PATCH, Method::DELETE])
        .allow_headers(tower_http::cors::Any)
}
