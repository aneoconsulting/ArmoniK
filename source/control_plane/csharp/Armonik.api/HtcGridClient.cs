using HTCGrid;
using System.Collections.Generic;
using System;
using System.Linq;
using System.Text;

namespace Armonik.sdk
{
    public class HtcGridClient : IGridClient
    {
        private GridConfig gridConfig_;

        private GridSession gridSession_;
    
        private HTCGridConnector gridConnector_;

        private TaskController submittedTasks_;

        private HtcDataClient htcDataClient_;

        public string SessionId => gridSession_.SessionId;

        private HtcGridClient(GridConfig gridConfig, HtcDataClient htcDataClient, int dummy=0)
        {
            gridConfig_ = gridConfig;
            gridConnector_ = new HTCGridConnector(gridConfig);
            submittedTasks_ = new TaskController();
            htcDataClient_ = htcDataClient;
            GridContext context = new GridContext();
            context.tasks_priority = 0;
            gridSession_.SetContext(context);
        }

        public HtcGridClient(GridConfig gridConfig, HtcDataClient htcDataClient):this(gridConfig, htcDataClient, 0)
        {
            this.gridSession_ = this.gridConnector_.CreateSession();
        }

        public HtcGridClient(GridConfig gridConfig, HtcDataClient htcDataClient, string sessionId):this(gridConfig, htcDataClient, 0)
        {
            this.gridSession_ = this.gridConnector_.OpenSession(sessionId);
        }

        public byte[] GetResult(string taskId)
        {
            return htcDataClient_.GetData(taskId);
        }

        //TODO change signature to get a default timeout time in seconds
        public void WaitCompletion(string taskId)
        {
            Console.WriteLine("Start WaitCompletion");
            int timeOut = 600; // 10 min
            if (submittedTasks_.AleradyFinished(taskId))
                return;
            Console.WriteLine("Check result WaitCompletion");

            for (int i = 0; i < timeOut; i++)
            {
                System.Threading.Thread.Sleep(1000);
                var sessionResponse = gridSession_.CheckResults();

                if (sessionResponse == null)
                {
                    Console.WriteLine("sessionResponse = NULL");
                    continue;
                }

                if (sessionResponse.Cancelled != null && sessionResponse.Cancelled.Any())
                {
                    Console.WriteLine(String.Format("WARN :  Task {0} cancelled ", taskId));
                    break;
                }

                if (sessionResponse.Failed != null && sessionResponse.Failed.Any())
                {
                    Console.WriteLine(String.Format("ERROR :  Task {0} failed ", taskId));
                    break;
                }

                List<string> finishedTasks = sessionResponse.Finished;

                if (finishedTasks == null || !finishedTasks.Any())
                {
                    Console.WriteLine(String.Format("WARN :  Task {0} no result available", taskId));
                    continue;
                }
                else
                {
                    Console.WriteLine("WARN : printing element in finished state");
                    finishedTasks.ForEach(Console.WriteLine);
                }

                submittedTasks_.Add(finishedTasks, sessionResponse.FinishedOutput);

                if (submittedTasks_.AleradyFinished(taskId))
                {
                    Console.WriteLine("INFO: Task {0} finished", taskId);
                    return;
                }
            }
        }

        public void WaitSubtasksCompletion(string parentId)
        {
            WaitCompletion(parentId);
            Queue<string> subtasks = htcDataClient_.getSubTaskId(parentId);

            while (subtasks.Any())
            {
                string subTaskId = subtasks.Dequeue();
                WaitCompletion(subTaskId);
                Queue<string> tasks = htcDataClient_.getSubTaskId(subTaskId);
                while (tasks.Any())
                    subtasks.Enqueue(tasks.Dequeue());
            }
        }

        public IEnumerable<string> SubmitTasks(IEnumerable<byte[]> payloads)
        {
            Console.WriteLine($"Will submit tasks for session {gridSession_.SessionId}.");

            var result = new List<string>();
            var currentBatch = new List<HtcTask>(500);
            foreach (var payload in payloads)
            {
                currentBatch.Add(new HtcTask() { SessionId = gridSession_.SessionId, Payload = payload, debug = gridConfig_.debug });
                if (currentBatch.Count() == 500)
                {
                    Console.WriteLine($"(1) Will submit a batch of {currentBatch.Count()} tasks");
                    var ids = gridSession_.SendTasks(currentBatch.ToArray());
                    result.AddRange(ids);
                    currentBatch.Clear();
                }
            }

            if (currentBatch.Any())
            {
                Console.WriteLine($"(2) Will submit a batch of {currentBatch.Count()} tasks");
                var ids = gridSession_.SendTasks(currentBatch.ToArray());
                result.AddRange(ids);
                currentBatch.Clear();
            }

            Console.WriteLine($"{result.Count()} tasks submitted for session {gridSession_.SessionId}.");
            return result;
        }

        public string SubmitSubtask(string parentId, byte[] payload)
        {
            string subTaskId = this.SubmitTask(payload);
            htcDataClient_.AddSubTaskId(parentId, subTaskId);

            return subTaskId;
        }

        public IEnumerable<string> SubmitSubtasks(string parentId, IEnumerable<byte[]> payloads)
        {
            throw new NotImplementedException("TODO : Parsing of Agent config isn't implemented");
        }

        public string SubmitTaskWithDependencies(byte[] payload, IList<string> dependencies)
        {
            throw new NotImplementedException("TODO Should be implemente when the scheduler will be able to handle dependecies");
        }

        public IEnumerable<string> SubmitTaskWithDependencies(IEnumerable<(byte[], IList<string>)> payloadWithDependencies)
        {
            throw new NotImplementedException("TODO : Parsing of Agent config isn't implemented");
        }

        public string SubmitSubtaskWithDependencies(string parentId, byte[] payload, IList<string> dependencies)
        {
            throw new NotImplementedException("TODO Should be implemente when the scheduler will be able to handle dependecies");

            // string subTaskId = SubmitSubtask(sessonId, parentId, payload);

            // htcGridClient_.AddSubTaskId(parentId, subTaskId);

            // foreach (string taskId in dependencies)
            // {
            //     htcGridClient_.AddSubTaskId(subTaskId, taskId);
            // }

            // return subTaskId;
        }
        public IEnumerable<string> SubmitSubtaskWithDependencies(string parentId, IEnumerable<Tuple<byte[], IList<string>>> payloadWithDependencies)
        {
            throw new NotImplementedException("TODO : Parsing of Agent config isn't implemented (SubmitSubtaskWithDependencies)");
        }

        public IEnumerable<string> SubmitTaskWithDependencies(IEnumerable<Tuple<byte[], IList<string>>> payloadWithDependencies)
        {
            throw new NotImplementedException("TODO : Parsing of Agent config isn't implemented (SubmitSubtaskWithDependencies)");
        }

        public IEnumerable<string> SubmitSubtaskWithDependencies(string parentId, IEnumerable<(byte[], IList<string>)> payloadWithDependencies)
        {
            throw new NotImplementedException("TODO : Parsing of Agent config isn't implemented");
        }

        public void CancelSession()
        {
            if (gridSession_ != null)
                gridSession_.CancelSession();
        }

        public void CancelTask(string taskId)
        {
            throw new NotImplementedException("TODO : Parsing of Agent config isn't implemented");
        }
    }
}