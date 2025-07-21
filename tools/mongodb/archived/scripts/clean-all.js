// Move to the correct database in MongoDB
db = db.getSiblingDB("database")

// Delete all collections in the database
db.getCollectionNames().forEach(function (collection) {
  if (collection != "system.indexes") {
    db.getCollection(collection).drop();
  }
});
