# GUIÓN DE DEMO — COLMENA (4 minutos)

## Hackathon 2026 — Sistema de Monitoreo Ambiental contra Minería Ilegal

---

## ANTES DE EMPEZAR (preparación)

- [ ] Web abierta en Chrome con login listo (admin@colmena.org / Admin123!)
- [ ] Celular con la app instalada y abierto en Inicio
- [ ] Backend corriendo en Render (verificar que responde)
- [ ] Tener una foto de prueba lista en el celular

---

## MINUTO 0:00 – 0:30 | APERTURA (Impacto)

**DECIR:**

> "La minería ilegal de oro en Bolivia libera toneladas de mercurio a nuestros ríos cada año. Un solo gramo contamina 10,000 litros de agua. Las comunidades ribereñas no tienen herramientas técnicas para denunciar, y quienes se atreven a reportar temen por su seguridad."

> "Colmena resuelve esto. Es un sistema completo de monitoreo ambiental comunitario con inteligencia artificial."

---

## MINUTO 0:30 – 1:30 | APP MÓVIL (En vivo)

**MOSTRAR EL CELULAR:**

> "Empecemos por donde todo inicia: la app móvil. Cualquier persona de la comunidad puede descargarla."

### Acción 1: Mostrar Onboarding (primera vez)
> "Cuando un usuario abre la app por primera vez, ve un onboarding educativo: qué es Colmena, cómo capturar evidencia, cómo funciona el análisis automático, y la garantía de anonimato. 4 pantallas con navegación por deslizar."

> "Esto solo se muestra UNA vez — se guarda en almacenamiento local con SharedPreferences."

### Acción 2: Mostrar pantalla de Inicio (5 seg)
> "Después del onboarding, la app tiene un dashboard informativo con recursos institucionales: AJAM, SERNAP, Defensoría del Pueblo. Enlaces directos que abren el navegador."

### Acción 2: Tap en "Nuevo registro" (iniciar flujo)
> "El flujo de captura son 5 pasos diseñados para campo — botones grandes, pictogramas, mínimo texto."

### Acción 3: Tomar foto (cámara)
> "Paso 1: Captura fotográfica. GPS se registra automáticamente con precisión de metros. No necesita acercarse a la operación."

### Acción 4: Pasar rápido por estimación (mostrar las pantallas)
> "Pasos 2 a 5: Tamaño de draga, tiempo operando, indicadores visibles, contacto opcional. Todo visual, funciona sin alfabetización tecnológica."

### Acción 5: Enviar reporte
> "Al enviar, el backend procesa con un agente de IA que calcula automáticamente: mercurio estimado liberado, nivel de riesgo, zona protegida afectada y normativa boliviana aplicable."

### Acción 6: Mostrar resultado con mercurio
> "Aquí vemos el resultado: X kg de mercurio estimado. Puedo descargar un PDF oficial para denuncia formal."

### Acción 7: Mostrar Registros tab
> "Todos los reportes se listan aquí. Al abrir uno veo el mapa con la ubicación exacta, las fotos de evidencia, y toda la evaluación de la IA."

---

## MINUTO 1:30 – 3:00 | PANEL WEB (En vivo)

**CAMBIAR A CHROME:**

> "Ahora el otro lado: el panel web para organizaciones ambientales y autoridades."

### Acción 8: Mostrar Dashboard
> "Dashboard en tiempo real. Métricas: total de reportes, mercurio acumulado en kilogramos, zonas protegidas afectadas, porcentaje de reportes anónimos. Todo viene del API."

### Acción 9: Señalar el mapa
> "Mapa interactivo con OpenStreetMap. Cada punto es un reporte geolocalizado. Sin API keys de pago, totalmente gratuito."

### Acción 10: Ir a Historial
> "Historial completo de denuncias. Cada tarjeta muestra nivel de riesgo con color, tamaño de draga, indicadores, mercurio estimado. Diseño responsive."

### Acción 11: Abrir un reporte (detalle)
> "Detalle del reporte: mapa, fotos de evidencia cargadas desde el servidor, evaluación completa de la IA, y puedo cambiar el estado del reporte — nuevo, revisado, escalado."

### Acción 12: Mostrar el PDF
> "Genero un PDF oficial con un click. Documento listo para presentar ante la AJAM o Defensoría del Pueblo."

### Acción 13: Abrir el Chatbot
> "Y esto es el chatbot. Está conectado con Llama 3.3 de 70 mil millones de parámetros vía Groq. Le pregunto sobre los datos del sistema..."

**Escribir:** "¿Cuánto mercurio se ha estimado en total?"

> "Responde con datos REALES del backend. Y está entrenado para SOLO responder sobre minería ilegal y monitoreo ambiental. Si le preguntas una receta de cocina, te redirige."

---

## MINUTO 3:00 – 3:30 | ARQUITECTURA (Verbal, rápido)

> "Arquitectura del sistema:"
>
> - "Backend en **Rust con Axum** — rendimiento de bajo nivel, seguridad de memoria."
> - "Base de datos **PostgreSQL con PostGIS** — consultas geoespaciales nativas."
> - "Frontend **Flutter** multiplataforma — web y Android desde un solo codebase."
> - "IA: **Llama 3.3 70B** vía Groq para el chatbot, y un agente de reglas para evaluación automática de reportes."
> - "Deploy en **Render** — auto-deploy desde GitHub."
> - "La app funciona **offline** — si no hay señal, guarda localmente y sincroniza cuando hay conexión."

---

## MINUTO 3:30 – 4:00 | CIERRE (Impacto social)

> "Colmena no es solo software. Es una herramienta de justicia ambiental."
>
> "Permite que una persona de una comunidad ribereña, con solo un celular, genere evidencia técnica equivalente a un informe pericial — con geolocalización, estimación de impacto, normativa aplicable, y un PDF oficial."
>
> "Todo de forma **anónima**, **segura**, y **gratuita**."
>
> "Ríos sanos, comunidades fuertes, futuro sostenible."

---

## TIPS PARA EL DEMO

1. **Velocidad**: No expliques cada botón, muestra y sigue. Los jueces ven, tú narras.
2. **No leas**: Memoriza las frases clave. Habla con convicción.
3. **Errores**: Si algo falla, di "esto es un demo en vivo" y sigue con otra parte.
4. **Contacto visual**: Mira a los jueces, no a la pantalla.
5. **Cierre fuerte**: La última frase es la que recuerdan. Hazla con pausa y fuerza.

---

## PALABRAS CLAVE PARA IMPRESIONAR

- Agente de IA con evaluación automática
- Consultas geoespaciales con PostGIS
- Arquitectura event-driven con Rust
- LLM de 70B parámetros en producción
- Offline-first con sincronización diferida
- Zero-knowledge del informante (anonimato)
- Evidencia georreferenciada con metadatos GPS
- Multiplataforma desde un solo codebase (Flutter)
- API RESTful con autenticación stateless (JWT)
- Deploy CI/CD desde GitHub a Render
