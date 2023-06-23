const localRequire = require("module").createRequire(__filename);
const faker = localRequire("@faker-js/faker").fakerEN;

// Move to the correct database in MongoDB
db = db.getSiblingDB("database");

const resultsNumber = 100;

for (let i = 0; i < resultsNumber; i++) {
  const creationDate = faker.date.past();
  const completionDate = faker.date.future({ refDate: creationDate });
  db.Result.insertOne({
    SessionId: faker.string.uuid(),
    Name: faker.word.sample(),
    OwnerTaskId: faker.string.uuid(),
    Status: faker.number.int({
      min: 0,
      max: 3
    }),
    DependentTasks: Array.from({
      length: faker.number.int({
        min: 1,
        max: 10
      })
    }, () => faker.string.uuid()),
    // Binary data
    Data: faker.number.octal(),
    CreationDate: creationDate,
    CompletionDate: completionDate,
    _id: faker.string.uuid(),
  });
}
