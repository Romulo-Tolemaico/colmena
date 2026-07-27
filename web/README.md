# Colmena Web (Panel de Monitoreo)

Panel web para organizaciones ambientales y autoridades. Permite visualizar, gestionar y analizar los reportes de minería ilegal enviados desde la app móvil.

---

## Características

- **Login/Registro** con JWT y sesión persistente
- **Dashboard** con métricas en tiempo real:
  - Total de reportes
  - Mercurio acumulado estimado (kg)
  - Zonas protegidas afectadas
  - Porcentaje de reportes anónimos
  - Gráfico de eventos por mes
- **Mapa interactivo** con todos los reportes geolocalizados (OpenStreetMap)
- **Historial de denuncias** con tarjetas modernas (hover, chips con colores, nivel de riesgo)
- **Detalle de reporte** con:
  - Mapa de ubicación
  - Fotos de evidencia
  - Evaluación IA (mercurio, riesgo, zona, normativa)
  - Cambio de estado (Nuevo → Revisado → Escalado)
  - Descarga de PDF
- **Alertas activas** (reportes nuevos y de alto riesgo)
- **Chatbot IA** (Llama 3.3 vía Groq) con datos reales del sistema
- **Filtros** por estado y fecha
- **Tema claro/oscuro**
- **Diseño de login** profesional con imagen de fondo y branding animado

---

## Cómo correr

```bash
cd web
flutter pub get
flutter run -d chrome
```

---

## Configuración API

Por defecto apunta a: `https://colmena-1mlk.onrender.com/api/v1`

Para desarrollo local:
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

---

## Credenciales de prueba

Para acceder al panel web en producción:
- **Correo:** admin@colmena.org
- **Contraseña:** Admin123!

O crear una cuenta nueva desde "Crear cuenta".

---

## Pantallas

| Pantalla | Descripción |
|----------|------------|
| Login | Autenticación con diseño premium |
| Register | Registro de nuevos usuarios |
| Dashboard | Métricas, mapa, gráfico, filtros |
| Historial | Lista completa de reportes |
| Alertas | Reportes nuevos y de alto riesgo |
| Detalle | Info completa + evaluación + fotos + PDF |

---

## Dependencias principales

| Paquete | Uso |
|---------|-----|
| flutter_map | Mapas OpenStreetMap |
| http | Llamadas API |
| shared_preferences | Persistencia de sesión/JWT |
| intl | Formateo de fechas |

---

## Estructura

```
web/lib/
├── main.dart
├── app.dart                → Shell principal, auth, navegación
└── src/
    ├── data/
    │   ├── api_service.dart    → Servicio HTTP con JWT
    │   └── data_service.dart   → Datos mock (fallback)
    ├── models/
    │   ├── reporte.dart            → Modelo de reporte
    │   └── metricas_dashboard.dart → Métricas del dashboard
    ├── screens/
    │   ├── login_screen.dart       → Login con branding
    │   ├── register_screen.dart    → Registro
    │   ├── dashboard_screen.dart   → Dashboard principal
    │   ├── historial_screen.dart   → Historial de denuncias
    │   └── alertas_screen.dart     → Alertas activas
    └── widgets/
        ├── branding_panel.dart     → Panel animado login/register
        ├── app_shell.dart          → Layout con sidebar
        ├── map_widget.dart         → Mapa interactivo
        ├── report_detail_panel.dart → Panel detalle de reporte
        └── floating_chat.dart      → Chatbot IA flotante
```

---

## Chatbot IA

El chatbot del panel web está conectado con **Llama 3.3 70B** vía Groq API. Responde preguntas sobre:
- Total de reportes y mercurio acumulado
- Zonas protegidas afectadas
- Estadísticas de reportes anónimos
- Información general sobre minería ilegal

Solo responde sobre temas ambientales/minería. Si se le pregunta algo fuera de tema, redirige amablemente.

Requiere la variable `GROQ_API_KEY` en el backend.
