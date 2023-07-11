const localRequire = require("module").createRequire(__filename);
const faker = localRequire("@faker-js/faker").fakerEN;

// Move to the correct database in MongoDB
db = db.getSiblingDB("database");

const tasksNumber = 100;
for (let i = 0; i < tasksNumber; i++) {
  const creationDate = faker.date.past();
  const submittedDate = faker.date.between({ from: creationDate, to: new Date() });
  const startDate = faker.date.future({ refDate: submittedDate });
  const endDate = faker.datatype.boolean() ? faker.date.future({ refDate: startDate }) : null;
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
      Options: {
        "CustomOption1": faker.word.sample(),
        "CustomOption2": faker.word.sample()
      },
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
    CreationDate: creationDate,
    SubmittedDate: submittedDate,
    StartDate: startDate,
    EndDate: endDate,
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
