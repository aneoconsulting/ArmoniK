const localRequire = require("module").createRequire(__filename);
const faker = localRequire("@faker-js/faker").fakerEN;

// Move to the correct database in MongoDB
db = db.getSiblingDB("database");

const resultsNumber = 100;

for (let i = 0; i < resultsNumber; i++) {
  const createdAt = faker.date.past();
  const completedAt = faker.date.future({ refDate: createdAt });
  db.Result.insertOne({
    SessionId: faker.string.uuid(),
    Name: faker.word.sample(),
    OwnerTaskId: faker.string.uuid(),
    status: faker.number.int({
      min: 0,
      max: 3
    }),
    CreatedAt: createdAt,
    CompletedAt: completedAt,
    ResultId: new ObjectId(),
  });
}
