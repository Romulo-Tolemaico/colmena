//! Middleware de autenticación JWT. Se aplica selectivamente con
//! `axum::middleware::from_fn` sobre las rutas que lo requieren (no de
//! forma global), usando `.route_layer(...)` en cada módulo.
//!
//! Nota de diseño: `axum::middleware::from_fn_with_state` exige un valor
//! concreto del estado en el momento de construir el router, pero cada
//! módulo expone `fn rutas() -> Router<EstadoApp>` sin recibir el estado
//! como parámetro. Por eso este middleware lee el `EstadoApp` desde una
//! `Extension`, que `main.rs` inserta una sola vez de forma global con
//! `.layer(Extension(estado))`; así los layers `route_layer` de cada
//! módulo pueden usar la versión sin estado (`from_fn`).

use axum::{
    Extension,
    extract::Request,
    http::header::AUTHORIZATION,
    middleware::Next,
    response::Response,
};
use jsonwebtoken::{DecodingKey, Validation, decode};

use crate::error::ErrorApi;
use crate::estado::EstadoApp;
use crate::usuarios::modelo::ClaimsJwt;

/// Verifica que la petición traiga un header `Authorization: Bearer <jwt>`
/// válido. Si es válido, inserta los `ClaimsJwt` como extensión de la
/// petición para que los handlers los puedan leer con `Extension<ClaimsJwt>`.
pub async fn exigir_jwt(
    Extension(estado): Extension<EstadoApp>,
    mut request: Request,
    next: Next,
) -> Result<Response, ErrorApi> {
    let encabezado = request
        .headers()
        .get(AUTHORIZATION)
        .and_then(|valor| valor.to_str().ok())
        .ok_or(ErrorApi::NoAutenticado)?;

    let token = encabezado
        .strip_prefix("Bearer ")
        .ok_or(ErrorApi::NoAutenticado)?;

    let datos = decode::<ClaimsJwt>(
        token,
        &DecodingKey::from_secret(estado.configuracion.jwt_secret.as_bytes()),
        &Validation::default(),
    )
    .map_err(|_| ErrorApi::NoAutenticado)?;

    request.extensions_mut().insert(datos.claims);

    Ok(next.run(request).await)
}
