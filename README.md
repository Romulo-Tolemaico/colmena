# Colmena

Sistema comunitario de monitoreo ambiental contra la minería ilegal en ríos.

---

## Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.3+)
- Chrome (para web)
- Dispositivo Android con cable USB o emulador (para mobile)

Verifica tu instalación:
```bash
flutter doctor
```

---

## Panel Web (Colmena)

```bash
cd web
flutter pub get
flutter run -d chrome
```

**Credenciales de prueba:** cualquier email con `@` y contraseña de 6+ caracteres (ej: `test@test.com` / `123456`).

---

## App Mobile (Abeja)

### En navegador (modo web para preview rápido)
```bash
cd mobile
flutter pub get
flutter run -d chrome
```

### En celular Android con cable USB
1. Activar **Opciones de desarrollador** en tu celular (toca 7 veces "Número de compilación" en Ajustes > Acerca del teléfono)
2. Activar **Depuración USB** en Opciones de desarrollador
3. Conectar cable USB y aceptar el prompt en el celular
4. Ejecutar:
```bash
cd mobile
flutter pub get
flutter run
```

Si hay errores de plugins nativos (cámara/GPS), hacer:
```bash
flutter clean
flutter pub get
flutter run
```

### Verificar dispositivos conectados
```bash
flutter devices
```

---

## Estructura del proyecto

```
colmena/
├── web/        → Panel web (Flutter Web) - Dashboard, mapa, reportes
├── mobile/     → App mobile (Flutter) - Captura de evidencia en campo
├── api/        → Backend (pendiente)
└── mcp/        → Servidor MCP (pendiente)
```

---

## Notas

- Ambos proyectos funcionan con datos mock (sin backend real).
- La web incluye: login, registro, dashboard con mapa interactivo, historial, alertas, chat flotante.
- La mobile incluye: captura de fotos (cámara/galería), GPS real, formulario de estimación, resultado con impacto.
