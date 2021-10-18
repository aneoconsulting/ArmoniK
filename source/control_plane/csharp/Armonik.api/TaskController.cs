using HTCGrid;
using System.Collections.Generic;
using System;
using System.Linq;

using System.Collections.Concurrent;

namespace Armonik.sdk
{
    public class TaskController
    {
        private readonly ConcurrentDictionary<string, string> tasksResults_ = new ConcurrentDictionary<string, string>();

        public bool AleradyFinished(string taskId)
        {
            return tasksResults_.ContainsKey(taskId);
        }

        public void Add(IList<string> taskIds, IList<string> finishedOutputs)
        {
            foreach (var task in taskIds.Zip(finishedOutputs, Tuple.Create))
            {
                if (!AleradyFinished(task.Item1))
                {
                    tasksResults_[task.Item1] = task.Item2;
                }
            }
        }

        public string Get(string taskId)
        {
            if (AleradyFinished(taskId))
            {
                return tasksResults_[taskId];
            }

            return "";
        }
    }
}
