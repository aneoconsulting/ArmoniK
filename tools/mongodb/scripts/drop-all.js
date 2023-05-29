db = db.getSiblingDB("database");

db.getCollectionNames().forEach(function (collection) {
  if (collection != "system.indexes") {
    db.getCollection(collection).drop();
  }
});
