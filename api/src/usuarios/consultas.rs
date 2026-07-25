//! Consultas SQL del módulo usuarios. Todo el SQL se escribe a mano como
//! texto y se ejecuta con las funciones `sqlx::query` / `sqlx::query_as`
//! (sin los macros `query!`/`query_as!`, para no requerir conexión real a
//! la base de datos en tiempo de compilación).

use sqlx::PgPool;
use uuid::Uuid;

use super::modelo::Usuario;

/// Inserta un nuevo usuario y devuelve la fila insertada.
pub async fn crear_usuario(
    pool: &PgPool,
    nombre: &str,
    correo: &str,
    contrasena_hash: &str,
    rol_codigo: &str,
) -> Result<Usuario, sqlx::Error> {
    sqlx::query_as::<_, Usuario>(
        r#"
        INSERT INTO usuarios (nombre, correo, contrasena_hash, rol_codigo)
        VALUES ($1, $2, $3, $4)
        RETURNING codigo, nombre, correo, contrasena_hash, rol_codigo,
                  fecha_creacion, hora_creacion
        "#,
    )
    .bind(nombre)
    .bind(correo)
    .bind(contrasena_hash)
    .bind(rol_codigo)
    .fetch_one(pool)
    .await
}

/// Busca un usuario por su correo. Devuelve `None` si no existe.
pub async fn buscar_por_correo(
    pool: &PgPool,
    correo: &str,
) -> Result<Option<Usuario>, sqlx::Error> {
    sqlx::query_as::<_, Usuario>(
        r#"
        SELECT codigo, nombre, correo, contrasena_hash, rol_codigo,
               fecha_creacion, hora_creacion
        FROM usuarios
        WHERE correo = $1
        "#,
    )
    .bind(correo)
    .fetch_optional(pool)
    .await
}

/// Busca un usuario por su código (UUID). Devuelve `None` si no existe.
pub async fn buscar_por_codigo(
    pool: &PgPool,
    codigo: Uuid,
) -> Result<Option<Usuario>, sqlx::Error> {
    sqlx::query_as::<_, Usuario>(
        r#"
        SELECT codigo, nombre, correo, contrasena_hash, rol_codigo,
               fecha_creacion, hora_creacion
        FROM usuarios
        WHERE codigo = $1
        "#,
    )
    .bind(codigo)
    .fetch_optional(pool)
    .await
}
