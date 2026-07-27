# Colmena Mobile

App móvil Android para captura de evidencia de minería ilegal en ríos. Diseñada para comunidades que necesitan reportar de forma segura, anónima y sin depender de conectividad constante.

---

## Características

- **Captura de evidencia**: Fotos con cámara o galería + GPS automático
- **Formulario simplificado**: 5 pasos con pictogramas (draga, tiempo, indicadores, notas, contacto)
- **Análisis con IA**: Al enviar, el backend evalúa mercurio, riesgo, zona protegida y normativa
- **Modo offline**: Si no hay conexión, muestra datos mock y se sincroniza después
- **Detalle con mapa**: Visualiza cada reporte en OpenStreetMap con coordenadas exactas
- **Descarga de PDF**: Genera y abre el reporte formal desde el servidor
- **Fotos en detalle**: Carga y muestra las fotos de evidencia del servidor
- **Modo oscuro**: Configurable desde Ajustes
- **Selector de idioma**: Español, English, Quechua (UI preparada)
- **Guía de seguridad**: Consejos para reportar sin exponerse
- **Enlaces institucionales**: AJAM, SERNAP, Defensoría del Pueblo, Ley 1333

---

## Navegación

| Tab | Descripción |
|-----|------------|
| Inicio | Dashboard con info del proyecto, pasos, seguridad, recursos |
| Registros | Todos los reportes + Mis registros (tabs) |
| Ajustes | Modo oscuro, idioma, seguridad, enlaces, versión |

**FAB**: Botón "Nuevo registro" que inicia el flujo de captura.

---

## Flujo de registro

1. **Cámara** → Tomar fotos + GPS automático
2. **Tamaño de draga** → Pequeña / Mediana / Grande
3. **Tiempo operando** → <1 día / Varios días / +1 semana
4. **Indicadores** → Personas visibles / Motobombas
5. **Notas** → Descripción libre (opcional)
6. **Contacto** → Alias + celular (opcional, si vacío = anónimo)
7. **Envío** → Sube al servidor + fotos + recibe evaluación IA
8. **Resultado** → Muestra impacto + descarga PDF

---

## Cómo correr

```bash
cd mobile
flutter pub get
flutter run
```

### Celular físico
1. Activar depuración USB
2. Conectar cable
3. `flutter run`

### Generar APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Configuración API

Por defecto apunta a: `https://colmena-1mlk.onrender.com/api/v1`

Para desarrollo local:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000/api/v1
```

---

## Dependencias principales

| Paquete | Uso |
|---------|-----|
| flutter_map | Mapas OpenStreetMap |
| geolocator | GPS del dispositivo |
| image_picker | Cámara y galería |
| http + http_parser | Llamadas API + multipart |
| url_launcher | Abrir enlaces y PDFs |
| shared_preferences | Persistencia local (onboarding) |
| permission_handler | Permisos de cámara/ubicación |

---

## Estructura

```
mobile/lib/
├── main.dart
├── app.dart                → Shell principal con navegación y tema
└── src/
    ├── data/
    │   ├── api_service.dart    → Servicio HTTP (reportes, fotos, PDF)
    │   └── mock_registros.dart → Datos offline
    ├── models/
    │   └── registro.dart       → Modelo de datos
    ├── screens/
    │   ├── inicio_screen.dart      → Dashboard de inicio
    │   ├── registros_screen.dart   → Listado con tabs
    │   ├── ajustes_screen.dart     → Configuración
    │   ├── camera_screen.dart      → Captura de fotos + GPS
    │   ├── estimation_screen.dart  → Formulario 5 pasos
    │   ├── record_detail_screen.dart → Detalle + mapa + fotos
    │   ├── report_result_screen.dart → Resultado + PDF
    │   └── onboarding_screen.dart  → Primera vez
    └── widgets/
        ├── connection_indicator.dart
        └── sync_status_badge.dart
```
