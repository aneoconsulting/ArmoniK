using HTCGrid;
using System.Collections.Generic;
using System;
using Htc.Mock;
using System.Linq;
using System.Text;

namespace HTCGrid
{
    namespace Common
    {
        public class HtcGridClient : IGridClient
        {
            private GridConfig gridConfig_;

            private GridSession gridSession_;

            private HTCGridConnector gridConnector_;

            private TaskController submittedTasks_;

            private HtcDataClient htcDataClient_;

            public HtcGridClient(GridConfig gridConfig, HtcDataClient htcDataClient)
            {
                this.gridConfig_ = gridConfig;

                this.gridConnector_ = new HTCGridConnector(gridConfig);

                this.submittedTasks_ = new TaskController();

                this.htcDataClient_ = htcDataClient;
            }

            public byte[] GetResult(string taskId)
            {
                Encoding.ASCII.GetBytes(submittedTasks_.Get(taskId));
                return new byte[0];
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
                    bool taskFound = false ;

                    if (sessionResponse == null)
                    {
                        Console.WriteLine("sessionResponse = NULL");
                        continue;
                    }

                    Console.WriteLine($"sessionResponse={sessionResponse}");

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
                        Console.WriteLine($"WARN : sessionResponse={sessionResponse}");
                        continue;
                    } else {
                        Console.WriteLine("WARN : printing element in finished state");
                        finishedTasks.ForEach(Console.WriteLine);
                    }

                    submittedTasks_.Add(finishedTasks, sessionResponse.FinishedOutput);
                    
                    /*foreach (var completedTaskId in finishedTasks)
                    {
                        if (completedTaskId == taskId)
                        {
                            taskFound = true ;
                            break ;
                        }
                    }
                    if (taskFound ) break ;*/
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

            public string SubmitTask(string sessionId, byte[] payload)
            {
                Console.WriteLine("INFO : Submit single task ");
                HtcTask htcTask = new HtcTask();
                sessionId = gridSession_.SessionId;
                htcTask.SessionId = sessionId;
                htcTask.Payload = payload;
                Console.WriteLine("Set Payload and Session " + sessionId);
                List<HtcTask> tasksToProcess = new List<HtcTask>();
                tasksToProcess.Add(htcTask);
                if (gridSession_ is null)
                {
                    Console.WriteLine("ERROR : GridSession is null reference ");
                }
                else
                {
                    Console.WriteLine("Ready to send task with gridSession " + gridSession_.GetHashCode());
                }

                string[] task_ids = gridSession_.SendTasks(tasksToProcess.ToArray());
                // throw new NotImplementedException("TODO : Parsing of Agent config isn't implemented");
                return (task_ids != null && task_ids.Length > 0) ? task_ids[0] : "Fail to send";
            }


            public IEnumerable<string> SubmitTasks(string session, IEnumerable<byte[]> payloads)
            {         
                Console.WriteLine($"Will submit tasks for session {session}.");
                
                var result = new List<string>();
                var currentBatch = new List<HtcTask>(500);
                foreach (var payload in payloads)
                {
                    currentBatch.Add(new HtcTask(){SessionId = gridSession_.SessionId, Payload=payload});
                    if(currentBatch.Count()==500)
                    {
                        Console.WriteLine($"(1) Will submit a batch of {currentBatch.Count()} tasks");
                        var ids = gridSession_.SendTasks(currentBatch.ToArray());
                        result.AddRange(ids);
                        currentBatch.Clear();
                    }
                }

                if(currentBatch.Any())
                {
                    Console.WriteLine($"(2) Will submit a batch of {currentBatch.Count()} tasks");
                    var ids = gridSession_.SendTasks(currentBatch.ToArray());
                    result.AddRange(ids);
                    currentBatch.Clear();
                }

                Console.WriteLine($"{result.Count()} tasks submitted for session {session}.");
                return result;
            }

            public string SubmitSubtask(string sessionId, string parentId, byte[] payload)
            {
                string subTaskId = SubmitTask(sessionId, payload);
                htcDataClient_.AddSubTaskId(parentId, subTaskId);

                return subTaskId;
            }

            public IEnumerable<string> SubmitSubtasks(string session, string parentId, IEnumerable<byte[]> payloads)
            {
                throw new NotImplementedException("TODO : Parsing of Agent config isn't implemented");
            }

            public string SubmitTaskWithDependencies(string sessionId, byte[] payload, IList<string> dependencies)
            {
                throw new NotImplementedException("TODO Should be implemente when the scheduler will be able to handle dependecies");
            }

            public IEnumerable<string> SubmitTaskWithDependencies(string session, IEnumerable<(byte[], IList<string>)> payloadWithDependencies)
            {
                throw new NotImplementedException("TODO : Parsing of Agent config isn't implemented");
            }

            public string SubmitSubtaskWithDependencies(string session, string parentId, byte[] payload, IList<string> dependencies)
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
            public IEnumerable<string> SubmitSubtaskWithDependencies(string session, string parentId, IEnumerable<Tuple<byte[], IList<string>>> payloadWithDependencies)
            {
                throw new NotImplementedException("TODO : Parsing of Agent config isn't implemented (SubmitSubtaskWithDependencies)");
            }

            public IEnumerable<string> SubmitTaskWithDependencies(string session, IEnumerable<Tuple<byte[], IList<string>>> payloadWithDependencies)
            {
                throw new NotImplementedException("TODO : Parsing of Agent config isn't implemented (SubmitSubtaskWithDependencies)");
            }

            public IEnumerable<string> SubmitSubtaskWithDependencies(string session, string parentId, IEnumerable<(byte[], IList<string>)> payloadWithDependencies)
            {
                throw new NotImplementedException("TODO : Parsing of Agent config isn't implemented");
            }


            public string CreateSession()
            {

                gridSession_ = this.gridConnector_.CreateSession();
                Console.WriteLine("DEBUG : CreateSession " + gridSession_.SessionId);

                GridContext context = new GridContext();
                context.tasks_priority = 0;
                gridSession_.SetContext(context);

                return gridSession_.SessionId;
            }

            public IDisposable OpenSession(string sessionId)
            {
                //gridSession_ = this.gridConnector_.OpenSession(sessionId);
                gridSession_ = this.gridConnector_.CreateSession();
                Console.WriteLine("DEBUG : OpenSession with Id " + gridSession_.SessionId);

                GridContext context = new GridContext();
                context.tasks_priority = 0;
                gridSession_.SetContext(context);
                return null;
            }

            public void CancelSession(string session)
            {
                throw new NotImplementedException("TODO : Parsing of Agent config isn't implemented");
            }

            public void CancelTask(string taskId)
            {
                throw new NotImplementedException("TODO : Parsing of Agent config isn't implemented");
            }


        }
    }
}