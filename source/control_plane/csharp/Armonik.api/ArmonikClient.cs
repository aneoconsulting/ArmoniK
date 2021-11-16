using HTCGrid;
using System.Collections.Generic;
using System.Linq;

namespace Armonik.sdk
{
    public class ArmonikClient
    {
        private HtcGridClient htcGridClient_;
        private HtcDataClient htcDataClient_;
        private GridConfig gridConfig_;

        public ArmonikClient(GridConfig gridConfig)
        {
            gridConfig_ = gridConfig;
            htcDataClient_ = new HtcDataClient(gridConfig_);
            htcGridClient_ = new HtcGridClient(gridConfig_, htcDataClient_);
            htcDataClient_.ConnectDB();
        }

        /// <summary>
        /// User call to get customer data from client (Server side)
        /// </summary>
        /// <param name="key">
        /// The user key that can be retrieved later from client side.
        /// </param>
        public byte[] GetData(string key)
        {
            return htcDataClient_.GetData(key);
        }

        /// <summary>
        /// User method to submit task from the client
        /// </summary>
        /// <param name="payloads">
        /// The user payload list to execute. Generaly used for subtasking.
        /// </param>
        public IEnumerable<string> SubmitTasks(IEnumerable<byte[]> payloads)
        {
            return htcGridClient_.SubmitTasks(payloads);
        }

        /// <summary>
        /// User method to wait for tasks from the client
        /// </summary>
        /// <param name="taskID">
        /// The task id of the task
        /// </param>
        public void WaitCompletion(string taskId)
        {
            htcGridClient_.WaitCompletion(taskId);
        }
    }
    public static class ArmonikClientExt
    {
        /// <summary>
        /// User method to submit task from the client
        /// </summary>
        /// <param name="payload">
        /// The user payload to execute.
        /// </param>
        public static string SubmitTask(this ArmonikClient client, byte[] payload)
        {
            return client.SubmitTasks(new[] { payload })
                                   .Single();
        }
    }
}