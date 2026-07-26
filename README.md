# Colmena

Sistema comunitario de monitoreo ambiental contra la minería ilegal en ríos.

---

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.3+)
- [Rust](https://rustup.rs/) (edición 2024)
- [Docker](https://www.docker.com/products/docker-desktop/) (para PostgreSQL + PostGIS)
- Chrome (para web)
- Dispositivo Android con cable USB (para mobile)

Verifica tu instalación:
```bash
flutter doctor
cargo --version
docker --version
```

---

## Paso a paso para correr todo

### 1. Base de datos (Docker)

```powershell
docker run -d --name colmena-db -p 5434:5432 -e POSTGRES_USER=colmena -e POSTGRES_PASSWORD=colmena123 -e POSTGRES_DB=colmena --health-cmd="pg_isready -U colmena" --health-interval=10s postgis/postgis:17-3.4
```

Si el contenedor ya existe, solo iniciarlo:
```powershell
docker start colmena-db
```

### 2. API (Rust)

```powershell
cd api
cp .env.example .env
```

Editar `.env` con estos valores:
```
DATABASE_URL=postgres://colmena:colmena123@localhost:5434/colmena
JWT_SECRET=colmena_dev_super_secret_2026_change_me
PORT=3000
CORS_ORIGENES=*
```

Levantar el servidor:
```powershell
cargo run
```

Esperar hasta ver: `listening on 0.0.0.0:3000`

Verificar: http://localhost:3000/health debe responder `ok`

### 3. Cargar datos de prueba (solo la primera vez)

```powershell
cd api
Get-Content scripts/seed_data.sql | docker exec -i colmena-db psql -U colmena -d colmena
```

### 4. Panel Web (Colmena)

```powershell
cd web
flutter pub get
flutter run -d chrome --web-port=8080
```

Abrir http://localhost:8080

**Credenciales:** crear un usuario en "Crear cuenta" y luego iniciar sesión.

### 5. App Mobile (Abeja)

```powershell
cd mobile
flutter pub get
flutter run
```

**En celular físico con USB:**
1. Activar "Opciones de desarrollador" (tocar 7 veces "Número de compilación")
2. Activar "Depuración USB"
3. Conectar cable USB y aceptar el prompt
4. Ejecutar `flutter run`

**Si hay error de plugins (cámara/GPS):**
```powershell
flutter clean
flutter pub get
flutter run
```

---

## Puertos

| Servicio | Puerto |
|---|---|
| PostgreSQL (Docker) | localhost:5434 |
| API Rust | localhost:3000 |
| Web Flutter | localhost:8080 |
| Mobile | Celular vía USB |

---

## Estructura del proyecto

```
colmena/
├── api/        → Backend en Rust (Axum + PostgreSQL + PostGIS)
├── web/        → Panel web en Flutter (Dashboard, mapa, reportes)
├── mobile/     → App mobile en Flutter (Captura de evidencia)
└── mcp/        → Servidor MCP (pendiente)
```

---

## Funcionalidades implementadas

### Panel Web
- Login y registro con JWT
- Sesión persistente (no se pierde al recargar)
- Dashboard con mapa interactivo (OpenStreetMap)
- Métricas: reportes, mercurio, zonas, comunidades
- Gráfico de eventos por mes
- Filtros por estado y fecha (conectados al API)
- Historial de denuncias
- Alertas activas
- Detalle de reporte con cambio de estado
- Chat flotante inteligente (responde con datos reales)
- Tema claro/oscuro

### App Mobile
- Onboarding de bienvenida (solo primera vez)
- Captura de fotos (cámara real + galería)
- GPS real del dispositivo
- Formulario de estimación (4 preguntas con pictogramas)
- Envío de reportes al API
- Lista de registros desde el API
- Indicador online/offline
- Pantalla de resultado con impacto estimado

### API
- Autenticación JWT (login, registro, refresh)
- CRUD de reportes con PostGIS
- Sincronización offline (batch)
- Dashboard métricas y mapa GeoJSON
- Cambio de estado con auditoría
- Evaluaciones del agente
