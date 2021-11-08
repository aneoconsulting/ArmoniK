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

        private HtcGridClient(GridConfig gridConfig, HtcDataClient htcDataClient, int dummy = 0)
        {
            gridConfig_ = gridConfig;
            gridConnector_ = new HTCGridConnector(gridConfig);
            submittedTasks_ = new TaskController();
            htcDataClient_ = htcDataClient;
        }

        public HtcGridClient(GridConfig gridConfig, HtcDataClient htcDataClient) : this(gridConfig, htcDataClient, 0)
        {
            this.gridSession_ = this.gridConnector_.CreateSession();
            GridContext context = new GridContext();
            context.tasks_priority = 0;
            gridSession_.SetContext(context);
        }

        public HtcGridClient(GridConfig gridConfig, HtcDataClient htcDataClient, string sessionId) : this(gridConfig, htcDataClient, 0)
        {
            this.gridSession_ = this.gridConnector_.OpenSession(sessionId);
            GridContext context = new GridContext();
            context.tasks_priority = 0;
            gridSession_.SetContext(context);
        }

        public byte[] GetResult(string taskId)
        {
            return htcDataClient_.GetData(taskId);
        }

        //TODO change signature to get a default timeout time in seconds
        public void WaitCompletion(string taskId)
        {
            Logger.Debug("Start WaitCompletion");
            int timeOut = 600; // 10 min
            if (submittedTasks_.AleradyFinished(taskId))
                return;

            for (int i = 0; i < timeOut; i++)
            {
                System.Threading.Thread.Sleep(1000);
                var sessionResponse = gridSession_.CheckResults();

                if (sessionResponse == null)
                {
                    Logger.Error("sessionResponse = NULL");
                    continue;
                }

                if (sessionResponse.Cancelled != null && sessionResponse.Cancelled.Any())
                {
                    Logger.Debug(String.Format("Task {0} cancelled ", taskId));
                    break;
                }

                if (sessionResponse.Failed != null && sessionResponse.Failed.Any())
                {
                    Logger.Error(String.Format("Task {0} failed ", taskId));
                    break;
                }

                List<string> finishedTasks = sessionResponse.Finished;

                if (finishedTasks == null || !finishedTasks.Any())
                {
                    Logger.Debug(String.Format("Task {0} no result available", taskId));
                    continue;
                }
                else
                {
                    if (Logger.isDebug())
                    {
                        Logger.Debug("printing element in finished state");
                        foreach (var task in finishedTasks)
                        {
                            Logger.Debug(task);
                        }
                    }
                }

                submittedTasks_.Add(finishedTasks, sessionResponse.FinishedOutput);

                if (submittedTasks_.AleradyFinished(taskId))
                {
                    Logger.Info($"Task {taskId} finished");
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
            Logger.Info($"Tasks submission for session {gridSession_.SessionId}.");

            var result = new List<string>();
            var currentBatch = new List<HtcTask>(500);
            foreach (var payload in payloads)
            {
                currentBatch.Add(new HtcTask() { SessionId = gridSession_.SessionId, Payload = payload, debug = gridConfig_.debug });
                if (currentBatch.Count() == 500)
                {
                    Logger.Debug($"(1) Will submit a batch of {currentBatch.Count()} tasks");
                    var ids = gridSession_.SendTasks(currentBatch.ToArray());
                    result.AddRange(ids);
                    currentBatch.Clear();
                }
            }

            if (currentBatch.Any())
            {
                Logger.Debug($"(2) Will submit a batch of {currentBatch.Count()} tasks");
                var ids = gridSession_.SendTasks(currentBatch.ToArray());
                result.AddRange(ids);
                currentBatch.Clear();
            }

            Logger.Info($"{result.Count()} tasks submitted for session {gridSession_.SessionId}.");
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