const localRequire = require("module").createRequire(__filename);
const faker = localRequire("@faker-js/faker").fakerEN;

// Move to the correct database in MongoDB
db = db.getSiblingDB("database");

// Create 100 sessions
const sessionsNumber = 100;

for (let i = 0; i < sessionsNumber; i++) {
  db.SessionData.insertOne({
    _id: faker.string.uuid(),
    Status: faker.number.int({
      min: 0,
      max: 2
    }),
    PartitionIds: Array.from({
      length: faker.number.int({
        min: 1,
        max: 10
      })
    }, () => faker.string.uuid()),
    CreationDate: faker.date.past(),
    CancellationDate: faker.datatype.boolean() ? faker.date.past() : null,
    Options: {
      MaxDuration: "00:00:00",
      MaxRetries: faker.number.int({
        min: 0,
        max: 10
      }),
      Options: {},
      Priority: faker.number.int({
        min: 0,
        max: 4
      }),
      PartitionId: faker.string.uuid(),
      EngineType: faker.commerce.productAdjective(),
      ApplicationName: faker.commerce.productName().split(" ").join("."),
      ApplicationService: faker.hacker.verb(),
      ApplicationVersion: faker.system.semver(),
      ApplicationNamespace: faker.commerce.productName().split(" ").join("."),
    },
  });
}
