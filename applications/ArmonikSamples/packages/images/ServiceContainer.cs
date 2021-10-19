
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

        public void Compute(TaskContext taskContext, ClientPayload clientPayload)
        {
            if (clientPayload.numbers.Count == 0) return; // Nothing to do

            if (clientPayload.numbers.Count == 1)
            {
                int value = clientPayload.numbers[0] * clientPayload.numbers[0];
                writeTaskOutput(taskContext.TaskId, BitConverter.GetBytes(value));
            }
            else if (clientPayload.numbers.Count > 1)
            {
                int value = clientPayload.numbers[0];
                int square = value * value;

                var subTaskPaylaod = new ClientPayload();
                clientPayload.numbers.RemoveAt(0);
                subTaskPaylaod.numbers = clientPayload.numbers;

                var subTaskId = this.SubmitTask(subTaskPaylaod.serialize());

                htcGridClient.WaitCompletion(subTaskId);
                byte[] arr = htcDataClient.GetData(subTaskId);
                int subResult = BitConverter.ToInt32(arr);

                writeTaskOutput(taskContext.TaskId, BitConverter.GetBytes(square + subResult));
            }
        }

        public override void OnInvoke(SessionContext sessionContext, TaskContext taskContext)
        {
            var clientPayload = ClientPayload.deserialize(taskContext.TaskInput);

            Compute(taskContext, clientPayload);
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