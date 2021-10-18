
using Armonik.sdk;

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
            byte[] input = taskContext.TaskInput();
            List<int> numbers = List<int>();
            string inputTaskType;
            using (MemoryStream m = new MemoryStream(data))
            {
                using (BinaryReader reader = new BinaryReader(m))
                {
                    inputTaskType = reader.ReadString();

                    if (inputTaskType == "Compute")
                    {
                        byte[] nextTaskInput;
                        int n = reader.ReadInt32();
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
                            SubmitTask(sessionContext.SessionId, nextTaskInput);
                        }
                        writeTaskOutput(taskContext.TaskId, sum);
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