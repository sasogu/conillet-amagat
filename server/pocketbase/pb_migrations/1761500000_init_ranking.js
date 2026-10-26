migrate((app) => {
  const email = $os.getenv("PB_SUPERUSER_EMAIL");
  const password = $os.getenv("PB_SUPERUSER_PASSWORD");
  if (email && password) {
    try {
      const superusers = app.findCollectionByNameOrId("_superusers");
      const admin = new Record(superusers);
      admin.set("email", email);
      admin.set("password", password);
      app.save(admin);
    } catch (_) {
      // Si ya existe, la migración continúa.
    }
  }

  const players = new Collection({
    type: "base",
    name: "players",
    listRule: null,
    viewRule: null,
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      { name: "device_id", type: "text", required: true, max: 64 },
      { name: "nickname", type: "text", required: true, max: 20 },
      { name: "total", type: "number", required: true },
      { name: "days", type: "number", required: true },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_players_device_id ON players (device_id)",
    ],
  });
  app.save(players);

  const daily = new Collection({
    type: "base",
    name: "daily_scores",
    listRule: null,
    viewRule: null,
    createRule: null,
    updateRule: null,
    deleteRule: null,
    fields: [
      { name: "device_id", type: "text", required: true, max: 64 },
      { name: "nickname", type: "text", required: true, max: 20 },
      { name: "day", type: "text", required: true, max: 10 },
      { name: "score", type: "number", required: true },
      { name: "seconds", type: "number", required: true },
      { name: "lives", type: "number", required: true },
      { name: "size", type: "number", required: true },
    ],
    indexes: [
      "CREATE UNIQUE INDEX idx_daily_scores_device_day ON daily_scores (device_id, day)",
      "CREATE INDEX idx_daily_scores_day_score ON daily_scores (day, score DESC, seconds ASC)",
    ],
  });
  app.save(daily);
}, (app) => {
  try {
    app.delete(app.findCollectionByNameOrId("daily_scores"));
  } catch (_) {}
  try {
    app.delete(app.findCollectionByNameOrId("players"));
  } catch (_) {}
  const email = $os.getenv("PB_SUPERUSER_EMAIL");
  if (email) {
    try {
      app.delete(app.findAuthRecordByEmail("_superusers", email));
    } catch (_) {}
  }
});
