# Pruebas manuales — Fase 1

Última actualización: 2026-09-29. Las pruebas marcadas ⏳ requieren a una persona frente a la Mac.

Correr después de `make install`. Anotar fecha, versión de macOS y resultado de cada punto.

| # | Prueba | Cómo | Esperado | Resultado |
|---|---|---|---|---|
| 1 | Arranque | Abrir Clawd.app | Cae en el monitor más grande y aterriza | ✅ 2026-09-29 (solo MacBook): aparece cayendo y aterriza en el piso. |
| 2 | Vida propia | Dejarlo 10 min | Camina, mira, cocina, trepa, se sienta, hamaca; no repite dos veces seguidas | 🟡 Parcial: se le vio trepar la pared derecha y sentarse en la repisa de la esquina; falta observar 10 min completos. |
| 3 | Fantasma | Acercar el mouse en el piso, la pared y la esquina | Se vuelve semitransparente, los clicks pasan, se hace a un lado | ⏳ Pendiente (Santiago) |
| 4 | Sin parpadeo | Dejar el mouse a ~60 pt de él | Se queda fantasma, no parpadea | ⏳ Pendiente (Santiago) |
| 5 | Zona caliente | Espantarlo 3 veces seguidas en la esquina | Deja la esquina un rato | ⏳ Pendiente (Santiago) |
| 6 | ⌥ click | ⌥ + click sobre Clawd (piso y esquina) | Saluda (desde la esquina: baja y saluda) | ⏳ Pendiente (Santiago) |
| 7 | Foco | ⌥ click mientras escribes en otra app | La otra app no pierde el foco | ⏳ Pendiente (Santiago) |
| 8 | ⌥ arrastrar | Cargarlo y soltarlo en el otro monitor | Cae y aterriza ahí | ⏳ Pendiente (Santiago) |
| 9 | Monitores | Desconectar y reconectar el externo | Se muda a la MacBook y luego regresa a casa | ⏳ Pendiente (Santiago) |
| 10 | Resolución | Cambiar la escala de la pantalla | Se reacomoda sin quedar fuera | ⏳ Pendiente (Santiago) |
| 11 | Sueño de la Mac | Dormir la Mac 1 min y despertarla | No sale disparado, sigue donde estaba | ⏳ Pendiente (Santiago) |
| 12 | Bloqueo | Bloquear la pantalla 1 min | El bucle se pausa (CPU ~0 %) y reanuda | ⏳ Pendiente (Santiago) |
| 13 | Inactividad | No tocar nada 5 min | Se duerme; al mover el mouse despierta | ⏳ Pendiente (Santiago) |
| 14 | Compartir pantalla | Compartir pantalla en Meet/Zoom y grabar con ⌘⇧5, con "Ocultar al compartir" activo | Clawd no aparece (anotar qué herramientas sí lo muestran) | 🟡 Parcial: con el ajuste activo, `screencapture` no lo captura. Falta probar Meet/Zoom y ⌘⇧5. |
| 15 | Atajo | ⌃⌥⌘C desde otra app | Lo esconde y lo muestra | ⏳ Pendiente (Santiago) |
| 16 | Inicio de sesión | Activar, cerrar sesión y volver a entrar | Clawd arranca solo | ⏳ Pendiente (Santiago) |
| 17 | Una sola instancia | Abrir Clawd.app dos veces | Solo hay un Clawd | ✅ 2026-09-29: se lanzó una segunda copia; se cerró sola automáticamente. Solo 1 instancia permanece. |
| 18 | Consumo | Monitor de Actividad, 5 min en reposo | CPU < 1 % en promedio | ✅ 0.92 % CPU en reposo (muestra de 10 s) |
