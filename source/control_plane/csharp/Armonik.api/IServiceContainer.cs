using HTCGrid;
using System.Text;

namespace Armonik.sdk
{
    public abstract class IServiceContainer
    {
        /// <summary>
        ///
        /// </summary>
        /// <value></value>
        HtcGridClient htcGridClient
        {
            get;
            set;
        }
        /// <summary>
        ///
        /// </summary>
        /// <value></value>
        HtcDataClient htcDataClient { get; set; }

        /// <summary>
        /// The middleware triggers the invocation of this handler just after a Service Instance is started.
        /// The application developer must put any service initialization into this handler. Default implementation does nothing.
        /// </summary>
        /// <param name="serviceContext">
        /// Holds all information on the state of the service at the start of the execution.
        /// </param>
        public abstract void OnCreateService(ServiceContext serviceContext);



        /// <summary>
        /// This handler is executed once after the callback OnCreateService and before the OnInvoke
        /// </summary>
        /// <param name="sessionContext">
        /// Holds all information on the state of the session at the start of the execution.
        /// </param>
        public abstract void OnSessionEnter(SessionContext sessionContext);




        /// <summary>
        /// The middleware triggers the invocation of this handler every time a task input is sent to the service to be processed.
        /// The actual service logic should be implemented in this method. This is the only method that is mandatory for the application developer to implement.
        /// </summary>
        /// <param name="sessionContext">
        /// Holds all information on the state of the session at the start of the execution such as session ID.
        /// </param>
        /// <param name="taskContext"
        /// Holds all information on the state of the task such as the task ID and the paykload.
        /// ></param>
        public abstract void OnInvoke(SessionContext sessionContext, TaskContext taskContext);



        /// <summary>
        /// The middleware triggers the invocation of this handler to unbind the Service Instance from its owning Session.
        /// This handler should do any cleanup for any resources that were used in the onSessionEnter() method.
        /// </summary>
        /// <param name="sessionContext">
        /// Holds all information on the state of the session at the start of the execution such as session ID.
        /// </param>
        public abstract void OnSessionLeave(SessionContext sessionContext);



        /// <summary>
        /// The middleware triggers the invocation of this handler just before a Service Instance is destroyed.
        /// This handler should do any cleanup for any resources that were used in the onCreateService() method.
        /// </summary>
        /// <param name="serviceContext">
        /// Holds all information on the state of the service at the start of the execution.
        /// </param>
        public abstract void OnDestroyService(ServiceContext serviceContext);



        /// <summary>
        /// User call to insert customer result data from task (Server side)
        /// </summary>
        /// <param name="key">
        /// The user key that can be retrieved later from client side.
        /// </param>
        /// <param name="value">
        /// The data value to put in the database.
        /// </param>
        public void writeTaskOutput(string key, byte[] value)
        {
            htcDataClient.StoreData(key, value);
        }

        /// <summary>
        /// User method to submit task from the service
        /// </summary>
        /// <param name="sessionId">
        /// The session id to attach the new task.
        /// </param>
        /// <param name="payload">
        /// The user payload to execute. Generaly used for subtasking.
        /// </param>
        public void SubmitTask(string sessionId, byte[] payload)
        {
            htcGridClient.SubmitTask(sessionId, payload);
        }
    }
}