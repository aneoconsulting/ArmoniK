locals {
  ingress_generated_cert = {
    names = ["Submitter", "Monitoring"]
    permissions = tomap({
      "Submitter" = [
        "Submitter:GetServiceConfiguration",
        "Submitter:CancelSession",
        "Submitter:CancelTasks",
        "Submitter:CreateSession",
        "Submitter:CreateSmallTasks",
        "Submitter:CreateLargeTasks",
        "Submitter:CountTasks",
        "Submitter:TryGetResultStream",
        "Submitter:WaitForCompletion",
        "Submitter:TryGetTaskOutput",
        "Submitter:WaitForAvailability",
        "Submitter:GetTaskStatus",
        "Submitter:GetResultStatus",
        "Submitter:ListTasks",
        "Submitter:ListSessions",
        "Sessions:CancelSession",
        "Sessions:GetSession",
        "Sessions:ListSessions",
        "Tasks:GetTask",
        "Tasks:ListTasks",
        "Tasks:GetResultIds",
        "Results:GetOwnerTaskId",
        "General:Impersonate"
        ]
      "Monitoring" = [
        "Submitter:GetServiceConfiguration",
        "Submitter:CountTasks",
        "Submitter:GetTaskStatus",
        "Submitter:GetResultStatus",
        "Submitter:ListTasks",
        "Submitter:ListSessions",
        "Sessions:GetSession",
        "Sessions:ListSessions",
        "Tasks:GetTask",
        "Tasks:ListTasks",
        "Tasks:GetResultIds",
        "Results:GetOwnerTaskId"
        ]
    })
  }
}