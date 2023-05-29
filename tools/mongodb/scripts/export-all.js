const fs = require("fs");

// Create a folder named .database
if (fs.existsSync("./data/.database")) {
  // Remove files in the folder
  fs.readdirSync("./data/.database").forEach(function (file) {
    fs.unlinkSync("./data/.database/" + file);
  });
} else {
  fs.mkdirSync("./data/.database");
}

// Move to the correct database in MongoDB
db = db.getSiblingDB("database")

// Retrieve all collections in the database
db.getCollectionNames().forEach(function (collection) {
  // Export each collection to its own file
  if (collection != "system.indexes") {
    var collectionContent = db.getCollection(collection).find();
    const collectionName = collection;
    const data = [];
    while (collectionContent.hasNext()) {
      data.push(collectionContent.next());
    }
    fs.writeFile(
      `./data/.database/${collectionName}.json`,
      JSON.stringify(data, null, 2),
      function (err) {
        if (err) {
          console.log(err);
        }
      }
    );
  }
});
