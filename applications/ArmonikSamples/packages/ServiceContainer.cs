
using Armonik.sdk;
using HTCGrid;
using System;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Diagnostics;
using System.Text;

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

        public void ComputeSquare(TaskContext taskContext, ClientPayload clientPayload)
        {
            if (clientPayload.numbers.Count == 0) return; // Nothing to do

            if (clientPayload.numbers.Count == 1)
            {
                int value = clientPayload.numbers[0] * clientPayload.numbers[0];
                Logger.Info($"Compute {value} in {taskContext.TaskId}");
                writeTaskOutput(taskContext.TaskId, BitConverter.GetBytes(value));
            }
            else if (clientPayload.numbers.Count > 1)
            {
                int value = clientPayload.numbers[0];
                int square = value * value;

                var subTaskPaylaod = new ClientPayload();
                clientPayload.numbers.RemoveAt(0);
                subTaskPaylaod.numbers = clientPayload.numbers;
                subTaskPaylaod.taskType = clientPayload.taskType;

                var subTaskId = this.SubmitTask(subTaskPaylaod.serialize());

                htcGridClient.WaitCompletion(subTaskId);
                byte[] arr = htcDataClient.GetData(subTaskId);
                int subResult = BitConverter.ToInt32(arr);

                Logger.Info($"Compute {square} + {subResult} in {taskContext.TaskId}");
                writeTaskOutput(taskContext.TaskId, BitConverter.GetBytes(square + subResult));
            }
        }

        private void _1_Job_of_N_Tasks(TaskContext taskContext, byte[] payload, int nbTasks)
        {
            List<byte[]> payloads = new List<byte[]>(nbTasks);
            for (int i = 0; i < nbTasks; i++)
            {
                payloads.Add(payload);
            }
            Stopwatch sw = Stopwatch.StartNew();
            int finalResult = 0;
            var taskIds = this.SubmitTasks(payloads);
            foreach (var taskId in taskIds)
            {
                htcGridClient.WaitCompletion(taskId);
                byte[] taskResult = htcDataClient.GetData(taskId);
                finalResult += BitConverter.ToInt32(taskResult);
            }
            long elapsedMilliseconds = sw.ElapsedMilliseconds;
            Logger.Info($"Server called {nbTasks} tasks in {elapsedMilliseconds} ms agregated result = {finalResult}");
        }

        public void ComputeCube(TaskContext taskContext, ClientPayload clientPayload)
        {
            int value = clientPayload.numbers[0] * clientPayload.numbers[0] * clientPayload.numbers[0];
            writeTaskOutput(taskContext.TaskId, BitConverter.GetBytes(value));
        }

        public override void OnInvoke(SessionContext sessionContext, TaskContext taskContext)
        {
            var clientPayload = ClientPayload.deserialize(taskContext.TaskInput);

            if (clientPayload.taskType == 1)
            {
                ComputeSquare(taskContext, clientPayload);
            }
            else if (clientPayload.taskType == 2)
            {
                ComputeCube(taskContext, clientPayload);
            }
            else if (clientPayload.taskType == 3)
            {
                Logger.Info($"Empty task, sessionId : {sessionContext.SessionId}, taskId : {taskContext.TaskId}, sessionId from task : {taskContext.SessionId}");
            }
            else if (clientPayload.taskType == 4)
            {
                var newPayload = new ClientPayload() { taskType = 3 };
                byte[] bytePayload = newPayload.serialize();
                _1_Job_of_N_Tasks(taskContext, bytePayload, clientPayload.numbers[0] - 1);
            }
            else
            {
                Logger.Info($"Task type {clientPayload.taskType}");
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