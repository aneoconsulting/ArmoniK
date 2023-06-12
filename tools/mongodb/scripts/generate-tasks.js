const localRequire = require("module").createRequire(__filename);
const faker = localRequire("@faker-js/faker").fakerEN;

// Move to the correct database in MongoDB
db = db.getSiblingDB("database");

const tasksNumber = 100;
// TODO: Add more intelligent data (e.g. a task that depends on another task or a task that is a retry of another task or many tasks with the same application and session)
// TODO: It could be in another file.
for (let i = 0; i < tasksNumber; i++) {
  db.TaskData.insertOne({
    _id: faker.string.uuid(),
    SessionId: faker.string.uuid(),
    OwnerPodId: "",
    OwnerPodName: "",
    PayloadId: faker.string.uuid(),
    ParentTaskIds: Array.from({
      length: faker.number.int({
        min: 1,
        max: 10
      })
    }, () => faker.string.uuid()),
    DataDependencies: [],
    RemainingDataDependencies: {},
    ExpectedOutputIds: Array.from({
      length: faker.number.int({
        min: 1,
        max: 10
      })
    }, () => faker.string.uuid()),
    InitialTaskId: faker.string.uuid(),
    "RetryOfIds": [],
    Status: faker.number.int({
      min: 0,
      max: 11
    }),
    StatusMessage: "",
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
      ApplicationName: faker.commerce.productName().split(" ").join("."),
      ApplicationService: faker.hacker.verb(),
      ApplicationVersion: faker.system.semver(),
      ApplicationNamespace: faker.commerce.productName().split(" ").join("."),
      EngineType: faker.commerce.productAdjective(),
    },
    CreationDate: faker.date.past(),
    // TODO: Add a date
    SubmittedDate: null,
    StartDate: null,
    EndDate: null,
    ReceptionDate: null,
    AcquisitionDate: null,
    PodTtl: null,
    // TODO: Is it a date?
    ProcessingToEndDuration: null,
    // TODO: Is it a date?
    CreationToEndDuration: null,
    Output: {
      Success: false,
      Error: ""
    }
  });
}
