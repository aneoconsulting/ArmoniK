const localRequire = require("module").createRequire(__filename);
const faker = localRequire("@faker-js/faker").fakerEN;

// Move to the correct database in MongoDB
db = db.getSiblingDB("database");

// Generate a session
const sessionId = db.SessionData.insertOne({
  _id: faker.string.uuid(),
  Status: 1, // Running
  PartitionIds: [
    'default' // Default partition in ArmoniK
  ],
  CreationDate: faker.date.past(),
  CancellationDate: null, // Not cancelled
  Options: {
    MaxDuration: "00:05:00",
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
    PartitionId: 'default',
    EngineType: faker.commerce.productAdjective(),
    ApplicationName: faker.commerce.productName().split(" ").join("."),
    ApplicationService: faker.hacker.verb(),
    ApplicationVersion: faker.system.semver(),
    ApplicationNamespace: faker.commerce.productName().split(" ").join("."),
  },
}).insertedId;
const session = db.SessionData.findOne({ _id: sessionId });

const tasksNumber = 100;

for (let i = 0; i < tasksNumber; i++) {
  const status = faker.number.int({
    min: 0,
    max: 11
  })

  db.TaskData.insertOne({
    _id: faker.string.uuid(),
    SessionId: session._id,
    OwnerPodId: "",
    OwnerPodName: "",
    PayloadId: faker.string.uuid(),
    ParentTaskIds: [],
    DataDependencies: [],
    RemainingDataDependencies: {},
    ExpectedOutputIds: Array.from({
      length: faker.number.int({
        min: 1,
        max: 1
      })
    }, () => faker.string.uuid()),
    InitialTaskId: faker.string.uuid(),
    RetryOfIds: [],
    Status: status,
    StatusMessage: "",
    Options: {
      MaxDuration: "00:05:00",
      MaxRetries: faker.number.int({
        min: 0,
        max: 10
      }),
      Options: {},
      Priority: faker.number.int({
        min: 0,
        max: 4
      }),
      PartitionId: session.Options.PartitionId,
      EngineType: session.Options.EngineType,
      ApplicationName: session.Options.ApplicationName,
      ApplicationService: session.Options.ApplicationService,
      ApplicationVersion: session.Options.ApplicationVersion,
      ApplicationNamespace: session.Options.ApplicationNamespace,
    },
    CreationDate: faker.date.past(),
    // TODO: date can be improved for more real world data
    SubmittedDate: null,
    StartDate: null,
    EndDate: null,
    ReceptionDate: null,
    AcquisitionDate: null,
    PodTtl: null,
    ProcessingToEndDuration: null,
    CreationToEndDuration: null,
    Output: {
      Success: false,
      Error: ""
    }
  });
}
