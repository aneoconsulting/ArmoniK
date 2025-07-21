const localRequire = require("module").createRequire(__filename);
const faker = localRequire("@faker-js/faker").fakerEN;

db = db.getSiblingDB("database");

// Create 100 partitions
const partitionsNumber = 100;

for (let i = 0; i < partitionsNumber; i++) {
  db.PartitionData.insertOne({
    _id: faker.string.uuid(),
    ParentPartitionIds: Array.from({
      length: faker.number.int({
        min: 1,
        max: 10
      })
    }, () => faker.string.uuid()),
    PodConfiguration: {
      Configuration: {
        verb: faker.hacker.verb(),
        noun: faker.hacker.noun(),
      }
    },
    PodMax: faker.number.int({
      min: 20,
      max: 100
    }),
    PodReserved: faker.number.int({
      min: 0,
      max: 20
    }),
    PreemptionPercentage: faker.number.int({
      min: 0,
      max: 100
    }),
    Priority: faker.number.int({
      min: 0,
      max: 4
    }),
  });
}
