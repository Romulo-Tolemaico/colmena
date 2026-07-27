# ============================================================
# Multi-stage build para la API de Colmena (Rust + Axum)
# Produce una imagen final liviana (~100 MB) usando Debian slim
# con solo el binario compilado en release.
# ============================================================

# --- Etapa 1: compilar el binario en release ---
FROM rust:1.83-slim-bookworm AS builder

# Dependencias del sistema necesarias para compilar sqlx (TLS) y ring
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar primero solo los archivos de dependencias para aprovechar
# la cache de Docker (si el código fuente cambia pero Cargo.toml no,
# las dependencias no se recompilan).
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release && rm -rf src target/release/deps/api*

# Ahora copiar el código fuente real y las migraciones
COPY src ./src
COPY migrations ./migrations

# Compilar el binario final en release
RUN cargo build --release

# --- Etapa 2: imagen final liviana ---
FROM debian:bookworm-slim

# Dependencias de runtime mínimas (TLS y CA certificates para HTTPS)
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copiar el binario compilado
COPY --from=builder /app/target/release/api ./api

# Copiar las migraciones (sqlx::migrate!() las embebe en el binario,
# pero las necesita presentes en tiempo de compilación, no de ejecución;
# se incluyen igualmente por si se quiere correr sqlx-cli desde el
# contenedor en el futuro).
COPY --from=builder /app/migrations ./migrations

# Crear la carpeta de uploads (filesystem efímero en Render free tier)
RUN mkdir -p /app/uploads

# Puerto por defecto (se puede sobreescribir con la variable PORT)
ENV PORT=3000
EXPOSE 3000

# El servidor lee las variables de entorno directamente (DATABASE_URL,
# JWT_SECRET, PORT, CORS_ORIGENES, CARPETA_ARCHIVOS). No necesita .env
# dentro del contenedor — Render las inyecta como env vars del servicio.
ENV CARPETA_ARCHIVOS=/app/uploads

CMD ["./api"]
