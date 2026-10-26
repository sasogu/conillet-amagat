# Ranking server

API del ranking de Conillet amagat con PocketBase 0.40.6.

- URL pública: `https://samuelsoriano.es/conillet-api`
- PocketBase escucha en `127.0.0.1:8096`; nginx publica `/conillet-api/`.
- Colecciones: `players` y `daily_scores` (sin API pública directa).
- Endpoints propios:
  - `POST /api/conillet/submit`
  - `GET /api/conillet/daily?day=YYYY-MM-DD&deviceId=...`
  - `GET /api/conillet/history?deviceId=...`
  - `GET /api/conillet/health`
- Validación: fórmula de puntos, tamaño según el día de la semana, fecha dentro de
  hoy/ayer/mañana (UTC, para cubrir husos horarios), apodo de 3–16 caracteres y
  lista básica de palabras ofensivas.
- CORS: PocketBase permite todos los orígenes por defecto (datos públicos, sin cookies).

## Despliegue

1. Copiar `pocketbase`, `pb_migrations/` y `pb_hooks/` a `/opt/conillet-ranking/`.
2. Usuario de sistema `conillet`; datos en `/opt/conillet-ranking/pb_data` (0700).
3. Instalar `systemd/conillet-ranking.service` y `nginx/*` como se describe en
   los propios ficheros; incluir `snippets/conillet-api.conf` en el vhost HTTPS de
   `samuelsoriano.es` y recargar nginx.
4. En el primer arranque, la migración crea el superusuario desde
   `PB_SUPERUSER_EMAIL` y `PB_SUPERUSER_PASSWORD` si están en el entorno.
   Correo: `admin@conillet.local`; contraseña en `pass conillet/ranking-admin`.
   Después del primer arranque no hace falta mantener la contraseña en el
   entorno.
5. El panel `/_/` está bloqueado desde Internet. Para administrar:
   `ssh -L 8096:127.0.0.1:8096 -p 2222 samgua@100.69.168.122` y abrir
   `http://127.0.0.1:8096/_/`.

## Notas

- Límite nginx: 300 peticiones/min por IP con burst 20.
- El ranking es opcional desde la app; el juego sigue funcionando offline.
- Pendiente: copia de seguridad diaria de `pb_data` y sincronización al NAS.
