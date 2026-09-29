# Clawd para macOS 🦀

> Una mascota de escritorio **nativa para Mac** de Clawd, el bichito en pixel art de
> Claude Code. Vive encima de tus ventanas, camina, trepa, se cuelga en una hamaca,
> cocina y duerme… **sin estorbarte nunca.**

![Plataforma](https://img.shields.io/badge/plataforma-macOS%2014%2B-lightgrey)
![Swift](https://img.shields.io/badge/Swift-6-orange)
![Estado](https://img.shields.io/badge/estado-fase%201-green)
![Licencia](https://img.shields.io/badge/licencia-MIT-blue)

**🍎 Solo para macOS.** No hay versión para Windows ni para Linux, y no está planeada.
Está hecha a propósito en Swift nativo para aprovechar macOS al máximo y gastar lo
mínimo de batería.

> 🇬🇧 **English summary:** Unofficial, community-made **macOS-only** desktop pet of
> Clawd, the Claude Code mascot. Native Swift, no permissions required, no network
> access, no telemetry. It walks, climbs, hangs in a hammock, cooks and sleeps on
> your desktop and always gets out of your mouse's way. **Status: design phase —
> no runnable code yet.** Docs are in Spanish; issues and PRs in English are welcome.

---

## 🚧 Estado actual

- ✅ **Fase 1 ("Clawd vive")**: implementada (falta terminar las pruebas manuales). Ver [diseño](docs/specs/2026-09-28-fase-1-diseno.md), [plan](docs/plans/2026-09-29-fase-1-plan.md) y [pruebas manuales](docs/pruebas-manuales.md).
- ⏳ Fase 2: reaccionar a Claude Code.

Por ahora no hay descargas firmadas: se compila desde el código (es rápido, ver abajo).

---

## ✨ Qué hace

### Fase 1: "Clawd vive" (en diseño)

- **Vive donde no estorba:** en el piso de la pantalla, en la esquina superior derecha, trepando por el lado derecho o colgado en una hamaca del borde de arriba.
- **Nunca te cuesta un click:** cuando acercas el mouse se vuelve **fantasma** (semitransparente y los clicks lo atraviesan) y luego se hace a un lado. Si lo espantas mucho de un lugar, aprende a evitarlo.
- **Juega contigo:** **⌥ + click** para que te salude y **⌥ + arrastrar** para cargarlo y soltarlo.
- **11 animaciones:** idle, caminar, mirar alrededor, trepar, sentado, hamaca, caer, saludar, esquivar, dormir y **cocinar** 🍳.
- **Varios monitores:** vive en el más grande, se pasea a los demás y, si desconectas uno, se muda solito.
- **Se duerme** cuando no usas la Mac y despierta cuando regresas.
- **Icono en la barra de menú:** tamaño (chico, mediano o grande), esconderlo, dormirlo, ocultarlo al compartir pantalla y abrir al iniciar sesión.

### Lo que viene

| Fase | Nombre | Qué agrega |
|---|---|---|
| 2 | **Clawd te acompaña** | Reacciona a **Claude Code** en tiempo real: se pone a teclear cuando Claude trabaja, **te avisa cuando Claude necesita tu permiso** y celebra cuando termina. |
| 3 | **La casa de Clawd** | Una ventana propia con paisajes en arte ASCII, inspirada en *Claude FM*, donde Clawd cocina, pilota, navega… con modo chill y música lofi. |
| 4 | **Extras** | Más actividades, eventos de temporada y lo que proponga la comunidad. |

---

## 🧠 Cómo funciona

La app está dividida en dos partes que no se mezclan:

```
┌─────────────────┐   "foto" del mundo      ┌──────────────────┐
│   ClawdApp      │ ──────────────────────► │   ClawdCore      │
│   (el cuerpo)   │   pantallas, mouse, ⌥,  │   (el cerebro)   │
│                 │   inactividad           │                  │
│ ventana, mouse, │ ◄────────────────────── │ máquina de       │
│ barra de menú   │   dónde está, qué cuadro│ estados, zonas,  │
│                 │   dibujar, ¿fantasma?   │ decisiones       │
└─────────────────┘                         └──────────────────┘
```

- **El cerebro (`ClawdCore`)** es lógica pura: decide qué hace Clawd, a dónde va y cuándo esquiva. Como no toca la pantalla, se prueba con tests automáticos.
- **El cuerpo (`ClawdApp`)** es la ventana transparente que dibuja a Clawd, lee el mouse y maneja la barra de menú. Solo obedece al cerebro.
- **Los sprites son texto.** Cada animación es un archivo donde cada letra es un pixel (`O` = naranja, `K` = ojos, `.` = transparente). Se pueden editar con cualquier editor y en git se ve exactamente qué pixel cambió.

Todos los detalles (zonas, prioridades, cómo evita estorbar y cómo sobrevive a cambios
de monitor) están en el [documento de diseño](docs/specs/2026-09-28-fase-1-diseno.md).

---

## 🔒 Privacidad y permisos

- **No pide permisos de macOS** para funcionar. No necesita Accesibilidad ni Grabación de pantalla.
- **Sin internet:** la Fase 1 no se conecta a nada.
- **Sin telemetría:** no recopila ni envía ningún dato.
- **Fase 2:** la integración con Claude Code funcionará **solo en tu Mac** (`127.0.0.1`), mediante los *hooks* oficiales de Claude Code, que tú configuras.

---

## 💻 Compilar e instalar

Requisitos: macOS 14 (Sonoma) o superior y Xcode 16+ (o las Command Line Tools con Swift 6).

    git clone https://github.com/4nubiX/clawd-macos.git
    cd clawd-macos
    make test      # corre los tests del cerebro
    make install   # compila, arma Clawd.app, lo copia a /Applications y lo abre

Otros comandos: `make dev` (correr sin empaquetar), `make run` (armar y abrir desde `build/`),
`make preview` (hoja PNG con todas las animaciones en `build/preview.png`).

**Uso:** Clawd vive solo. Acerca el mouse y se hace a un lado. **⌥ + click** para que salude,
**⌥ + arrastrar** para cargarlo. **⌃⌥⌘C** lo esconde o lo muestra. El resto está en su icono de la barra de menú.

**Logs:** `log stream --predicate 'subsystem == "com.4nubix.clawd"'` o Console.app filtrando por "Clawd".

---

## 🤝 Contribuir

Todavía estamos en diseño, pero ya puedes aportar:

- **Ideas de animaciones o actividades:** abre un *issue*.
- **Comentarios al diseño:** lee el [documento de diseño](docs/specs/2026-09-28-fase-1-diseno.md) y abre un *issue* si ves algún hueco.
- **Pixel art:** cuando exista el formato de sprites, las nuevas animaciones serán bienvenidas.

---

## ⚖️ Aviso legal

**Este es un proyecto de fans, no oficial.** No está afiliado, patrocinado ni respaldado
por Anthropic.

- *Claude*, *Claude Code* y el personaje *Clawd* son marcas y propiedad de **Anthropic, PBC**.
- El pixel art de este repositorio está dibujado desde cero como **fan art**, inspirado en el personaje. No se usan recursos oficiales de Anthropic.
- Es un proyecto **gratuito y sin fines de lucro**. No lo vendas ni lo redistribuyas como producto comercial.
- Si Anthropic pide cambios o que se retire el proyecto, se atenderá de inmediato.

La **licencia MIT** cubre el **código fuente**. No otorga ningún derecho sobre las marcas
ni sobre el personaje de Anthropic.

---

## 📄 Licencia

Código bajo licencia [MIT](LICENSE).

Hecho con 🧡 por [Santiago H. (@4nubiX)](https://github.com/4nubiX), diseñado en
conjunto con Claude.
