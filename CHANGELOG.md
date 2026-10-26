# Changelog

## 0.7.0 — 2026-10-26

- **Ranking opcional** del puzle diario entre dispositivos: top 20 del día y
  clasificación histórica por suma de marcas diarias.
- Apodo elegido e identificador aleatorio; sin cuentas ni correo. El envío es
  manual desde la pantalla de ranking y solo se manda al resolver el diario.
- Validación en el servidor de puntos, tiempo, vidas, tamaño, fecha y apodo.
- Backend PocketBase en el VPS y API HTTPS en
  `https://samuelsoriano.es/conillet-api`; código en `server/`.
- Nuevo permiso normal de Internet en Android para el ranking opcional. El
  juego y el guardado siguen funcionando sin conexión.

## Web — 2026-10-25

- Versión web publicada en GitHub Pages: https://sasogu.github.io/ronron/
- PWA instalable, con progreso local del navegador y funcionamiento sin
  conexión tras la primera carga.
- Despliegue automático con GitHub Actions al hacer push a `main`.

## 0.6.0 — 2026-10-25

- **Progresión rápida**: cada puzle avanza 1 etapa; si se resuelve dentro del
  tiempo objetivo (30 s por casilla de lado) y sin perder vidas, avanza 2; y si
  además no se usan pistas y se baja del 60 % de ese tiempo, avanza 3.
- El diálogo de victoria muestra el salto rápido conseguido.

## 0.5.0 — 2026-10-25

- **Revivir con zanahorias**: al quedarse sin vidas se puede gastar 3
  zanahorias para recuperar una vida y seguir la partida.
- Doble toque más seguro: sobre una X primero la quita, sin gastar vida.
- **Tutorial de primera vez** con las reglas, las vidas, los conejos fijos y
  las zanahorias; también se puede abrir desde ajustes.
- **Aspectos de conejo**: cinco colores que se desbloquean con zanahorias y se
  equipan al momento. El conejo blanco sigue siendo el inicial.

## 0.4.0 — 2026-10-25

- **Puntuación por puzle resuelto**: base según el tamaño, bonus por resolver
  rápido y bonus por cada vida conservada.
- Las **vidas no consumidas se convierten en zanahorias** para el conejo. Los
  puntos y las zanahorias se acumulan en las estadísticas.
- El diálogo de victoria muestra los puntos, el desglose (base, tiempo y
  vidas), el tiempo, las pistas y las zanahorias conseguidas.
- Nuevo contador de puntos y zanahorias en la portada.
- El conejo pasa a ser blanco, con contorno para destacar sobre las casillas;
  también se ha actualizado el icono de la aplicación.

## 0.3.0 — 2026-10-25

- Nueva **progresión por etapas**: una secuencia lineal de 399 etapas que va de
  6×6 a 9×9 y sigue con 9×9 infinitos. Se elimina el selector de niveles.
- Las etapas 1 a 3 incluyen dos conejos fijos de pista; las etapas 4 a 6, uno.
  Los conejos de pista se marcan con un contorno y no se pueden quitar.
- La portada muestra la etapa actual, el progreso y un único botón para jugar.
  El puzle diario se mantiene como modo independiente.
- Tablero rediseñado con casillas redondeadas y separadas entre sí; se eliminan
  los bordes gruesos entre regiones y la cuadrícula gana protagonismo.

## 0.2.1 — 2026-10-25

- Identificador de la aplicación cambiado a `es.sasogu.conillet`, acorde con el
  nuevo nombre.
- Es un paquete distinto de `es.sasogu.ronron`: no comparte progreso con las
  instalaciones anteriores y puede convivir con ellas.

## 0.2.0 — 2026-10-25

- La app pasa a llamarse **Conillet amagat**: el gato deja paso a un conejo.
- Nuevo arte del conejo en el tablero y en el icono de la aplicación.
- Textos en castellano y valenciano adaptados a los conejos.
- Nuevas **tres vidas**: colocar un conejo en una casilla incorrecta descuenta
  una vida y deja una X; al agotarlas se puede reiniciar el puzle. Las pistas y
  el deshacer no devuelven vidas.
- Tablero con iluminación y bordes de región más definidos, X más finas y
  conejos con orejas interiores.
- El identificador `es.sasogu.ronron` se mantiene para conservar el progreso
  y la firma de las instalaciones anteriores.

## 0.1.2 — 2026-10-25

- Identificador de la aplicación cambiado a `es.sasogu.ronron` antes de la
  publicación en Play Store.
- Versión de prueba con el nuevo paquete; la 0.1.1 queda como anterior.

## 0.1.1 — 2026-10-25

- Mejorada la paleta del modo oscuro: regiones más luminosas, saturadas y
  distinguibles, con un borde más definido.
- Las X automáticas usan un tono oscuro discreto para no competir con los
  gatos y las X manuales.
- Ajustados el color de conflicto y las líneas de la cuadrícula en oscuro.

## 0.1.0 — 2026-10-25

Primera versión publicada para probar.

- 399 puzles originales con solución única: 99 de 6×6, 100 de 7×7, 100 de 8×8
  y 100 de 9×9.
- Puzle diario con tamaño rotativo y racha.
- Niveles sin fin por tamaño y progreso guardado.
- Toque para marcar X, doble toque para poner gato y arrastre para varias X.
- Marcado automático de X, pistas, deshacer, reinicio y detección de conflictos.
- Guardado automático de la partida y del cronómetro.
- Castellano y valenciano; tema claro, oscuro o del sistema.
- Sin anuncios, sin conexión, sin cuentas y sin permisos de red.
