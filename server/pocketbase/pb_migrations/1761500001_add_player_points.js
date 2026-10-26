migrate((app) => {
  const collection = app.findCollectionByNameOrId("players");
  if (!collection.fields.getByName("points")) {
    collection.fields.add(
      new NumberField({ name: "points", required: true, min: 0 }),
    );
    app.save(collection);
  }
}, (app) => {
  try {
    const collection = app.findCollectionByNameOrId("players");
    collection.fields.removeByName("points");
    app.save(collection);
  } catch (_) {}
});
