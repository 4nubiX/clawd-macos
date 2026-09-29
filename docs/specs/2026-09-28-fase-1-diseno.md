# Clawd para macOS — Diseño de la Fase 1: "Clawd vive"

- **Fecha:** 2026-09-28
- **Estado:** Diseño aprobado, pendiente de plan de implementación
- **Plataforma:** solo macOS 14 (Sonoma) o superior
- **Autores:** Santiago H. ([@4nubiX](https://github.com/4nubiX)) con Claude (Anthropic)

> Proyecto de fans, no oficial. Clawd y Claude son marcas de Anthropic. Ver el
> [aviso en el README](../../README.md#aviso-legal).

---

## 1. Contexto y objetivo

Clawd es la mascota en pixel art de Claude Code. Este proyecto la convierte en una
**mascota de escritorio nativa para macOS**: un bichito que vive encima de tus
ventanas, camina, trepa, se cuelga en una hamaca, cocina y duerme, sin estorbarte
nunca.

El proyecto completo tiene cuatro fases. **Este documento solo cubre la Fase 1.**

| Fase | Nombre | Qué incluye |
|---|---|---|
| **1** | **Clawd vive** | Mascota autónoma: zonas, animaciones, esquivar el mouse, varios monitores, barra de menú |
| 2 | Clawd te acompaña | Reacciona a Claude Code vía *hooks* (trabajando, pide permiso, terminó, error) |
| 3 | La casa de Clawd | Ventana propia con escenas ASCII estilo Claude FM, actividades y modo chill |
| 4 | Extras | Más actividades, temporadas, ideas nuevas |

### Criterios de éxito de la Fase 1

1. Clawd vive en tu escritorio de forma autónoma y se siente "vivo": variado, sin repetirse, con personalidad.
2. **Nunca te cuesta un click**: jamás bloquea un botón, un scroll ni el foco del teclado.
3. Sobrevive sin romperse a: conectar o desconectar monitores, cambiar resolución, dormir la Mac y bloquear la pantalla.
4. Gasta muy poca batería y CPU.
5. **No pide ningún permiso de macOS** (salvo, quizá, el sub-paso de ventanas no maximizadas; ver §7.4).

### Fuera de alcance (Fase 1)

- Cualquier integración con Claude Code (Fase 2).
- La ventana "casa" y el modo chill (Fase 3).
- Soporte para Windows o Linux. **Es solo para Mac, por diseño.**

---

## 2. Decisiones tomadas (y por qué)

| Decisión | Elegido | Alternativas descartadas | Razón |
|---|---|---|---|
| Tecnología | **Swift nativo** (AppKit + SwiftUI) | Tauri, Electron | Pesa pocos MB y tiene control total de ventanas y pantallas. Electron gastaría ~150 MB de RAM para un bichito. |
| Formato del proyecto | **Swift Package + script de empaquetado** | `.xcodeproj` | Es texto plano y legible en git, se compila y prueba desde la terminal, y Xcode lo abre igual. |
| Dónde camina | **Piso + esquina superior derecha + lado derecho + hamaca en bordes** | Solo piso, flotar libre | Presente sin estorbar. El usuario tiene el Dock oculto y usa las ventanas maximizadas (no en pantalla completa nativa). |
| Interacción con el mouse | **Fantasma + se hace a un lado + ⌥ click / ⌥ arrastrar** | Solo esquivar, solo fantasma | Nunca bloquea clicks y aun así puedes jugar con él. |
| Tamaño | **Mediano (~80 pt) por defecto**, ajustable a chico o grande | Tamaño fijo | Se nota sin estorbar. El pixel art escala perfecto en múltiplos enteros. |
| Monitores | **Vive en el más grande**, se pasea y va a buscarte cuando te necesita (Fase 2) | Fijo, seguir al mouse | Balance entre tener una "casa" estable y estar presente. |
| Arte | **Sprites definidos como texto en el repo**, dibujados desde cero | PNG hechos a mano, sprites de la comunidad | Editables, revisables en git y sin problemas de licencia de terceros. Se deja la puerta abierta a PNG. |

---

## 3. Arquitectura

### 3.1 Estructura del repositorio

```
clawd-macos/
├── Package.swift                 # Definición del proyecto (SwiftPM)
├── Makefile                      # make app · make run · make test · make preview
├── Sources/
│   ├── ClawdCore/                # EL CEREBRO: lógica pura, sin AppKit, 100% testeable
│   │   ├── Sprites/              #   parser de sprites en texto → cuadros
│   │   ├── Brain/                #   máquina de estados, decisiones, interrupciones
│   │   └── World/                #   geometría: pantallas, zonas, rutas entre monitores
│   ├── ClawdApp/                 # EL CUERPO: todo lo que toca macOS
│   │   ├── PetWindow/            #   panel transparente + dibujado
│   │   ├── Input/                #   mouse, ⌥, inactividad
│   │   ├── System/               #   eventos de pantallas, sueño y bloqueo
│   │   └── MenuBar/              #   icono y menú
│   └── ClawdPreview/             # Herramienta CLI: genera la hoja de vista previa (PNG)
├── Resources/
│   ├── Sprites/*.txt             # Una animación por archivo
│   └── Info.plist                # Metadatos del .app (LSUIElement = sin icono en el Dock)
├── Tests/ClawdCoreTests/
└── docs/
```

### 3.2 Separación cerebro / cuerpo

```
         ┌────────────── cada tick ──────────────┐
         │                                       ▼
┌─────────────────┐   WorldSnapshot    ┌──────────────────┐
│    ClawdApp     │ ─────────────────► │    ClawdCore     │
│   (el cuerpo)   │                    │   (el cerebro)   │
│                 │ ◄───────────────── │                  │
│ ventana, mouse, │   PetRenderState   │ estados, zonas,  │
│ pantallas, menú │                    │ decisiones       │
└─────────────────┘                    └──────────────────┘
```

- **`WorldSnapshot`** (entrada): pantallas (marco y área útil), posición del mouse, si ⌥ está presionado, si hay un arrastre en curso, segundos de inactividad, delta de tiempo y ajustes (tamaño, pausado).
- **`PetRenderState`** (salida): posición en coordenadas globales, animación y cuadro actual, dirección (izquierda/derecha), opacidad (fantasma) y si la ventana debe aceptar clicks.

**Por qué:** el cerebro no sabe nada de ventanas y el cuerpo no toma decisiones. Así
toda la lógica difícil se prueba con tests automáticos, sin abrir ventanas, y si algo
se ve mal sabes enseguida si es un problema de lógica o de dibujo.

### 3.3 Bucle de actualización

- Un timer en el hilo principal llama a `brain.tick(snapshot)` y aplica el resultado.
- **Frecuencia adaptativa** para cuidar la batería:
  - 30 fps mientras Clawd se mueve (caminar, trepar, caer, ser arrastrado).
  - ~8 fps cuando está quieto.
  - ~2 fps dormido.
  - **0 fps** con la pantalla bloqueada o las pantallas dormidas.
- El delta de tiempo **se limita a 0.1 s por tick**, para que al despertar la Mac Clawd no salga disparado.

---

## 4. El cerebro (`ClawdCore/Brain`)

### 4.1 Lugares y transiciones

```
        ┌──────── esquina sup. der. ────────┐
        │  (sentado · hamaca · dormir)      │
        │           ↑ trepar     ↓ caer     │
        │      pared derecha                │
        │           ↑ trepar                │
   piso ←──────────── caminar ─────────────→┘
   (idle · mirar · cocinar · dormir)
```

| Lugar | Actividades posibles | Sale hacia |
|---|---|---|
| Piso | idle, mirar alrededor, caminar, cocinar, dormir | pared derecha (trepar), otro monitor (caminar) |
| Pared derecha | trepar (subir/bajar) | esquina, piso (caer) |
| Esquina sup. der. | sentado, hamaca, dormir | pared (bajar), piso (caer) |
| Cualquiera | saludar, esquivar, ser arrastrado, caer | — |

Todas las posiciones se calculan sobre el **área útil** de cada pantalla (`visibleFrame`),
que ya descuenta la barra de menú y el Dock. La barra de menú de la MacBook, más alta
por el notch, y la del monitor externo se manejan solas.

### 4.2 Cómo elige qué hacer

- Cuando una actividad termina, elige la siguiente **al azar con pesos**, solo entre las válidas en su lugar actual.
- Los pesos favorecen **la esquina superior derecha y el lado derecho**.
- Cada actividad tiene una duración aleatoria dentro de un rango (sentado 20 s–2 min, cocinar ~15 s, etc.).
- **Anti-repetición:** nunca repite la misma actividad dos veces seguidas. Las especiales (cocinar, hamaca) tienen un tiempo de espera antes de volver a salir.
- El azar usa un generador con **semilla inyectable**: en los tests es determinista.

### 4.3 Interrupciones (de mayor a menor prioridad)

1. **Cambio de pantallas** (monitor desconectado, resolución, reacomodo): se reubica de inmediato.
2. **Arrastre con ⌥:** lo cargas; al soltarlo, cae.
3. **Mouse cerca:** modo fantasma y luego se hace a un lado (§4.4).
4. **⌥ click:** saluda.
5. **Reservado para la Fase 2:** "Claude necesita tu atención". Despierta a Clawd aunque esté dormido y lo lleva a la pantalla donde estás.
6. **Inactividad** (5 min por defecto, configurable): se duerme donde esté. Al moverte, despierta.

### 4.4 Esquivar el mouse (sin estorbar nunca)

- **Histéresis:** entra en modo fantasma cuando el cursor está a **≤ 40 pt**. Solo vuelve a la normalidad cuando el cursor está a **> 80 pt** y ha pasado **≥ 1 s**. Esto evita el parpadeo cuando el mouse se queda justo en el límite.
- **Fantasma:** 30 % de opacidad con fundido de 150 ms. La ventana deja pasar los clicks.
- **Hacerse a un lado:** después de volverse fantasma, camina a una posición libre **dentro de su zona válida**. Si no la hay (por ejemplo, a media caída), solo se queda fantasma.
- **Zonas calientes:** si lo espantan **3 veces en pocos minutos** en la misma zona, la marca como "caliente" y se va a otra zona un rato. Las zonas calientes se enfrían con el tiempo.

### 4.5 Varios monitores

- **Casa = el monitor más grande**, medido en puntos de su área útil. En el setup actual es el externo de 1080p.
- **Paseos ocasionales** a otros monitores caminando por el piso.
- **Cruce:** si las pantallas se tocan por el borde a la altura del piso, camina de una a otra y, si el piso de la otra queda más abajo, se deja caer. Si no se tocan a esa altura, **aparece cayendo desde arriba** en la otra pantalla.
- Si desconectas el monitor, se muda a la pantalla que quede. Al reconectarlo, regresa caminando a casa.

### 4.6 Blindaje

| Riesgo | Prevención |
|---|---|
| Esquiva sin parar en su esquina favorita | Zonas calientes (§4.4) |
| Parpadeo fantasma/normal | Histéresis 40/80 pt + 1 s |
| Salto al despertar la Mac | Delta máximo 0.1 s por tick + revalidar posición |
| Queda fuera de pantalla | Validación en cada tick y en cada cambio de pantallas → cae en una pantalla válida |
| Estado atorado por un bug | Cada actividad tiene duración máxima; un "perro guardián" lo regresa a idle y lo registra en el log |
| Repetitivo o aburrido | Anti-repetición + tiempos de espera |
| Consumo de batería | Frecuencia adaptativa (§3.3) + ventana pequeña |

---

## 5. Sprites (`ClawdCore/Sprites` + `Resources/Sprites`)

### 5.1 Formato

Una animación por archivo de texto:

```
fps: 8
repetir: si
ancla: 8,8
paleta: O=#D97757 o=#B85C3E K=#1A1A1A

--- cuadro 1
..OOOOOOOOOOOO..
..OOOOOOOOOOOO..
..OOKOOOOOOKOO..
OOOOKOOOOOOKOOOO
OOOOOOOOOOOOOOOO
..OOOOOOOOOOOO..
..oooooooooooo..
...O.O....O.O...
...O.O....O.O...
--- cuadro 2
...
```

- Cada carácter es un pixel. `.` es transparente y las demás letras se mapean en `paleta`.
- **`ancla`:** el pixel que "pisa" el piso, o del que cuelga en la hamaca. Mantiene alineadas las transiciones entre animaciones.
- **Paleta base:** terracota `#D97757`, sombra `#B85C3E`, ojos `#1A1A1A`, más colores de objetos (sartén, hamaca, "Zzz"…).
- Solo se dibuja a **Clawd mirando a la derecha**. La izquierda es un espejo.

### 5.2 Animaciones de la Fase 1 (11)

| # | Animación | Cuándo |
|---|---|---|
| 1 | Idle | Quieto: respira y parpadea |
| 2 | Caminar | Por el piso o entre monitores |
| 3 | Mirar alrededor | Pausa curiosa, voltea a los lados |
| 4 | Trepar | Subir y bajar por la pared derecha |
| 5 | Sentado en la esquina | Esquina superior derecha, patitas colgando |
| 6 | Hamaca | Colgado del borde superior, meciéndose |
| 7 | Caer y aterrizar | Bajar de la esquina, al soltarlo o al cambiar de monitor (con "aplastadito") |
| 8 | Saludar | ⌥ click |
| 9 | Esquivar | Brinquito cuando se acerca el mouse |
| 10 | Dormir | Por inactividad, con "Zzz" |
| 11 | Cocinar | En el piso con su sartén, volteando un huevo |

### 5.3 Dibujado

- Al arrancar, cada cuadro se convierte **una sola vez** en `CGImage` y queda en caché.
- Se escala con **vecino más cercano** (sin suavizado) y **solo en múltiplos enteros**: 1 pixel del sprite = **3, 5 u 8 pt** (chico ≈ 48, mediano ≈ 80, grande ≈ 128).
- La ventana cambia de tamaño según la animación y se posiciona usando el ancla.

### 5.4 Validación

- **Test automático:** carga todas las animaciones y falla si hay una letra sin color en la paleta, cuadros de distinto tamaño, falta el ancla o está fuera del cuadro.
- **En tiempo de ejecución:** si un archivo viene roto, la app **no se cae**. Esa animación se reemplaza por idle y el error se registra con archivo y línea.

### 5.5 Vista previa

`make preview` genera `build/preview.png`, una hoja con todas las animaciones cuadro por
cuadro. Sirve para revisar el pixel art sin correr la app.

### 5.6 Puerta abierta a PNG

El motor obtiene las animaciones a través del protocolo `SpriteSource`. La primera
implementación lee `.txt`. Una futura puede leer spritesheets PNG exportados de
Aseprite sin tocar el resto del código.

---

## 6. El cuerpo (`ClawdApp`)

### 6.1 Ventana

- `NSPanel` sin bordes, **no activable** (un click nunca le quita el foco del teclado a tu app), fondo transparente y sin sombra.
- Nivel flotante: encima de las ventanas normales.
- Comportamiento: aparece en **todos los escritorios (Spaces)**, estacionario (no aparece en Mission Control), fuera del ciclo de ventanas y compatible con apps en pantalla completa.
- `ignoresMouseEvents = true` por defecto, así que los clicks lo atraviesan.
- `LSUIElement = true`: sin icono en el Dock ni en ⌘Tab.

### 6.2 Entrada (sin permisos de macOS)

- **Posición del mouse:** `NSEvent.mouseLocation` en cada tick.
- **⌥:** `NSEvent.modifierFlags` en cada tick.
- **Aceptar clicks:** solo cuando ⌥ está presionado **y** el cursor está sobre un **pixel opaco** de Clawd. En ese caso `ignoresMouseEvents = false`.
- **⌥ click** → saluda. **⌥ arrastrar** → lo cargas; al soltar, cae.
- **Inactividad:** `CGEventSource.secondsSinceLastEventType`.

### 6.3 Eventos del sistema

- `NSApplication.didChangeScreenParametersNotification` → revalidar pantallas y posición.
- `NSWorkspace.didWakeNotification` → revalidar.
- Bloqueo y desbloqueo de pantalla (`com.apple.screenIsLocked` / `screenIsUnlocked`) → pausar y reanudar.
- Pantallas dormidas y despiertas → pausar y reanudar.

### 6.4 Barra de menú

Icono de Clawd en pixel art con el menú:

- Tamaño: Chico / **Mediano** / Grande
- Esconder / Mostrar Clawd (con atajo de teclado global)
- Dormir ahora / Despertar
- ✓ Ocultar al compartir pantalla
- ✓ Abrir al iniciar sesión
- Salir

Las preferencias se guardan en `UserDefaults`.

### 6.5 Una sola instancia

Si se abre la app dos veces, la segunda detecta a la primera y se cierra.

---

## 7. Riesgos conocidos y cómo se atienden

### 7.1 Aparecer al compartir pantalla o grabar
Se usa `NSWindow.sharingType = .none` para excluir la ventana de las capturas. **A
verificar:** hay reportes de que algunas herramientas de captura recientes no lo
respetan. **Plan B garantizado:** el atajo global para esconder a Clawd al instante.

### 7.2 "Abrir al iniciar sesión"
Primer intento: `SMAppService.mainApp`. Puede fallar con apps firmadas localmente,
sin cuenta de desarrollador de Apple. **Plan B:** un `LaunchAgent` en
`~/Library/LaunchAgents`.

### 7.3 Cosas que lo taparán un momento (aceptado)
- Las **notificaciones de macOS**, que salen arriba a la derecha.
- El **Dock oculto** cuando lo muestras.

Detectarlas requeriría permisos o trucos frágiles, así que no vale la pena.

### 7.4 Colgarse de ventanas no maximizadas (sub-paso final de la Fase 1)
Idea: leer la posición de las ventanas con `CGWindowListCopyWindowInfo` para colgar la
hamaca del borde superior de una ventana que no está maximizada, moverse con ella y caer
si se cierra. **A verificar antes de construir:** que leer las posiciones no pida permiso
de grabación de pantalla (se cree que solo los *nombres* de ventana lo requieren). Si sí
lo pide, se consulta al usuario antes de implementarlo.

---

## 8. Pruebas y manejo de errores

### 8.1 Automáticas (`swift test`, solo `ClawdCore`)
- Máquina de estados: transiciones válidas, duraciones, anti-repetición y perro guardián.
- Fantasma: histéresis 40/80 pt + 1 s.
- Zonas calientes: se marcan y se enfrían.
- Monitores: elección del más grande, cruce entre pantallas y reubicación al desconectar.
- Blindaje: delta máximo, posición fuera de pantalla → recuperación.
- Sprites: todos los archivos del repo son válidos.

### 8.2 Manuales (checklist en la Mac)
- Mover el mouse hacia Clawd en cada zona.
- ⌥ click y ⌥ arrastrar.
- Desconectar y reconectar el monitor externo.
- Cambiar la resolución.
- Dormir la Mac y bloquear la pantalla.
- Compartir pantalla en una videollamada con "Ocultar al compartir" activado.
- Revisar el consumo en el Monitor de Actividad (objetivo: CPU < 1 % en reposo).

### 8.3 Errores
- Nunca se silencian. Todo va a `os.Logger` (subsistema `com.4nubix.clawd`) con contexto suficiente para diagnosticar.
- Se consulta en `Console.app` filtrando por "Clawd".

---

## 9. Preparación para las siguientes fases

- **Fase 2:** la prioridad de interrupción #5 ya existe. El cuerpo tendrá una entrada de "eventos externos" que la Fase 2 alimentará desde un pequeño servidor en `127.0.0.1` al que llamarán los *hooks* de Claude Code.
- **Fase 3:** las actividades y escenas se diseñan de forma que puedan reusarse dentro de la ventana "casa".
