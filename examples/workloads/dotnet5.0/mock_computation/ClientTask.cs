using System;
using HTCGrid;

namespace mock_computation_image
{
    
    public class  ClientTask : GridTask {         
        
        public ClientTask(int subtasks_count, int depth, string trade_data_key, int sleep_time_ms) {
            this.subtasks_count = subtasks_count;
            this.depth = depth;
            this.trade_data_key = trade_data_key;
            this.sleep_time_ms = sleep_time_ms;
        }
        
// 		public string firstName { get; set; }
// 		public int sleepTimeMs { get; set; }
// 		public string surname { get; set; }
	
        public int subtasks_count { get; set; }
        public int depth { get; set; }
        public string trade_data_key { get; set; }
        public int sleep_time_ms { get; set; }

    }
    
    
    public class ClientResponse {
        public ClientResponse(int value) {
            this.value = value;
        }
        public int value;
    }
    
}
