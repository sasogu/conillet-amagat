migrate((app) => {
  const collection = app.findCollectionByNameOrId("players");
  if (!collection.fields.getByName("legacy_points")) {
    collection.fields.add(
      new NumberField({ name: "legacy_points", required: false, min: 0 }),
    );
  }
  if (!collection.fields.getByName("merged_into")) {
    collection.fields.add(
      new TextField({ name: "merged_into", required: false, max: 64 }),
    );
  }
  app.save(collection);
}, (app) => {
  const collection = app.findCollectionByNameOrId("players");
  collection.fields.removeByName("legacy_points");
  collection.fields.removeByName("merged_into");
  app.save(collection);
});
