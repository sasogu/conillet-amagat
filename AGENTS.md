# AGENTS.md — Conillet amagat

Puzle de lógica de conejos para Android (Flutter). Interfaz en castellano y
valenciano. Licencia GPL-3.0-or-later.

## Comandos

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build apk --release`

Ejecutar `flutter analyze` y `flutter test` antes de cualquier commit.

## Reglas del proyecto

- Mantener la jugabilidad: un toque marca X, doble toque pone o quita un conejo
  y arrastrar marca varias X. Sobre una X, el doble toque primero la quita sin
  gastar vida. No cambiar este esquema sin pedirlo.
- Cada partida tiene tres vidas. Un conejo en una casilla que no pertenece a la
  solución descuenta una vida y deja una X; sin vidas se bloquea el tablero
  hasta reiniciar. Las pistas no cuestan vidas y deshacer no las devuelve.
- La progresión es una campaña lineal: no añadir un selector de niveles. Las
  etapas se encadenan de 6×6 a 9×9 y el progreso vive en
  `ronron.campaign.stage`.
- Los conejos de pista de las primeras etapas son celdas fijas: no se pueden
  quitar ni deshacer, y se guardan en `SavedGame.given`.
- La puntuación se calcula solo en `lib/game/scoring.dart` (base por tamaño,
  bonus por tiempo y por vidas). No duplicar la fórmula en la interfaz. Las
  vidas restantes se convierten en zanahorias y se acumulan en `StatsData`.
- Revivir cuesta `reviveCost` (3 zanahorias) y devuelve una vida. No cambiar el
  coste sin revisar el equilibrio de la economía.
- El salto de etapa se calcula solo con `stageAdvanceFor` en
  `lib/game/scoring.dart`: tiempo objetivo = tamaño × 30 s; +1 etapa extra si
  se cumple sin perder vidas; +1 más si no se usan pistas y se baja del 60 %.
  No duplicar estos umbrales en la interfaz.
- Los aspectos viven en `lib/game/bunny_skin.dart`; el desbloqueo y la selección
  se guardan en `ronron.skins.unlocked` y `ronron.skins.selected`. El blanco
  debe seguir desbloqueado por defecto.
- El tutorial de primera vez se guarda en `ronron.tutorial.v1` y se puede
  reabrir desde ajustes.
- Cualquier puzle nuevo debe tener **solución única**, regiones conexas y un
  conejo por fila, columna y región. Validarlo con las pruebas y con
  `dart run tool/verify_pool.dart`.
- El lote vive en `assets/puzzles.json`. No editarlo a mano; generarlo con
  `tool/gen_range.dart` y conservar la verificación.
- No usar material, nombres, niveles ni imágenes de Meowdoku. El nombre
  «Conillet amagat», el icono y el arte deben seguir siendo originales.
- La app es offline y sin permisos de red. No añadir analítica, anuncios ni
  servicios externos.
- Respetar el tema Material 3 y la paleta de `lib/theme.dart`; el tablero usa
  las regiones de color como información funcional, no solo decorativa.
- Textos de interfaz centralizados en `lib/l10n/strings.dart`, siempre en
  castellano y valenciano.
- No comentar el código salvo que sea imprescindible.

## Ranking

- Ranking opcional del puzle diario. La app no envía nada automáticamente: el
  jugador pulsa «Enviar al ranking» en `lib/ui/ranking_page.dart`.
- API: `https://samuelsoriano.es/conillet-api`, servida por PocketBase 0.40.6 en
  el VPS aulessocarrades (127.0.0.1:8096) y publicada con nginx en
  `/conillet-api/`. Código y despliegue en `server/`.
- El servidor valida la fórmula de puntos, el tamaño según el día, la fecha
  (±1 día UTC), el apodo y devuelve top 20 diario/histórico.
- Identidad: `playerId` aleatorio en `ronron.player.id` y apodo en
  `SettingsData.nickname`. El mejor resultado diario se guarda en
  `StatsData.lastDaily*`.
- No hay cuentas ni secretos en la app. La contraseña del panel PocketBase está
  en `pass conillet/ranking-admin` y el panel está bloqueado desde Internet;
  se accede por túnel SSH. No mostrar credenciales.
- El APK incluye el permiso normal INTERNET por el ranking; el resto del juego
  debe seguir funcionando offline.

## Web

- La web se publica en https://sasogu.github.io/ronron/ con GitHub Pages.
- Workflow: `.github/workflows/web.yml` (Flutter 3.35.7 y `--base-href`
  dinámico con el nombre del repositorio). No subir `build/web`.
- Para probar en local: `flutter build web --release --base-href /ronron/` y
  servir `build/web` bajo una carpeta `ronron/`.
- `web/manifest.json`, `web/index.html` y los iconos son parte del producto;
  el icono web debe coincidir con `docs/icon.png`.
- La web guarda el progreso en `localStorage`; es independiente del APK.

## Secretos

- `android/key.properties` y `android/app/*.jks` están en `.gitignore`.
- No mostrar contraseñas, tokens ni claves en la salida de comandos, logs,
  capturas ni commits. La contraseña del almacén de firma está en `pass`
  (`ronron/android-keystore`).
- No subir `build/`, `.dart_tool/` ni artefactos de Gradle.

## Estilo de commits

Mensajes concisos e imperativos, por ejemplo:
`Add daily streak stats`, `Fix board gesture handling`, `Update puzzle pool`.
