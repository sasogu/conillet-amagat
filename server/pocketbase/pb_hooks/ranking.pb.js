routerAdd("GET", "/api/conillet/health", (e) => {
  return e.json(200, { ok: true, app: "conillet-ranking" });
});

routerAdd("POST", "/api/conillet/submit", (e) => {
  function text(value) {
    return String(value === undefined || value === null ? "" : value).trim();
  }

  function utcDay(offsetDays) {
    const date = new Date();
    date.setUTCDate(date.getUTCDate() + offsetDays);
    return date.toISOString().slice(0, 10);
  }

  function expectedSize(day) {
    const sizes = [9, 6, 7, 8, 9, 8, 7]; // domingo..sábado
    const date = new Date(day + "T12:00:00Z");
    return sizes[date.getUTCDay()];
  }

  function scoreFor(size, seconds, lives) {
    return size * 100 + Math.max(0, size * 30 - seconds) * 10 + lives * 100;
  }

  function validNickname(nickname) {
    const nickRe = /^[A-Za-z0-9ÁÉÍÓÚÜÑáéíóúüñÇçÀÈÌÒÙàèìòù _.-]{3,16}$/;
    const badWords = [
      "puta",
      "puto",
      "mierda",
      "cabron",
      "cabrón",
      "gilipollas",
      "coño",
      "zorra",
      "marica",
      "maricón",
      "pendejo",
      "verga",
      "fuck",
      "shit",
      "bitch",
      "nazi",
      "hitler",
    ];
    if (!nickRe.test(nickname)) return false;
    const lower = nickname.toLowerCase();
    return !badWords.some((word) => lower.indexOf(word) !== -1);
  }

  const deviceRe = /^[A-Za-z0-9-]{16,64}$/;
  const dayRe = /^\d{4}-\d{2}-\d{2}$/;
  const body = e.requestInfo().body || {};
  const deviceId = text(body.deviceId);
  const nickname = text(body.nickname).replace(/\s+/g, " ");
  const day = text(body.day);
  const score = Number(body.score);
  const seconds = Number(body.seconds);
  const lives = Number(body.lives);
  const size = Number(body.size);

  if (!deviceRe.test(deviceId)) {
    throw new BadRequestError("Identificador de dispositivo no válido.");
  }
  if (!validNickname(nickname)) {
    throw new BadRequestError(
      "El apodo debe tener entre 3 y 16 caracteres y usar letras, números, espacios, puntos, guiones o guiones bajos.",
    );
  }
  if (!dayRe.test(day)) {
    throw new BadRequestError("Fecha no válida.");
  }
  const today = utcDay(0);
  const yesterday = utcDay(-1);
  const tomorrow = utcDay(1);
  if (day !== today && day !== yesterday && day !== tomorrow) {
    throw new BadRequestError("Solo se puede enviar la marca del día.");
  }
  if (size !== expectedSize(day)) {
    throw new BadRequestError("El tamaño no corresponde al puzle diario.");
  }
  if (!Number.isFinite(seconds) || seconds < 0 || seconds > 86400) {
    throw new BadRequestError("Tiempo no válido.");
  }
  if (!Number.isFinite(lives) || lives < 0 || lives > 3) {
    throw new BadRequestError("Vidas no válidas.");
  }
  if (!Number.isFinite(score) || score !== scoreFor(size, seconds, lives)) {
    throw new BadRequestError("Puntuación no válida.");
  }

  let improved = false;
  let total = 0;

  e.app.runInTransaction((txApp) => {
    let player = null;
    try {
      player = txApp.findFirstRecordByData("players", "device_id", deviceId);
    } catch (_) {
      player = null;
    }

    if (!player) {
      const collection = txApp.findCollectionByNameOrId("players");
      player = new Record(collection);
      player.set("device_id", deviceId);
      player.set("nickname", nickname);
      player.set("total", 0);
      player.set("days", 0);
      player.set("points", 0);
    } else {
      player.set("nickname", nickname);
    }

    let daily = null;
    try {
      daily = txApp.findFirstRecordByFilter(
        "daily_scores",
        "device_id = {:deviceId} && day = {:day}",
        { deviceId: deviceId, day: day },
      );
    } catch (_) {
      daily = null;
    }

    if (!daily) {
      const collection = txApp.findCollectionByNameOrId("daily_scores");
      daily = new Record(collection);
      daily.set("device_id", deviceId);
      daily.set("nickname", nickname);
      daily.set("day", day);
      daily.set("score", score);
      daily.set("seconds", seconds);
      daily.set("lives", lives);
      daily.set("size", size);
      player.set("total", player.getInt("total") + score);
      player.set("days", player.getInt("days") + 1);
      txApp.saveNoValidate(daily);
      improved = true;
    } else {
      const oldScore = daily.getInt("score");
      const oldSeconds = daily.getInt("seconds");
      const betterScore = score > oldScore;
      const betterTime = score === oldScore && seconds < oldSeconds;
      if (betterScore) {
        player.set("total", player.getInt("total") + (score - oldScore));
        improved = true;
      }
      if (betterScore || betterTime) {
        daily.set("score", score);
        daily.set("seconds", seconds);
        daily.set("lives", lives);
        daily.set("size", size);
      }
      daily.set("nickname", nickname);
      txApp.saveNoValidate(daily);
    }

    txApp.saveNoValidate(player);
    total = player.getInt("total");
  });

  return e.json(200, { ok: true, improved: improved, score: score, total: total });
});

routerAdd("GET", "/api/conillet/daily", (e) => {
  function text(value) {
    return String(value === undefined || value === null ? "" : value).trim();
  }

  function utcDay() {
    return new Date().toISOString().slice(0, 10);
  }

  const dayRe = /^\d{4}-\d{2}-\d{2}$/;
  const query = e.requestInfo().query || {};
  const day = text(query.day) || utcDay();
  const deviceId = text(query.deviceId);
  if (!dayRe.test(day)) {
    throw new BadRequestError("Fecha no válida.");
  }

  const records = e.app.findRecordsByFilter(
    "daily_scores",
    "day = {:day}",
    "-score,seconds",
    20,
    0,
    { day: day },
  );
  const entries = [];
  let rank = 0;
  for (const record of records) {
    rank += 1;
    entries.push({
      rank: rank,
      nickname: record.getString("nickname"),
      score: record.getInt("score"),
      seconds: record.getInt("seconds"),
      lives: record.getInt("lives"),
      size: record.getInt("size"),
      me: !!deviceId && record.getString("device_id") === deviceId,
    });
  }

  let my = null;
  if (deviceId) {
    try {
      const record = e.app.findFirstRecordByFilter(
        "daily_scores",
        "day = {:day} && device_id = {:deviceId}",
        { day: day, deviceId: deviceId },
      );
      const score = record.getInt("score");
      const seconds = record.getInt("seconds");
      const better = e.app.countRecords(
        "daily_scores",
        $dbx.exp(
          "day = {:day} AND (score > {:score} OR (score = {:score} AND seconds < {:seconds}))",
          { day: day, score: score, seconds: seconds },
        ),
      );
      my = {
        rank: better + 1,
        nickname: record.getString("nickname"),
        score: score,
        seconds: seconds,
        lives: record.getInt("lives"),
        size: record.getInt("size"),
      };
    } catch (_) {
      my = null;
    }
  }

  return e.json(200, { day: day, entries: entries, my: my });
});

routerAdd("GET", "/api/conillet/history", (e) => {
  function text(value) {
    return String(value === undefined || value === null ? "" : value).trim();
  }

  const query = e.requestInfo().query || {};
  const deviceId = text(query.deviceId);

  const records = e.app.findRecordsByFilter(
    "players",
    "days > 0",
    "-total,-days",
    20,
    0,
  );
  const entries = [];
  let rank = 0;
  for (const record of records) {
    rank += 1;
    entries.push({
      rank: rank,
      nickname: record.getString("nickname"),
      total: record.getInt("total"),
      days: record.getInt("days"),
      me: !!deviceId && record.getString("device_id") === deviceId,
    });
  }

  let my = null;
  if (deviceId) {
    try {
      const record = e.app.findFirstRecordByData("players", "device_id", deviceId);
      const total = record.getInt("total");
      const days = record.getInt("days");
      const better = e.app.countRecords(
        "players",
        $dbx.exp(
          "days > 0 AND (total > {:total} OR (total = {:total} AND days > {:days}))",
          { total: total, days: days },
        ),
      );
      my = {
        rank: better + 1,
        nickname: record.getString("nickname"),
        total: total,
        days: days,
      };
    } catch (_) {
      my = null;
    }
  }

  return e.json(200, { entries: entries, my: my });
});

routerAdd("POST", "/api/conillet/points", (e) => {
  function text(value) {
    return String(value === undefined || value === null ? "" : value).trim();
  }

  function validNickname(nickname) {
    const nickRe = /^[A-Za-z0-9ÁÉÍÓÚÜÑáéíóúüñÇçÀÈÌÒÙàèìòù _.-]{3,16}$/;
    const badWords = [
      "puta",
      "puto",
      "mierda",
      "cabron",
      "cabrón",
      "gilipollas",
      "coño",
      "zorra",
      "marica",
      "maricón",
      "pendejo",
      "verga",
      "fuck",
      "shit",
      "bitch",
      "nazi",
      "hitler",
    ];
    if (!nickRe.test(nickname)) return false;
    const lower = nickname.toLowerCase();
    return !badWords.some((word) => lower.indexOf(word) !== -1);
  }

  const deviceRe = /^[A-Za-z0-9-]{16,64}$/;
  const body = e.requestInfo().body || {};
  const deviceId = text(body.deviceId);
  const nickname = text(body.nickname).replace(/\s+/g, " ");
  const points = Number(body.points);

  if (!deviceRe.test(deviceId)) {
    throw new BadRequestError("Identificador de dispositivo no válido.");
  }
  if (!validNickname(nickname)) {
    throw new BadRequestError(
      "El apodo debe tener entre 3 y 16 caracteres y usar letras, números, espacios, puntos, guiones o guiones bajos.",
    );
  }
  if (
    !Number.isFinite(points) ||
    points < 0 ||
    points > 1000000000 ||
    points !== Math.floor(points)
  ) {
    throw new BadRequestError("Puntuación total no válida.");
  }

  e.app.runInTransaction((txApp) => {
    let player = null;
    try {
      player = txApp.findFirstRecordByData("players", "device_id", deviceId);
    } catch (_) {
      player = null;
    }
    if (!player) {
      const collection = txApp.findCollectionByNameOrId("players");
      player = new Record(collection);
      player.set("device_id", deviceId);
      player.set("nickname", nickname);
      player.set("total", 0);
      player.set("days", 0);
      player.set("points", points);
    } else {
      player.set("nickname", nickname);
      player.set("points", points);
    }
    txApp.saveNoValidate(player);
  });

  return e.json(200, { ok: true, points: points });
});

routerAdd("GET", "/api/conillet/general", (e) => {
  function text(value) {
    return String(value === undefined || value === null ? "" : value).trim();
  }

  const query = e.requestInfo().query || {};
  const deviceId = text(query.deviceId);

  const records = e.app.findRecordsByFilter(
    "players",
    "points > 0",
    "-points,-total",
    20,
    0,
  );
  const entries = [];
  let rank = 0;
  for (const record of records) {
    rank += 1;
    entries.push({
      rank: rank,
      nickname: record.getString("nickname"),
      points: record.getInt("points"),
      me: !!deviceId && record.getString("device_id") === deviceId,
    });
  }

  let my = null;
  if (deviceId) {
    try {
      const record = e.app.findFirstRecordByData("players", "device_id", deviceId);
      const points = record.getInt("points");
      if (points > 0) {
        const total = record.getInt("total");
        const better = e.app.countRecords(
          "players",
          $dbx.exp(
            "points > 0 AND (points > {:points} OR (points = {:points} AND total > {:total}))",
            { points: points, total: total },
          ),
        );
        my = {
          rank: better + 1,
          nickname: record.getString("nickname"),
          points: points,
        };
      }
    } catch (_) {
      my = null;
    }
  }

  return e.json(200, { entries: entries, my: my });
});
