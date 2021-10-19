
using Armonik.sdk;
using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;

namespace ArmonikSamples
{
    public class ServiceContainer : IServiceContainer
    {
        public override void OnCreateService(ServiceContext serviceContext)
        {
            //END USER PLEASE FIXME
        }

        public override void OnSessionEnter(SessionContext sessionContext)
        {
            //END USER PLEASE FIXME
        }

        public override void OnInvoke(SessionContext sessionContext, TaskContext taskContext)
        {
            var clientPayload = ClientPayload.deserialize(taskContext.TaskInput);

            if (string.Compare(clientPayload.taskType, "Compute") > 0)
            {
                List<string> taskIds = new List<string>();
                foreach (var number in clientPayload.numbers)
                {
                    var subTaskPaylaod = new ClientPayload();
                    subTaskPaylaod.taskType = "Square";
                    subTaskPaylaod.numbers = new List<int>() {number};
                    taskIds.Add(this.SubmitTask(sessionContext.SessionId, subTaskPaylaod.serialize()));
                }
                int sum = 0;
                foreach (var task in taskIds)
                {
                    htcGridClient.WaitCompletion(task);
                    byte [] taskOutput = GetData(task);
                    var outputPayload = ClientPayload.deserialize(taskOutput);
                    sum += outputPayload.result;
                }
                var sumPaylaod = new ClientPayload();
                sumPaylaod.taskType = "Result Sum";
                sumPaylaod.result = sum;
                Console.WriteLine($"Compute sum = {sum}");
                writeTaskOutput(taskContext.TaskId, sumPaylaod.serialize());
            }
            else if (string.Compare(clientPayload.taskType, "Square") > 0)
            {
                int c = clientPayload.numbers.First();
                var subTaskPaylaod = new ClientPayload();
                subTaskPaylaod.taskType = "Result Square";
                subTaskPaylaod.result = c * c;
                Console.WriteLine($"Compute {c} square = {subTaskPaylaod.result}");
                writeTaskOutput(taskContext.TaskId, subTaskPaylaod.serialize());
            }
        }

        public override void OnSessionLeave(SessionContext sessionContext)
        {
            //END USER PLEASE FIXME
        }


        public override void OnDestroyService(ServiceContext serviceContext)
        {
            //END USER PLEASE FIXME
        }
    }
}