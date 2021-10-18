using System;
using HTCGrid;

namespace csharp
{

    public class  ClientTask : GridTask {

        public ClientTask(int subtasks_count, int depth, string trade_data_key, int sleep_time_ms) {
            this.subtasks_count = subtasks_count;
            this.depth = depth;
            this.trade_data_key = trade_data_key;
            this.sleep_time_ms = sleep_time_ms;
        }

        public int subtasks_count;
        public int depth;
        public string trade_data_key;
        public int sleep_time_ms;



    }

    // public class
}
