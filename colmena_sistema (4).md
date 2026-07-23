# Colmena
### Sistema comunitario de monitoreo ambiental contra la minería ilegal en ríos

---

## 1. Contexto y problema

La minería aluvial (de río) con uso de mercurio es una de las formas de minería con mayor impacto ambiental en Bolivia:

- Se liberan entre 4 y 6 partes de mercurio por cada parte de oro producido.
- Bolivia se convirtió en el segundo mayor emisor mundial de mercurio por minería de oro (dato de 2016).
- Entre 2021 y 2023 se detectó mercurio en comunidades nativas alejadas de los puntos de extracción.
- Un estudio de 2021 encontró 180 dragas en el río Madre de Dios, 166 de ellas operando de forma ilegal.
- La actividad avanza más rápido que la capacidad regulatoria del Estado, sin un Ministerio de Medio Ambiente actualmente en funciones.

**Ya existe un canal oficial de denuncia** (AJAM — `seguimiento.autoridadminera.gob.bo`), pero tiene limitaciones importantes:

| Limitación de AJAM | Consecuencia |
|---|---|
| Exige identificación completa (nombre, cédula, documento de identidad digital en PDF) | Expone al denunciante ante posibles represalias |
| Ubicación por dropdown manual + mapa de doble clic | Sin verificación automática de zona protegida/territorio indígena |
| Campos de texto libre para describir hechos | Depende de que el denunciante sepa redactar y conozca la normativa |
| Formulario web tradicional, sin modo offline | Poco viable en zonas remotas sin señal |
| Sin reporte de vuelta ni panel de seguimiento | El denunciante no tiene visibilidad de patrones ni impacto acumulado |

**Colmena no reemplaza a AJAM — llena el vacío que deja**, protegiendo al informante y automatizando el análisis de impacto.

---

## 2. Modelo de usuarios: "Abeja → Colmena"

| Rol | Quién es | Qué hace | Qué expone |
|---|---|---|---|
| **Abeja** | Monitor comunitario / comunario en campo | Registra evidencia: foto, ubicación, estimación rápida de la actividad | Nada de su identidad personal (dato de contacto es opcional) |
| **Agente (sistema)** | Backend + LLM + MCP | Calcula impacto (mercurio estimado), verifica si la ubicación cae en zona protegida/territorio indígena, cita la normativa aplicable | — |
| **Colmena (organización)** | ONG / organización territorial / ambiental | Consolida reportes, ve patrones, decide cuándo y cómo escalar la denuncia formal ante AJAM | Su propia identidad institucional, nunca la del informante |

**Principio de diseño clave:** lo que se protege es la identidad de quien reporta, no la ubicación de la actividad (esa es el dato más valioso del reporte).

**Datos de contacto del informante son opcionales**, nunca obligatorios:
- Nunca se pide documento de identidad ni cédula escaneada.
- Al final del flujo se puede ofrecer dejar un nombre/alias y celular, con un botón de "Omitir" tan visible como el de continuar.
- Cada reporte queda marcado internamente como "anónimo" o "con contacto", para que la organización sepa qué tipo de seguimiento es posible.

---

## 3. Arquitectura del sistema

```
App mobile (Abeja)                 Panel web (Colmena)
       │                                    │
       ▼                                    ▼
  ┌─────────────────────────────────────────────┐
  │         Backend / Agente                     │
  │  Orquestador de reglas (determinístico)       │
  │  + LLM (solo para redactar texto de denuncia) │
  └─────────────────────┬─────────────────────────┘
                         ▼
              ┌─────────────────────┐
              │    Servidor MCP      │
              │  (el corazón)        │
              └──────────┬───────────┘
     ┌───────────┬────────┴────────┬────────────┐
     ▼           ▼                 ▼            ▼
 Normativa   Estimación        Ubicación/     Generador
 ambiental   económica del     jurisdicción   de reportes
             daño ambiental                   (PDF)
                         │
                         ▼
              ┌─────────────────────┐
              │  PostgreSQL + PostGIS │
              │  (fotos → S3, PDFs)   │
              └─────────────────────┘
```

**Principio de diseño:** ni la app mobile ni el panel web hablan directo con el LLM o el MCP — todo pasa por el backend/agente. Esto evita duplicar lógica de negocio entre clientes y permite agregar futuros clientes (bot de Slack, CLI, etc.) sin reescribir nada.

**Aclaración sobre el rol del agente (importante para el MVP):** el agente NO es un LLM haciendo todo el razonamiento. Es un orquestador de reglas (if/else) que decide qué tool invocar y en qué orden. El cálculo de mercurio (RF-06/RF-07) es un **algoritmo determinístico** — no se le pide al LLM que calcule números, para evitar alucinaciones. El LLM se usa únicamente para redactar el texto final de la denuncia (explicar el impacto de forma comprensible, citar la normativa con coherencia) y para responder preguntas en el chat del dashboard.

**Cálculo de mercurio (algoritmo, no LLM):**
Un factor dentro del rango 4–6 se elige combinando tamaño de la draga + tiempo estimado operando + indicadores visuales adicionales (número de personas/buzos visibles, presencia de motobombas o mangueras). Ejemplo: draga pequeña + "más de una semana" → factor 5; draga grande + "varios días" → factor 6.

**Fotografías y metadata EXIF:** el EXIF se lee en el propio dispositivo antes de subir la foto, para verificar consistencia (fecha reciente, ubicación coherente con lo declarado) y detectar fotos recicladas o duplicadas. Al subir al servidor, se limpian los campos que no aportan y sí arriesgan la protección del informante (modelo/serie de cámara, tags de propietario configurados en el teléfono). El GPS y la fecha capturados por la app se conservan, porque son el dato útil del reporte.

### 3.1 App mobile (cliente de la Abeja)
- Interfaz tipo formulario/botones — **no es un chat**. En campo, con mala señal, tocar 3-4 botones es más rápido y confiable que redactar mensajes.
- Offline-first: guarda registros localmente y sincroniza cuando hay señal.
- No expone nunca el análisis interno del agente — el informante solo ve "tomé la foto, marqué ubicación, generé mi reporte".

### 3.2 Panel web (cliente de la Colmena)
- Dashboard con mapa, filtros y métricas acumuladas.
- Incluye un **chat conversacional opcional** sobre los datos ya recolectados (ej. "¿qué zona tuvo más denuncias este mes?"). Aquí sí tiene sentido un agente tipo chat, porque quien lo usa tiene tiempo y conexión, y quiere explorar información, no capturar un evento urgente.

### 3.3 Servidor MCP (el corazón)
Expone las tools que el agente invoca según el caso:
1. **Normativa** — consulta la normativa ambiental y de seguridad minera vigente (Ley de Medio Ambiente, Convenio de Minamata).
2. **Estimación económica del daño ambiental** — a partir de un volumen estimado de oro extraído, calcula el valor equivalente en regalías no pagadas al Estado. (Reemplaza a la tool original de "consulta de precios", que no tenía un propósito claro dentro del reporte — este reencuadre sí aporta al argumento de la denuncia: cuantifica el perjuicio económico, no solo el ambiental.)
3. **Ubicación/jurisdicción** — determina si la coordenada GPS cae en territorio indígena o área protegida.
4. **Reportes** — genera el documento/reporte final en PDF.

**Sobre el chat del dashboard (RF-17):** para que sea rápido y económico, el agente no debe procesar todos los reportes en cada pregunta. La pregunta del usuario se traduce a una consulta estructurada simple sobre la base de datos (ej. filtrar por zona y fecha), se ejecuta esa consulta, y el LLM solo redacta la respuesta a partir del resultado ya filtrado. Para el MVP, un set simple de filtros predefinidos es suficiente — no hace falta una capa de búsqueda semántica sofisticada.

---

### 3.4 Esquema de datos (entrada/salida)

| Entrada (capturado por la Abeja) | Salida (generado por el sistema) |
|---|---|
| Foto(s) de la operación | Mercurio estimado liberado (kg) |
| Ubicación GPS + timestamp | Zona protegida/territorio indígena (sí/no + nombre) |
| Tamaño de draga (pequeña/mediana/grande) | Normativa citada (artículo/ley aplicable) |
| Tiempo estimado operando (menos de 1 día / varios días / más de una semana) | Estimación económica del daño (regalías no pagadas) |
| Indicadores visibles (personas, motobombas/mangueras) | Nivel de riesgo/urgencia (clasificación) |
| Notas opcionales (texto libre) | Reporte PDF consolidado |
| Contacto opcional (alias/celular) | Estado del reporte (nuevo/revisado/escalado) |

---

## 4. Flujo del sistema

1. **Detectar y registrar la draga** — el monitor ve una draga **operando activamente** (no una ya detenida o abandonada) y abre "nuevo registro" en la app. La evidencia de una operación en curso es lo que le da fuerza al reporte; una draga ya abandonada no prueba quién la operaba ni cuándo.
2. **Capturar evidencia a distancia segura** — toma una foto (usando zoom, sin acercarse físicamente a la operación); el sistema guarda automáticamente ubicación GPS y hora. Sin señal, el registro queda guardado localmente. La app no debe incentivar que el monitor se acerque más de lo necesario solo para conseguir mejor evidencia.
3. **Estimar la actividad por indicadores observables a distancia** — formulario corto: tamaño aproximado de la draga, tiempo estimado operando, cantidad de personas visibles / presencia de motobombas o mangueras, notas opcionales. El sistema nunca asume que se puede medir el mercurio real usado — solo lo que puede observarse sin poner en riesgo al monitor.
4. **El agente calcula el impacto (estimación, no medición exacta)** — al sincronizar, el algoritmo determinístico del backend elige un factor dentro del rango documentado (4 a 6 partes de mercurio por parte de oro) según los indicadores observados. El resultado siempre se presenta como una estimación, nunca como un dato medido con precisión de laboratorio.
5. **Verificar si es zona protegida** — el MCP cruza la ubicación contra territorios indígenas/áreas protegidas y trae la normativa aplicable.
6. **Generar el reporte de denuncia** — documento con foto, ubicación, cálculo de mercurio y normativa citada.
7. **Consolidar en el panel de la organización** — la Colmena ve todos los reportes, patrones por zona, y decide cómo escalar la denuncia formal.

---

## 5. Requisitos funcionales (RF)

### App mobile (Abeja)
- **RF-01:** Registrar una actividad minera **en curso** (operación activa) con fecha, hora y tipo de labor.
- **RF-02:** Capturar automáticamente la ubicación GPS de cada registro.
- **RF-03:** Adjuntar evidencia fotográfica a cada registro, con función de zoom para permitir captura a distancia segura sin necesidad de acercamiento físico.
- **RF-04:** Funcionar sin conexión y sincronizar los registros cuando haya señal disponible.
- **RF-05:** Ofrecer, de forma opcional y no obligatoria, dejar un dato de contacto (alias/celular) al finalizar el registro.
- **RF-19:** Registrar indicadores observables a distancia (tamaño de draga, tiempo estimado operando, personas/motobombas visibles) sin requerir que el monitor se acerque a verificar datos exactos.

### Agente (backend + LLM)
- **RF-06:** Recibir la información capturada por el cliente mobile y determinar qué tools del MCP invocar.
- **RF-07:** Calcular el nivel de riesgo/impacto ambiental mediante un algoritmo determinístico (no el LLM), a partir de los indicadores observables registrados.
- **RF-08:** Explicar qué normativa se incumple (si aplica) y por qué.
- **RF-09:** Mantener un historial de las evaluaciones realizadas.

### Servidor MCP
- **RF-10:** Exponer una tool que consulte la normativa ambiental y de seguridad minera vigente.
- **RF-11:** Exponer una tool que calcule la estimación económica del daño ambiental (regalías no pagadas) a partir del volumen de oro estimado.
- **RF-12:** Exponer una tool que determine si una coordenada GPS cae en territorio indígena/área protegida.
- **RF-13:** Exponer una tool que genere el reporte oficial en PDF. El PDF debe incluir una nota de metodología visible: *"Esta estimación se basa en observación a distancia segura y no reemplaza una medición técnica de campo. Su propósito es dar una base razonable de evidencia inicial."*
- **RF-14:** Registrar cada invocación de tool (qué se consultó y cuándo) para trazabilidad.

### Panel web (Colmena)
- **RF-15:** Mostrar un dashboard con mapa de denuncias, filtros (fecha, zona, nivel de riesgo) y métricas acumuladas.
- **RF-16:** Permitir consultar el historial de denuncias registradas.
- **RF-17:** Ofrecer un chat conversacional sobre los datos acumulados (patrones, resúmenes, comparativas).
- **RF-18:** Marcar cada reporte como "anónimo" o "con contacto" según lo que el informante haya decidido compartir.

---

## 5.1 Idioma y accesibilidad lingüística

**Corrección de contexto:** en la zona donde se documentó el caso más grave (río Madre de Dios, Territorio Indígena Multiétnico II, entre Beni y Pando), el idioma predominante **no es guaraní** — el guaraní se habla en el Chaco boliviano (Santa Cruz, Chuquisaca, Tarija), una región distinta. Los pueblos que habitan efectivamente esa zona son **Tacana, Ese Ejja y Cavineño**, los tres de la familia lingüística tacana (junto con araona y reyesano). Si el proyecto se enfoca en otra cuenca, conviene verificar qué pueblos la habitan antes de asumir un idioma específico.

**Punto de fondo válido:** Bolivia reconoce 36 idiomas oficiales, y no se puede asumir que todo monitor comunitario domina el español con fluidez.

**Enfoque para el MVP del hackathon (realista con el tiempo disponible):**
- Traducir toda la interfaz a varios idiomas indígenas en 5 días no es viable — son idiomas minoritarios sin librerías de traducción confiables, y una traducción automática mal hecha puede ofender o confundir más que ayudar.
- **RF-20:** La interfaz mobile debe apoyarse en íconos y pictogramas para las decisiones críticas (tamaño de draga, tiempo operando, indicadores visibles), minimizando la dependencia de texto en español.
- **RF-21 (futuro, no MVP):** Agregar audio corto pregrabado en el idioma local como ayuda contextual opcional (botón "🔊" junto a cada pregunta), en coordinación con la organización indígena/ONG que ya trabaja con los monitores territoriales.
- Documentar explícitamente en el pitch que el diseño ya contempla esta limitación y prevé soporte de audio en idiomas locales como siguiente fase — muestra sensibilidad cultural real sin comprometerse a algo inviable en el tiempo del hackathon.

---

## 6. Diferenciación frente a AJAM (criterio de innovación)

- **Protección del informante:** no exige identidad ni documento escaneado, a diferencia del formulario oficial.
- **Offline-first real:** funciona sin señal en zonas remotas del río.
- **Análisis automático:** calcula impacto (mercurio), verifica zona protegida y cita normativa — el informante no necesita saber redactar una denuncia técnica.
- **Visibilidad acumulada:** dashboard con patrones para la organización, algo que el canal oficial no ofrece.
- **Modelo gradual de exposición:** el informante decide su nivel de anonimato, no es "todo o nada".

Idea a futuro: el reporte generado podría pre-llenar los datos del formulario oficial de AJAM (excepto identidad), alimentando el canal oficial con mejor evidencia sin reemplazarlo.

---

## 7. Prompts de mockup (para generación de UI)

**Pantalla de inicio (app monitor):**
```
Diseña la pantalla de inicio de una app mobile para monitores comunitarios que denuncian minería ilegal en ríos de Bolivia. Debe verse simple y robusta para uso en campo con poca señal. Incluye: un botón grande y prominente "Nuevo registro" (ícono de cámara), una lista debajo con los últimos registros hechos por el usuario (miniatura de foto + fecha + estado: "pendiente de sincronizar" o "sincronizado"), y un indicador pequeño arriba mostrando el estado de conexión (offline/online). Paleta de colores con buen contraste para uso bajo luz solar directa, tipografía grande, botones táctiles amplios.
```

**Captura de evidencia (a distancia segura):**
```
Diseña la pantalla de captura de evidencia de una app de denuncia de minería ilegal, pensada para fotografiar una operación activa a distancia segura, sin necesidad de acercamiento físico. Debe mostrar la cámara activa ocupando la mayor parte de la pantalla, un control de zoom visible y fácil de usar con el pulgar, un botón circular grande para tomar la foto, y en la parte inferior un chip/etiqueta mostrando la ubicación GPS capturada automáticamente (latitud/longitud + ícono de pin) con un mensaje "Ubicación detectada automáticamente". Incluye un botón secundario "Adjuntar otra foto" y un botón principal "Continuar". Diseño minimalista, alto contraste, sin distracciones.
```

**Estimación de actividad:**
```
Diseña un formulario mobile corto de 4 preguntas, no un chat, para estimar el impacto de una draga de minería ilegal detectada desde una distancia segura. Pregunta 1: tamaño aproximado de la draga (opciones tipo tarjeta seleccionable: Pequeña / Mediana / Grande, con íconos ilustrativos). Pregunta 2: tiempo estimado que lleva operando en la zona (slider o botones: Menos de 1 día / Varios días / Más de una semana). Pregunta 3: indicadores visibles a distancia (checkboxes: Varias personas visibles / Motobombas o mangueras visibles). Pregunta 4: campo de texto opcional para notas adicionales. Botón final "Generar reporte". Usa componentes grandes, selección con un solo toque.
```

**Confirmación y resultado del reporte:**
```
Diseña la pantalla de resultado después de generar un reporte de denuncia de minería ilegal. Debe mostrar de forma visual y clara: un indicador de nivel de impacto estimado (ej. barra o medidor de "mercurio estimado liberado"), un sello o etiqueta si la ubicación cae dentro de zona protegida o territorio indígena, y un resumen breve de la normativa citada. Incluye un paso opcional para dejar un dato de contacto ("¿Quieres dejar un contacto por si la organización necesita más información?" con botón de "Omitir" igual de visible que "Continuar"). Botones: "Descargar reporte PDF" y "Enviar a mi organización". Tono visual serio pero no alarmista.
```

**Dashboard de la organización:**
```
Diseña un dashboard web para una organización territorial/ambiental que recibe reportes de denuncias de minería ilegal en ríos. Incluye: un mapa central con puntos marcando cada denuncia registrada (color según nivel de impacto), una barra lateral con filtros (por fecha, por zona, por nivel de riesgo), tarjetas resumen arriba con métricas clave (total de denuncias, mercurio estimado acumulado, zonas protegidas afectadas), y una tabla o lista de denuncias recientes debajo del mapa. Diseño limpio tipo dashboard profesional.
```

**Chat del panel (consulta sobre los datos):**
```
Diseña un panel de chat lateral o flotante dentro del dashboard de la organización, donde el usuario puede escribirle preguntas a un asistente sobre los datos acumulados de denuncias (ej. "¿qué zona tuvo más denuncias este mes?"). Debe verse integrado al dashboard, no como una app de mensajería genérica — con sugerencias de preguntas rápidas como chips clickeables arriba del campo de texto, y las respuestas del asistente pudiendo incluir mini-gráficos o referencias a denuncias específicas dentro de la conversación.
```

---

## 8. Criterios de evaluación del hackathon (referencia)

| Criterio | Peso | Cómo lo cubre Colmena |
|---|---|---|
| Impacto tecnológico | 30% | Resuelve un problema real y desatendido: protección del informante + automatización del análisis de impacto ambiental |
| Innovación | 30% | No existe una herramienta similar de monitoreo continuo comunitario con cálculo automático vía LLM, frente al formulario estático de AJAM |
| Software funcional y entregables | 30% | Repositorio + demo en línea + video — priorizar MVP funcional de punta a punta |
| Uso de AWS y Kiro | 10% | Evidenciado en la arquitectura (agente + MCP) |

---

## 9. Ecosistema de actores (contexto, no integración funcional)

Aunque el sistema solo interactúa directamente con la Abeja y la Colmena, es útil mostrar el ecosistema completo en la presentación para transmitir que el proyecto entiende el terreno institucional en el que se inserta:

```
Abeja ──► Colmena ──► AJAM (canal oficial de denuncia)
                  ├──► SERNAP (áreas protegidas)
                  ├──► Defensoría del Pueblo
                  ├──► Fiscalía Ambiental
                  └──► Organizaciones de pueblos indígenas
```

Colmena no reemplaza a ninguno de estos actores — mejora la calidad de la evidencia que eventualmente llega a ellos.

## 10. Métricas del dashboard

Además del mapa y la tabla de denuncias, el dashboard debe mostrar indicadores acumulados:
- Denuncias registradas por mes.
- Mercurio estimado acumulado (total).
- Zonas protegidas / territorios indígenas afectados.
- Porcentaje de denuncias anónimas vs. con contacto.
- Evolución temporal de denuncias por zona.

## 11. Riesgos identificados

| Riesgo | Mitigación considerada |
|---|---|
| GPS impreciso o sin señal satelital | Guardar coordenada con margen de error declarado; permitir corrección manual en el mapa si es necesario |
| Fotos falsas, recicladas o duplicadas | Verificación de EXIF en el dispositivo antes de subir (fecha, consistencia de ubicación) |
| Denuncias maliciosas o infundadas | Estado de revisión en el dashboard (nuevo/revisado/escalado) antes de que la Colmena actúe sobre un reporte |
| Ausencia de conexión por varios días | Cola de sincronización local robusta, sin límite estricto de tiempo de espera |
| Exposición de datos del denunciante | Datos de contacto opcionales; limpieza de metadata de dispositivo antes de subir la foto |
| **Riesgo físico del monitor al acercarse a una operación activa** | La app está diseñada para captura a distancia (zoom, no acercamiento); el formulario solo pide indicadores observables sin necesidad de confirmar datos exactos in situ |
| **Precisión limitada de la estimación de mercurio** | El resultado siempre se presenta como estimación, con nota de metodología visible en el reporte — nunca como medición exacta de laboratorio |

## 12. Servicios de AWS (uso concreto, no solo mencionado)

| Servicio AWS | Uso en Colmena |
|---|---|
| **S3** | Almacenamiento de fotografías y PDFs generados |
| **RDS (PostgreSQL + PostGIS)** | Base de datos de reportes y consultas geoespaciales |
| **Lambda** *(si el tiempo alcanza)* | Procesamiento asíncrono de sincronización y generación de PDF |
| **Bedrock** *(opcional)* | Alternativa a la API de Claude directa — evaluar según tiempo disponible; si no se usa, documentar la decisión en el README |

## 13. Roadmap priorizado para el hackathon

🔴 **Crítico — hacer primero**
- Algoritmo determinístico para el cálculo de mercurio (no LLM)
- Reencuadrar la tool de precios como estimación económica del daño
- Base de datos explícita (Postgres + PostGIS) en la arquitectura y el código
- Desplegar usando al menos S3 y RDS de forma real
- Flujo E2E completo funcionando: foto → sincronización → agente/MCP → dashboard → PDF

🟡 **Rápido, alto valor para el jurado**
- Sección de riesgos y ecosistema de actores en el README/pitch
- 3-4 métricas clave en el dashboard
- Estado simple del reporte (nuevo/revisado/escalado)

⚪ **Dejar como trabajo futuro (mencionar, no construir)**
- Flujo completo de validación → priorización → escalamiento → seguimiento
- Búsqueda semántica avanzada para el chat del dashboard
- Modo ráfaga de fotos / selección desde galería
