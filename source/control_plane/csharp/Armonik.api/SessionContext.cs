namespace Armonik.sdk
{
    /// <summary>
    /// Container for the information associated with a particular Session.
    /// Such information may be required during the servicing of a task from a Session.
    /// </summary>
    public class SessionContext
    {
        /// <summary>
        ///
        /// </summary>
        public bool IsDebugMode { get { return (timeRemoteDebug > 0); } }

        /// <summary>
        ///
        /// </summary>
        public int timeRemoteDebug;

        /// <summary>
        ///
        /// </summary>
        /// <value></value>
        public string SessionId { get; set; }

        /// <summary>
        ///
        /// </summary>
        /// <value></value>
        public string clientLibVersion { get; set; }
    }
}