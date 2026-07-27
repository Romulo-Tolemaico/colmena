//! Handlers axum del módulo usuarios: creación de usuario, login y refresh
//! de JWT.

use argon2::{
    Argon2,
    password_hash::{PasswordHash, PasswordHasher, PasswordVerifier, SaltString, rand_core::OsRng},
};
use axum::{Extension, Json, Router, extract::State, middleware, routing::{get, post}};
use jsonwebtoken::{DecodingKey, EncodingKey, Header, Validation, decode, encode};
use validator::Validate;

use crate::error::ErrorApi;
use crate::middleware::exigir_jwt;
use crate::respuesta::RespuestaExitosa;
use crate::estado::EstadoApp;

use super::consultas;
use super::modelo::{
    ClaimsJwt, CrearUsuarioPeticion, LoginPeticion, RefrescarTokenPeticion, TokenRespuesta,
    UsuarioPublico,
};

/// Duración de validez de un JWT emitido por la API, en segundos (24 horas).
const DURACION_TOKEN_SEGUNDOS: i64 = 60 * 60 * 24;

/// Router del módulo usuarios: `/usuarios`, `/auth/login`, `/auth/refresh`.
pub fn rutas() -> Router<EstadoApp> {
    let rutas_protegidas = Router::new()
        .route("/usuarios/me", get(obtener_usuario_actual))
        .route_layer(middleware::from_fn(exigir_jwt));

    Router::new()
        .route("/usuarios", post(crear_usuario))
        .route("/auth/login", post(login))
        .route("/auth/refresh", post(refrescar_token))
        .merge(rutas_protegidas)
}

/// `POST /api/v1/usuarios` — crea un nuevo usuario con la contraseña
/// hasheada con argon2.
async fn crear_usuario(
    State(estado): State<EstadoApp>,
    Json(peticion): Json<CrearUsuarioPeticion>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    peticion.validate()?;

    let salt = SaltString::generate(&mut OsRng);
    let contrasena_hash = Argon2::default()
        .hash_password(peticion.contrasena.as_bytes(), &salt)
        .map_err(|error| ErrorApi::ErrorInterno(format!("no se pudo hashear la contraseña: {error}")))?
        .to_string();

    let usuario = consultas::crear_usuario(
        &estado.pool,
        &peticion.nombre,
        &peticion.correo,
        &contrasena_hash,
        &peticion.rol_codigo,
    )
    .await
    .map_err(|error| {
        if let sqlx::Error::Database(ref error_db) = error {
            if error_db.is_unique_violation() {
                return ErrorApi::Conflicto("ya existe un usuario con ese correo".to_string());
            }
        }
        ErrorApi::from(error)
    })?;

    Ok(RespuestaExitosa::creado(UsuarioPublico::from(usuario)))
}

/// `POST /api/v1/auth/login` — valida las credenciales y devuelve un JWT.
async fn login(
    State(estado): State<EstadoApp>,
    Json(peticion): Json<LoginPeticion>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    peticion.validate()?;

    let usuario = consultas::buscar_por_correo(&estado.pool, &peticion.correo)
        .await?
        .ok_or(ErrorApi::CredencialesInvalidas)?;

    let hash_almacenado = PasswordHash::new(&usuario.contrasena_hash)
        .map_err(|error| ErrorApi::ErrorInterno(format!("hash de contraseña inválido: {error}")))?;

    Argon2::default()
        .verify_password(peticion.contrasena.as_bytes(), &hash_almacenado)
        .map_err(|_| ErrorApi::CredencialesInvalidas)?;

    let token = generar_token(
        &usuario.codigo.to_string(),
        &usuario.nombre,
        &usuario.rol_codigo,
        &estado.configuracion.jwt_secret,
    )?;

    Ok(RespuestaExitosa::ok(TokenRespuesta {
        token,
        tipo: "Bearer".to_string(),
    }))
}

/// `POST /api/v1/auth/refresh` — valida un JWT existente (aunque haya
/// expirado recientemente) y emite uno nuevo con vigencia renovada.
async fn refrescar_token(
    State(estado): State<EstadoApp>,
    Json(peticion): Json<RefrescarTokenPeticion>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    peticion.validate()?;

    // Se permite un margen (leeway) para aceptar tokens recién expirados,
    // de forma que el cliente pueda renovarlos sin tener que loguearse de
    // nuevo justo al vencer.
    let mut validacion = Validation::default();
    validacion.leeway = 60;

    let datos = decode::<ClaimsJwt>(
        &peticion.token,
        &DecodingKey::from_secret(estado.configuracion.jwt_secret.as_bytes()),
        &validacion,
    )
    .map_err(|_| ErrorApi::NoAutenticado)?;

    // Se confirma que el usuario siga existiendo antes de renovar el token.
    let codigo_usuario = uuid::Uuid::parse_str(&datos.claims.sub)
        .map_err(|_| ErrorApi::NoAutenticado)?;
    let usuario = consultas::buscar_por_codigo(&estado.pool, codigo_usuario)
        .await?
        .ok_or(ErrorApi::NoAutenticado)?;

    let token = generar_token(
        &usuario.codigo.to_string(),
        &usuario.nombre,
        &usuario.rol_codigo,
        &estado.configuracion.jwt_secret,
    )?;

    Ok(RespuestaExitosa::ok(TokenRespuesta {
        token,
        tipo: "Bearer".to_string(),
    }))
}

/// `GET /api/v1/usuarios/me` — devuelve los datos del usuario autenticado
/// (nombre, correo, rol), a partir del código en el JWT. Requiere JWT válido.
async fn obtener_usuario_actual(
    State(estado): State<EstadoApp>,
    Extension(claims): Extension<ClaimsJwt>,
) -> Result<impl axum::response::IntoResponse, ErrorApi> {
    let codigo_usuario = uuid::Uuid::parse_str(&claims.sub)
        .map_err(|_| ErrorApi::ErrorInterno("el token contiene un código de usuario inválido".to_string()))?;

    let usuario = consultas::buscar_por_codigo(&estado.pool, codigo_usuario)
        .await?
        .ok_or(ErrorApi::NoAutenticado)?;

    Ok(RespuestaExitosa::ok(UsuarioPublico::from(usuario)))
}

/// Genera un JWT firmado con HS256 para el usuario indicado.
fn generar_token(codigo_usuario: &str, nombre: &str, rol: &str, jwt_secret: &str) -> Result<String, ErrorApi> {
    let expiracion = (chrono::Utc::now().timestamp() + DURACION_TOKEN_SEGUNDOS) as usize;
    let claims = ClaimsJwt {
        sub: codigo_usuario.to_string(),
        nombre: nombre.to_string(),
        rol: rol.to_string(),
        exp: expiracion,
    };

    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(jwt_secret.as_bytes()),
    )
    .map_err(|error| ErrorApi::ErrorInterno(format!("no se pudo generar el token: {error}")))
}
