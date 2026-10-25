# Conillet amagat

**Puzle de lógica de conejos para Android, libre, sin anuncios y sin conexión.**

Conillet amagat es un juego de deducción sobre una cuadrícula dividida en
regiones de color. Hay que esconder exactamente un conejo en cada fila, en cada
columna y en cada región, sin que dos conejos se toquen, ni siquiera en
diagonal.

<p align="center">
  <img src="docs/icon.png" width="120" alt="Icono de Conillet amagat" />
</p>

<p align="center">
  <img src="docs/screenshots/home-light.png" width="260" alt="Portada en modo claro" />
  <img src="docs/screenshots/game-light.png" width="260" alt="Partida en curso" />
</p>
<p align="center">
  <img src="docs/screenshots/game-dark.png" width="260" alt="Partida en modo oscuro" />
  <img src="docs/screenshots/home-dark.png" width="260" alt="Portada en modo oscuro" />
</p>
<p align="center">
  <img src="docs/screenshots/win-light.png" width="260" alt="Puntos y zanahorias al resolver" />
  <img src="docs/screenshots/win-dark.png" width="260" alt="Puntos y zanahorias al resolver en modo oscuro" />
</p>
<p align="center">
  <img src="docs/screenshots/tutorial-light.png" width="260" alt="Tutorial de la primera vez" />
  <img src="docs/screenshots/skins-light.png" width="260" alt="Aspectos del conejo" />
</p>

## Descargar

La versión de prueba está en
[Releases](https://github.com/sasogu/ronron/releases):

- APK universal firmado: `conillet-amagat-0.6.0.apk`
- Requiere Android 7.0 o posterior.
- Instalación manual: descarga el APK y permite la instalación desde el
  navegador o el gestor de archivos. También se puede instalar con
  `adb install conillet-amagat-0.6.0.apk`.

La aplicación no pide permisos, no usa Internet y guarda todo en el propio
dispositivo.

## Cómo se juega

- **Un toque** sobre una casilla vacía marca una X (casilla descartada). Otro
  toque borra la X.
- **Doble toque** esconde un conejo. Si la casilla ya tiene un conejo, el doble
  toque lo quita; si tiene una X, primero la deja libre sin gastar vida.
- **Arrastra** el dedo para marcar varias X seguidas.
- Los conejos que se molestan entre sí (misma fila, columna, región o contacto
  diagonal) se resaltan en rojo.
- **X auto** marca automáticamente las casillas que ya no pueden tener conejo.
- **Tres vidas**: si escondes un conejo en una casilla que no le corresponde,
  pierdes una vida y la casilla queda marcada con una X. Al quedarte sin vidas
  puedes reiniciar el puzle o revivir con 3 zanahorias.
- **Progresión**: no hay selector de niveles; cada partida abre la siguiente
  etapa de la campaña. Las tres primeras etapas traen dos conejos fijos de
  pista y las tres siguientes uno; se distinguen por un contorno y no se
  pueden quitar.
- **Progresión rápida**: resolver sin perder vidas y dentro del tiempo objetivo
  (30 s por casilla de lado) avanza 2 etapas; si además no se usan pistas y se
  baja del 60 % de ese tiempo, avanza 3.
- **Pista** coloca un conejo correcto; **Deshacer** revierte el último cambio
  (sin devolver vidas) y **Reiniciar** limpia el tablero y recupera las vidas.
- Al resolver un puzle se suman **puntos** según el tamaño, el tiempo empleado
  y las vidas conservadas. Cada vida sin gastar se convierte en una
  **zanahoria** para el conejo.

## Características

- 399 puzles originales verificados con **solución única**: 99 de 6×6, 100 de
  7×7, 100 de 8×8 y 100 de 9×9.
- Regiones irregulares, desde casillas pequeñas hasta formas alargadas, como
  en los puzles de este género.
- **Puzle diario** con tamaño rotativo, racha de días y progreso guardado.
- **Campaña de 399 etapas** de 6×6 a 9×9, con progreso guardado, saltos de
  etapa por rapidez y 9×9 infinitos al terminarla.
- **Conejos de pista** fijos en las primeras etapas para arrancar con ayuda.
- **Puntos y zanahorias**: puntuación por tiempo y vidas conservadas, con
  contadores acumulados en la portada. Las zanahorias sirven para revivir.
- **Aspectos de conejo**: cinco colores desbloqueables con zanahorias.
- **Tutorial de primera vez** y acceso a «Cómo jugar» desde ajustes.
- Guardado automático de la partida en curso, el cronómetro y las vidas.
- Interfaz en **castellano y valenciano**.
- Tema **claro, oscuro o según el sistema**.
- Sin anuncios, sin compras, sin cuentas, sin telemetría y sin conexión.
- Código y puzles libres (GPL-3.0).

## Desarrollo

Requisitos: Flutter 3.35 o posterior, Dart 3.9 y Android SDK 35 o posterior.

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

El APK resultante queda en `build/app/outputs/flutter-apk/app-release.apk`.

Para firmar una versión de publicación se usa `android/key.properties` junto
con un almacén `android/app/ronron-release.jks`. Ambos están excluidos de Git.
Sin ese fichero, Gradle firma la versión release con la clave de depuración.

### Estructura

```
lib/
  app.dart                 MaterialApp, tema e idiomas
  app_state.dart           ajustes, estadísticas y partida guardada
  data/game_store.dart     persistencia con shared_preferences
  data/puzzle_repository.dart  carga del lote de puzles
  game/puzzle.dart         modelo del puzle
  game/generator.dart      generador de puzles con solución única
  game/solver.dart         solver exacto y solver humano
  game/campaign.dart       etapas, tamaños y conejos de pista
  game/scoring.dart        puntos y zanahorias por puzle
  game/bunny_skin.dart     colores y precios de los conejos
  game/game_controller.dart  estado de la partida
  ui/                      portada, tablero, partida, tutorial, aspectos y ajustes
assets/puzzles.json        lote verificado de puzles
tool/                      generación y verificación del lote
test/                      pruebas de lógica, controlador e interfaz
```

### Generación de puzles

Los puzles no se generan en el móvil: viajan verificados dentro del APK. El
generador parte de una solución válida y reparte las casillas entre regiones
vecinas comprobando, después de cada asignación, que la solución sigue siendo
única. Las regiones son siempre conexas y cada una contiene exactamente un
conejo. Después se filtran tamaños extremos y se vuelve a comprobar la unicidad
con el solver exacto.

```bash
# Generar un bloque de puzles de un tamaño
dart run tool/gen_range.dart 8 0 50 /tmp/pool-8.json

# Verificar assets/puzzles.json (regiones conexas, solución única)
dart run tool/verify_pool.dart
```

Las pruebas del proyecto validan los 399 puzles del lote, además del
generador, el controlador de partida y la interfaz.

## Privacidad

Conillet amagat funciona completamente sin conexión. No incluye el permiso de
Internet en el APK de publicación, no crea cuentas y no envía datos a ningún
servidor. El progreso se guarda localmente con `shared_preferences`.

## Créditos y alcance

El tipo de puzle (una pieza por fila, columna y región, sin contacto) es un
género clásico conocido como *Queens* o *Star Battle*. Este proyecto se inspira
en esa mecánica y en la popularidad de Meowdoku, pero **no está afiliado,
patrocinado ni asociado** con Meowdoku ni con Oakever Games, y no incluye
material, nombres, niveles ni imágenes del juego original. El nombre Conillet
amagat, el icono, el arte del conejo, los puzles y el código son originales.

## Licencia

Copyright © 2026 Samuel Soriano.

Este programa es software libre: puedes redistribuirlo y modificarlo bajo los
términos de la **GNU General Public License, versión 3 o posterior**. Consulta
[LICENSE](LICENSE).

---

## English summary

Conillet amagat is a free, offline, ad-free bunny logic puzzle for Android.
Hide one bunny in every row, column and colored region without touching, not
even diagonally. Includes 399 original uniquely-solvable puzzles, a rotating
daily puzzle, endless levels, Spanish/Valencian UI, dark mode, autosave and
hints. Built with Flutter. Not affiliated with Meowdoku. Licensed under
GPL-3.0-or-later.
