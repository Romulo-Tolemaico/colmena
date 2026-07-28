# Colmena

**Sistema comunitario de monitoreo ambiental contra la minería ilegal en ríos de Bolivia.**

Colmena es una plataforma integral que permite a comunidades reportar actividades de minería ilegal de forma segura y anónima, generar evidencia georreferenciada, y producir documentación formal para organismos de control.

---

## Problema que resuelve

La minería ilegal de oro en ríos de Bolivia libera toneladas de mercurio al medio ambiente, contaminando fuentes de agua, afectando ecosistemas acuáticos y poniendo en riesgo la salud de comunidades ribereñas. Las denuncias formales requieren evidencia técnica que las comunidades no pueden generar fácilmente, y quienes reportan temen represalias.

## Solución

Colmena democratiza el monitoreo ambiental mediante:
- **App móvil**: Captura de evidencia fotográfica con GPS automático, formulario simplificado de 5 pasos, y envío anónimo.
- **Análisis con IA**: Estimación automática de mercurio liberado, identificación de zonas protegidas afectadas, y normativa aplicable.
- **Panel web**: Dashboard para organizaciones con mapa interactivo, métricas de impacto, historial de denuncias, y generación de reportes PDF oficiales.
- **Chatbot IA**: Asistente integrado con Llama 3.3 (vía Groq) que responde preguntas sobre los datos del sistema.

---

## Arquitectura

```
╔══════════════════════════════════════════════════════════════════════════════════╗
║                          COLMENA - Arquitectura del Sistema                     ║
╚══════════════════════════════════════════════════════════════════════════════════╝

  ┌──────────────────────┐                              ┌──────────────────────┐
  │    📱 APP MÓVIL      │                              │    🖥️ PANEL WEB      │
  │                      │                              │    (Colmena)         │
  ├──────────────────────┤                              ├──────────────────────┤
  │ • Flutter (Android)  │                              │ • Flutter Web        │
  │ • Cámara + GPS       │                              │ • Dashboard          │
  │ • Offline-first      │                              │ • Mapa interactivo   │
  │ • 5 pasos captura    │                              │ • Métricas           │
  │ • Modo oscuro        │                              │ • Historial          │
  │ • Multilenguaje      │                              │ • Chatbot IA         │
  └──────────┬───────────┘                              └──────────┬───────────┘
             │ HTTPS (REST API)                                    │ HTTPS (REST API + JWT)
             │                                                     │
             ▼                                                     ▼
  ╔══════════════════════════════════════════════════════════════════════════════╗
  ║                         🦀 API BACKEND (Rust + Axum)                        ║
  ╠══════════════════════════════════════════════════════════════════════════════╣
  ║                                                                             ║
  ║  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       ║
  ║  │  Reportes   │  │  Usuarios   │  │  Dashboard  │  │   Agente    │       ║
  ║  │  CRUD +     │  │  Auth JWT   │  │  Métricas   │  │   IA/Reglas │       ║
  ║  │  Fotos/PDF  │  │  Login      │  │  GeoJSON    │  │   Evaluación│       ║
  ║  │  Sync batch │  │  Refresh    │  │  Chat IA    │  │   Automática│       ║
  ║  └─────────────┘  └─────────────┘  └─────────────┘  └──────┬──────┘       ║
  ║                                                              │              ║
  ╚══════════════════════════════════════════════════════════════════════════════╝
             │                                                   │
             ▼                                                   ▼
  ┌──────────────────────┐                       ┌──────────────────────┐
  │  🐘 PostgreSQL       │                       │  🤖 Groq API         │
  │  + PostGIS           │                       │  (Llama 3.3 70B)     │
  ├──────────────────────┤                       ├──────────────────────┤
  │ • Reportes + coords  │                       │ • Chatbot IA         │
  │ • Evaluaciones       │                       │ • Contexto del       │
  │ • Fotos (rutas)      │                       │   sistema inyectado  │
  │ • Usuarios + roles   │                       │ • Solo temas         │
  │ • Zonas protegidas   │                       │   ambientales        │
  │ • Normativa          │                       │ • Respuesta <500ms   │
  │ • Consultas geo      │                       │                      │
  └──────────────────────┘                       └──────────────────────┘

  ┌──────────────────────┐                       ┌──────────────────────┐
  │  🗺️ OpenStreetMap    │                       │  ☁️ Render           │
  ├──────────────────────┤                       ├──────────────────────┤
  │ • Tiles de mapa      │                       │ • Deploy automático  │
  │ • Sin API key        │                       │ • Desde rama main    │
  │ • Gratuito           │                       │ • Free tier          │
  └──────────────────────┘                       └──────────────────────┘
```

### Flujo de datos

```
USUARIO (Comunidad)                    ANALISTA (Organización)
       │                                        │
       ▼                                        ▼
  ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
  │ Captura │────>│ Envío   │────>│ Análisis│────>│ Gestión │
  │ Fotos + │     │ API +   │     │ IA auto │     │ Estado  │
  │ GPS +   │     │ Fotos   │     │ mercurio│     │ PDF     │
  │ Datos   │     │         │     │ riesgo  │     │ Alertas │
  └─────────┘     └─────────┘     └─────────┘     └─────────┘
  App Móvil        Backend         Agente IA        Panel Web
```

## Stack tecnológico

| Componente | Tecnología | Justificación |
|-----------|-----------|---------------|
| Backend | Rust + Axum | Rendimiento, seguridad de memoria, bajo consumo |
| Base de datos | PostgreSQL + PostGIS | Consultas geoespaciales nativas |
| App móvil | Flutter (Android) | UI nativa, cámara, GPS, offline-first |
| Panel web | Flutter Web | Código compartido con móvil, UI consistente |
| IA/Chat | Groq + Llama 3.3 70B | Gratuito, ultra-rápido, español |
| Deploy API | Render | Free tier, auto-deploy desde GitHub |
| Mapas | OpenStreetMap + flutter_map | Sin costo, sin API key |

---

## Funcionalidades

### App Móvil (colmena)
- Onboarding educativo (primera vez)
- Pantalla de inicio tipo dashboard con información del proyecto
- Captura de fotos (cámara + galería) con GPS automático
- Formulario de estimación de 5 pasos (draga, tiempo, indicadores, notas, contacto opcional)
- Envío de reportes al servidor con subida de fotos
- Listado de registros con tabs (Todos / Mis registros)
- Detalle de reporte con mapa, fotos, evaluación IA
- Descarga de PDF oficial
- Modo oscuro
- Selector de idioma (Español, English, Quechua)
- Ajustes con guía de seguridad y enlaces institucionales
- Navegación inferior (Inicio, Registros, Ajustes)
- Indicador de conexión online/offline con timeout
- Enlaces a AJAM, SERNAP, Defensoría del Pueblo, Ley 1333

### Panel Web (Colmena)
- Login y registro con JWT (sesión persistente)
- Dashboard con métricas en tiempo real (reportes, mercurio, zonas, anónimos)
- Mapa interactivo con todos los reportes geolocalizados
- Gráfico de eventos por mes
- Filtros por estado y fecha
- Historial de denuncias con tarjetas modernas (hover, chips con color, nivel de riesgo)
- Detalle de reporte con evaluación completa, fotos, mapa
- Cambio de estado (Nuevo → Revisado → Escalado)
- Descarga de PDF por reporte
- Chatbot IA (Llama 3.3) con datos reales del sistema
- Pantalla de alertas activas
- Tema claro/oscuro
- Login con diseño profesional (imagen de fondo, branding animado)

### API Backend
- Autenticación JWT (login, registro, refresh token)
- CRUD de reportes con PostGIS (ubicación geográfica)
- Subida y servicio de fotos (multipart/form-data)
- Generación de PDF por reporte
- Evaluación automática por agente IA (mercurio, riesgo, zona, normativa)
- Dashboard: métricas agregadas, mapa GeoJSON
- Chatbot IA: endpoint que conecta con Groq/Llama 3.3
- Sincronización offline (batch de reportes)
- Cambio de estado con validación de roles
- CORS configurado para web y móvil

---

## Cómo correr el proyecto

### Requisitos previos
- Flutter SDK 3.3+
- Rust (edición 2024)
- Docker (para PostgreSQL + PostGIS)
- Chrome (para web)
- Dispositivo Android con USB (para móvil)

### 1. Base de datos

```bash
docker run -d --name colmena-db -p 5434:5432 \
  -e POSTGRES_USER=colmena -e POSTGRES_PASSWORD=colmena123 \
  -e POSTGRES_DB=colmena postgis/postgis:17-3.4
```

### 2. API

```bash
cd api
cp .env.example .env
# Editar .env con DATABASE_URL, JWT_SECRET, PORT=3000, CORS_ORIGENES=*
cargo run
```

### 3. Datos seed (primera vez)

```bash
cat api/scripts/seed_data.sql | docker exec -i colmena-db psql -U colmena -d colmena
```

### 4. Web

```bash
cd web
flutter pub get
flutter run -d chrome
```

### 5. Móvil

```bash
cd mobile
flutter pub get
flutter run
```

---

## Demo en vivo

### Capturas

**App Móvil:**

<!-- Pegar imagen aquí -->

**Panel Web:**

<!-- Pegar imagen aquí -->

---

## Demo en vivo

### Capturas

**App Móvil:**

<!-- Pegar imagen aquí -->

**Panel Web:**

<!-- Pegar imagen aquí -->

---

## Acceso a la plataforma

| Plataforma | URL | Notas |
|-----------|-----|-------|
| Panel Web | https://colmena-1.onrender.com/ | Crear un usuario para monitorear reportes |
| API Backend | https://colmena-1mlk.onrender.com/api/v1 | Endpoints REST |
| App Móvil (APK) | [Descargar APK](https://drive.google.com/file/d/18QMdPox62MKUb3F--vTEBmno43l9mxfL/view?usp=sharing) | Instalar en Android |

### Para usar el Panel Web:
1. Entrar a https://colmena-1.onrender.com/
2. Crear una cuenta desde "Crear cuenta" (rol Analista o Administrador)
3. Iniciar sesión para acceder al dashboard de monitoreo

### Para usar la App Móvil:
1. Descargar el APK desde el enlace
2. Instalar en el celular (activar "Fuentes desconocidas")
3. Abrir y seguir el onboarding
4. Crear un reporte con fotos + GPS

---

## Deploy en producción

| Servicio | URL |
|---------|-----|
| API Backend | https://colmena-1mlk.onrender.com |
| Endpoint reportes | https://colmena-1mlk.onrender.com/api/v1/reportes |

### Variables de entorno en Render
```
DATABASE_URL=postgres://...
JWT_SECRET=...
PORT=3000
CORS_ORIGENES=*
GROQ_API_KEY=gsk_...
```

---

## Estructura del repositorio

```
colmena/
├── api/                → Backend Rust (Axum + PostgreSQL + PostGIS)
│   ├── src/
│   │   ├── agent/          → Reglas de evaluación IA del agente
│   │   ├── dashboard/      → Métricas, mapa GeoJSON, chatbot IA
│   │   ├── evaluaciones/   → Modelo y consultas de evaluación
│   │   ├── reportes/       → CRUD, fotos, PDF, sincronización
│   │   └── usuarios/       → Autenticación JWT (login, registro)
│   ├── migrations/         → Schema SQL (PostGIS)
│   ├── scripts/            → Datos seed de prueba
│   ├── uploads/            → Fotos y PDFs generados (local)
│   ├── Cargo.toml          → Dependencias Rust
│   ├── Dockerfile          → Imagen para deploy en Render
│   └── .env.example        → Variables de entorno requeridas
│
├── web/                → Panel web Flutter (Dashboard de monitoreo)
│   ├── lib/
│   │   ├── app.dart        → Shell principal, auth, navegación
│   │   └── src/
│   │       ├── data/       → Servicio API con JWT
│   │       ├── models/     → Modelos (reporte, métricas)
│   │       ├── screens/    → Dashboard, historial, alertas, login
│   │       └── widgets/    → Mapa, chat IA, panel detalle, branding
│   ├── assets/images/      → Imagen de fondo login
│   └── pubspec.yaml        → Dependencias Flutter
│
├── mobile/             → App móvil Flutter (Android)
│   ├── lib/
│   │   ├── app.dart        → Shell con navegación inferior y tema
│   │   └── src/
│   │       ├── data/       → Servicio API, datos mock offline
│   │       ├── models/     → Modelo Registro
│   │       ├── screens/    → Inicio, registros, ajustes, cámara, estimación
│   │       └── widgets/    → Indicadores de conexión y sync
│   ├── android/            → Configuración nativa (permisos, ícono)
│   └── pubspec.yaml        → Dependencias Flutter
│
├── mcp/                → Servidor MCP (reservado para extensiones futuras)
├── .gitignore
└── README.md           → Este archivo
```

---

## Equipo

Desarrollado para el Hackathon Colmena 2026.

---

## Licencia

Proyecto académico / hackathon. Todos los derechos reservados.
