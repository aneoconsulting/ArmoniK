
using Armonik.sdk;
using System;
using System.IO;
using System.Collections.Generic;

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
            List<int> numbers = new List<int>();
            string inputTaskType;
            using (MemoryStream m = new MemoryStream(taskContext.TaskInput))
            {
                using (BinaryReader reader = new BinaryReader(m))
                {
                    inputTaskType = reader.ReadString();

                    if (inputTaskType == "Compute")
                    {
                        byte[] nextTaskInput;
                        int n = reader.ReadInt32();
                        List<string> taskIds = new List<string>();
                        for (int i = 0; i < n; i++)
                        {
                            int c = reader.ReadInt32();

                            using (MemoryStream m2 = new MemoryStream())
                            {
                                using (BinaryWriter writer = new BinaryWriter(m2))
                                {
                                    writer.Write("Squarre");
                                    writer.Write(c);
                                }
                                nextTaskInput = m2.ToArray();
                            }
                            taskIds.Add(SubmitTask(sessionContext.SessionId, nextTaskInput));
                        }
                        int sum = 0;
                        foreach (var task in taskIds)
                        {
                            HtcGridClient.WaitCompletion(task);
                            sum += BitConverter.ToInt32(GetData(task), 0);
                        }
                        writeTaskOutput(taskContext.TaskId, BitConverter.GetBytes(sum));
                    }
                    else if (inputTaskType == "Squarre")
                    {
                        int c = reader.ReadInt32();
                        writeTaskOutput(taskContext.TaskId, BitConverter.GetBytes(c * c));
                    }
                }
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