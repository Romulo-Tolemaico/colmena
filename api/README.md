# Colmena API

API en Rust para el proyecto Colmena: gestión de usuarios (la Colmena) y
captura/evaluación de reportes de minería ilegal (la Abeja).

## Stack técnico

- **Rust** + **Axum** (100% asíncrono sobre Tokio)
- **PostgreSQL + PostGIS** vía **sqlx** — sin ORM, todo el SQL se escribe a
  mano y se ejecuta con `sqlx::query()` / `sqlx::query_as()` (sin macros
  `query!`/`query_as!`, para no requerir conexión real a la base de datos
  en tiempo de compilación)
- **JWT** (`jsonwebtoken`) para autenticación
- **argon2** para el hash de contraseñas
- **validator** para validar los payloads de entrada
- **tracing** + **tower-http** para logging de requests y CORS

## Requisitos previos

- Rust estable (edición 2024)
- PostgreSQL con la extensión **PostGIS** disponible
- La extensión `pgcrypto` (se habilita automáticamente en la migración)

## Configuración

1. Copiá `.env.example` a `.env` y completá los valores:

   ```bash
   cp .env.example .env
   ```

   | Variable         | Descripción                                                        |
   | ---------------- | ------------------------------------------------------------------- |
   | `DATABASE_URL`    | Cadena de conexión a PostgreSQL, ej: `postgres://usuario:clave@localhost:5432/colmena` |
   | `JWT_SECRET`      | Secreto usado para firmar/verificar los JWT (usar un valor largo y aleatorio) |
   | `PORT`            | Puerto en el que escucha el servidor HTTP, ej: `3000`               |
   | `CORS_ORIGENES`   | Orígenes permitidos para CORS, separados por coma (app web y mobile) |

2. El archivo `.env` se lee una sola vez al inicio de `main.rs` con
   `dotenvy`. **No se versiona** (está en `.gitignore`).

## Ejecutar el servidor

```bash
cargo run
```

Al arrancar:

1. Se carga la configuración desde el entorno.
2. Se crea el pool de conexiones (`sqlx::PgPool`).
3. Se ejecutan automáticamente las migraciones pendientes en
   `migrations/` (con `sqlx::migrate!()`).
4. Se levanta el servidor HTTP en `0.0.0.0:$PORT`.

Para verificar que compila sin levantar el servidor:

```bash
cargo check
```

## Estructura del proyecto

```
api/
├── Cargo.toml
├── .env.example
├── migrations/
│   └── 0001_init.sql        # esquema de base de datos (PostgreSQL + PostGIS)
└── src/
    ├── main.rs               # arranca el servidor, compone el router, corre migraciones
    ├── config.rs             # lee variables de entorno de forma centralizada
    ├── db.rs                 # crea el sqlx::PgPool
    ├── estado.rs             # estado compartido (pool + configuración) vía axum::extract::State
    ├── error.rs              # tipo de error común, implementa IntoResponse
    ├── respuesta.rs          # struct genérico de respuesta JSON { data }
    ├── middleware.rs         # middleware de autenticación JWT (aplicado selectivamente)
    │
    ├── usuarios/             # login y gestión de usuarios de la Colmena
    ├── reportes/             # captura de reportes de la Abeja (app mobile)
    ├── evaluaciones/         # resultado del análisis del agente sobre un reporte
    ├── dashboard/            # métricas y mapa (GeoJSON) para la Colmena
    └── agent/                # orquestador de reglas + futuras llamadas al MCP/LLM
```

## Rutas disponibles

Las rutas protegidas requieren el header `Authorization: Bearer <token>`.
Todo lo que reciben y devuelven va envuelto en el formato de respuesta
estándar (ver [Formato de respuestas](#formato-de-respuestas)); abajo se
muestra solo el contenido de `data` o del body de entrada.

### Usuarios (`/api/v1`)

#### `POST /usuarios` — crea un usuario · sin auth

Request:

```json
{
  "nombre": "Ana Pérez",
  "correo": "ana@colmena.test",
  "contrasena": "clave12345",
  "rol_codigo": "ANALISTA"
}
```

- `contrasena`: mínimo 8 caracteres (se hashea con argon2, nunca se devuelve).
- `rol_codigo`: código existente en la tabla `roles` (`ANALISTA`, `ADMIN`).

Response `201`:

```json
{
  "data": {
    "codigo": "9d65962d-141c-473a-9bcb-95b73f89e79b",
    "nombre": "Ana Pérez",
    "correo": "ana@colmena.test",
    "rol_codigo": "ANALISTA"
  }
}
```

Errores posibles: `VALIDACION_INVALIDA` (400), `CONFLICTO` (409, correo ya registrado).

#### `POST /auth/login` — inicia sesión · sin auth

Request:

```json
{ "correo": "ana@colmena.test", "contrasena": "clave12345" }
```

Response `200`:

```json
{ "data": { "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...", "tipo": "Bearer" } }
```

El JWT vence a las 24 horas (claims: `sub` = código de usuario, `rol`, `exp`).

Errores posibles: `VALIDACION_INVALIDA` (400), `CREDENCIALES_INVALIDAS` (401).

#### `POST /auth/refresh` — renueva un JWT · sin auth

Request:

```json
{ "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..." }
```

Response `200`: igual formato que el login (`token` nuevo + `tipo`).

Acepta tokens vencidos hace poco (60 segundos de margen). Si el token es
inválido o el usuario ya no existe: `NO_AUTENTICADO` (401).

### Reportes (`/api/v1/reportes`)

#### `POST /` — crea un reporte · sin auth (app mobile)

Request:

```json
{
  "longitud": -68.15,
  "latitud": -16.5,
  "tamano_draga_codigo": "MEDIANA",
  "tiempo_operacion_codigo": "VARIOS_DIAS",
  "personas_visibles": true,
  "motobombas_visibles": false,
  "alias_informante": "anonimo1",
  "celular_informante": null,
  "nota": "draga operando cerca de la orilla"
}
```

- `longitud`: -180 a 180. `latitud`: -90 a 90.
- `tamano_draga_codigo`: código en `tamanos_draga` (`PEQUENA`, `MEDIANA`, `GRANDE`).
- `tiempo_operacion_codigo`: código en `tiempos_operacion` (`MENOS_1_DIA`, `VARIOS_DIAS`, `MAS_1_SEMANA`).
- `alias_informante`, `celular_informante`, `nota`: opcionales (pueden omitirse o ir `null`).

Response `201`:

```json
{
  "data": {
    "codigo": "10bcaa35-9915-458f-9b5c-d591426b84e4",
    "longitud": -68.15,
    "latitud": -16.5,
    "tamano_draga_codigo": "MEDIANA",
    "tiempo_operacion_codigo": "VARIOS_DIAS",
    "personas_visibles": true,
    "motobombas_visibles": false,
    "estado_codigo": "nuevo",
    "fecha_creacion": "2026-07-24",
    "hora_creacion": "23:18:44.355081"
  }
}
```

#### `POST /sync` — sincroniza un lote offline · sin auth

Request: mismo objeto de arriba, repetido dentro de un array `reportes`:

```json
{ "reportes": [ { "longitud": -68.15, "latitud": -16.5, "...": "..." }, { "...": "..." } ] }
```

Response `201`:

```json
{ "data": { "creados": ["10bcaa35-9915-458f-9b5c-d591426b84e4", "..."] } }
```

Se insertan uno por uno en orden; si alguno falla la validación, corta ahí.

#### `GET /` — lista reportes · sin auth

Query params (todos opcionales):

| Param        | Tipo               | Descripción                                   |
| ------------ | ------------------ | ----------------------------------------------- |
| `estado`     | string             | filtra por `estado_codigo` (`nuevo`, `revisado`, `escalado`) |
| `zona`       | UUID                | filtra reportes ubicados dentro de esa zona protegida |
| `fecha`      | fecha (`YYYY-MM-DD`) | filtra por `fecha_creacion`                     |
| `pagina`     | entero              | por defecto `1`                                 |
| `por_pagina` | entero              | por defecto `20`, máximo `100`                  |

Response `200`:

```json
{
  "data": {
    "reportes": [ { "codigo": "...", "longitud": -68.15, "latitud": -16.5, "...": "..." } ],
    "pagina": 1,
    "por_pagina": 20,
    "total": 1
  }
}
```

#### `GET /:codigo` — detalle de un reporte · sin auth

Response `200`: el mismo objeto de reporte, más su evaluación si existe:

```json
{
  "data": {
    "codigo": "10bcaa35-9915-458f-9b5c-d591426b84e4",
    "longitud": -68.15,
    "latitud": -16.5,
    "...": "...",
    "evaluacion": null
  }
}
```

Cuando el agente ya evaluó el reporte, `evaluacion` trae:

```json
{
  "reporte_codigo": "10bcaa35-9915-458f-9b5c-d591426b84e4",
  "factor_mercurio": 0.0,
  "mercurio_estimado_kg": 0.0,
  "zona_codigo": null,
  "normativa_codigo": null,
  "nivel_riesgo_codigo": "MEDIO",
  "fecha_creacion": "2026-07-24",
  "hora_creacion": "23:20:00"
}
```

Error posible: `NO_ENCONTRADO` (404).

#### `PATCH /:codigo/estado` — cambia el estado · requiere JWT

Request:

```json
{ "estado_codigo": "revisado" }
```

- Valor esperado en la tabla `estados_reporte` (`nuevo`, `revisado`, `escalado`).
- Registra el cambio en `logs_auditoria` (usuario, acción `CAMBIO_ESTADO`, detalle con el estado nuevo).

Response `200`: el reporte actualizado (mismo formato que el detalle, sin `evaluacion`).

Errores posibles: `NO_AUTENTICADO` (401), `NO_ENCONTRADO` (404).

#### `GET /:codigo/evaluacion` — evaluación del agente · sin auth

Response `200`: el objeto `evaluacion` mostrado arriba.
Error posible: `NO_ENCONTRADO` (404, si el reporte todavía no fue evaluado).

### Dashboard (`/api/v1/dashboard`) — todas requieren JWT

#### `GET /metricas`

Response `200`:

```json
{
  "data": {
    "total_reportes": 1,
    "mercurio_acumulado_kg": 0.0,
    "porcentaje_anonimos": 0.0,
    "zonas_afectadas": 0
  }
}
```

#### `GET /mapa`

Response `200`: GeoJSON `FeatureCollection` con un punto por reporte:

```json
{
  "data": {
    "type": "FeatureCollection",
    "features": [
      {
        "type": "Feature",
        "geometry": { "type": "Point", "coordinates": [-68.15, -16.5] },
        "properties": { "codigo": "10bcaa35-9915-458f-9b5c-d591426b84e4", "estado": "revisado" }
      }
    ]
  }
}
```

### Común

#### `GET /health` — sin auth

Response `200`: texto plano `ok` (no usa el formato `{ data }`).

## Formato de respuestas

**Éxito:**

```json
{ "data": { ... } }
```

**Error:**

```json
{ "error": { "codigo": "CREDENCIALES_INVALIDAS", "mensaje": "el correo o la contraseña son incorrectos" } }
```

## Pendiente

El módulo `agent/reglas.rs` todavía no tiene la integración real con el
servidor MCP ni con el LLM (solo firmas con `todo!()`). Se implementará en
una etapa posterior.
