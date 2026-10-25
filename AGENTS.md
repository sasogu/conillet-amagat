# AGENTS.md — Ronrón

Puzle de lógica de gatos para Android (Flutter). Interfaz en castellano y
valenciano. Licencia GPL-3.0-or-later.

## Comandos

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter build apk --release`

Ejecutar `flutter analyze` y `flutter test` antes de cualquier commit.

## Reglas del proyecto

- Mantener la jugabilidad: un toque marca X, doble toque pone o quita un gato
  y arrastrar marca varias X. No cambiar este esquema sin pedirlo.
- Cualquier puzle nuevo debe tener **solución única**, regiones conexas y un
  gato por fila, columna y región. Validarlo con las pruebas y con
  `dart run tool/verify_pool.dart`.
- El lote vive en `assets/puzzles.json`. No editarlo a mano; generarlo con
  `tool/gen_range.dart` y conservar la verificación.
- No usar material, nombres, niveles ni imágenes de Meowdoku. El nombre
  «Ronrón», el icono y el arte deben seguir siendo originales.
- La app es offline y sin permisos de red. No añadir analítica, anuncios ni
  servicios externos.
- Respetar el tema Material 3 y la paleta de `lib/theme.dart`; el tablero usa
  las regiones de color como información funcional, no solo decorativa.
- Textos de interfaz centralizados en `lib/l10n/strings.dart`, siempre en
  castellano y valenciano.
- No comentar el código salvo que sea imprescindible.

## Secretos

- `android/key.properties` y `android/app/*.jks` están en `.gitignore`.
- No mostrar contraseñas, tokens ni claves en la salida de comandos, logs,
  capturas ni commits. La contraseña del almacén de firma está en `pass`
  (`ronron/android-keystore`).
- No subir `build/`, `.dart_tool/` ni artefactos de Gradle.

## Estilo de commits

Mensajes concisos e imperativos, por ejemplo:
`Add daily streak stats`, `Fix board gesture handling`, `Update puzzle pool`.
