using System;
using HTCGrid;


namespace Armonik.sdk
{
    public class HtcTask : GridTask
    {
        public HtcTask()
        {

        }

        public int subtasks_count;
        public int depth;
        public int sleep_time_ms;
        public int debug;

        public string sessionId_;

        public string SessionId { get { return sessionId_; } set { sessionId_ = value; } }
        public byte[] payload_;

        public byte[] Payload
        {
            get { return payload_; }

            set { payload_ = value; }
        }
    }
}