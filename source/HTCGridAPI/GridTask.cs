using System;

namespace HTCGrid
{
    public class GridTask
    {
        public string taskId;


        public GridTask() {

        }

        public virtual void SetSessionId(string session_id) {

        }

        public virtual object GetTask() {
            return null;
        }

        public string TaskId { get { return taskId; } set { taskId = value; } }

    }
}