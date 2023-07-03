const localRequire = require("module").createRequire(__filename)
const faker = localRequire("@faker-js/faker").fakerEN

// Move to the correct database in MongoDB
db = db.getSiblingDB("database")

const application = {
  ApplicationName: faker.commerce.productName().split(" ").join("."),
  ApplicationService: faker.hacker.verb(),
  ApplicationVersion: faker.system.semver(),
  ApplicationNamespace: faker.commerce.productName().split(" ").join(".")
}

const partitionId = faker.string.uuid()

db.PartitionData.insertOne({
  _id: partitionId,
  ParentPartitionIds: [],
  PodConfiguration: null,
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
})

const sessionId = faker.string.uuid()
const sessionCreationDate = faker.date.past()

const options = {
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
  PartitionId: partitionId,
  EngineType: faker.commerce.productAdjective(),
  ...application
}

db.SessionData.insertOne({
  _id: sessionId,
  Status: 1, // Running
  PartitionIds: [partitionId],
  CreationDate: sessionCreationDate,
  CancellationDate: null,
  Options: {
    ...options,
  },
})

const tasksNumber = 1_000

const resultsIds = []
for (let i = 0; i < tasksNumber; i++) {
  const creationDate = faker.date.between({ from: sessionCreationDate, to: new Date() })
  const submittedDate = faker.date.between({ from: creationDate, to: new Date() })
  const startDate = faker.date.future({ refDate: submittedDate })
  const endDate = faker.date.future({ refDate: startDate })

  const expectedOutputIds = Array.from({
    length: faker.number.int({
      min: 0,
      max: 2
    })
  }, () => faker.string.uuid())

  const taskId = faker.string.uuid()

  resultsIds.push({
    taskId: taskId,
    expectedOutputIds: expectedOutputIds
  })

  db.TaskData.insertOne({
    _id: taskId,
    SessionId: sessionId,
    OwnerPodId: "",
    OwnerPodName: "",
    PayloadId: faker.string.uuid(),
    ParentTaskIds: [],
    DataDependencies: [],
    RemainingDataDependencies: {},
    ExpectedOutputIds: expectedOutputIds,
    InitialTaskId: null,
    Status: 4, // Completed
    StatusMessage: "",
    Options: {
      ...options,
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
  })
}

resultsIds.forEach(({ taskId, expectedOutputIds }) => {
  const creationDate = faker.date.past();
  const completionDate = faker.date.future({ refDate: creationDate });

  expectedOutputIds.forEach((expectedOutputId) => {
    db.Result.insertOne({
      SessionId: sessionId,
      Name: faker.word.sample(),
      OwnerTaskId: taskId,
      Status: 2, // Completed
      DependentTasks: [],
      // Binary data
      Data: faker.number.octal(),
      CreationDate: creationDate,
      CompletionDate: completionDate,
      _id: expectedOutputId,
    })
  })
})
