using System;
 
using StackExchange.Redis;
 
namespace HTCGrid
{
    public class InOutRedis:StorageInterface
    {
        
        public InOutRedis(string redis_url) {
            Console.WriteLine("Redis Connecting to URL");
            Console.WriteLine(redis_url);
            
            ConnectionMultiplexer connection = 
                ConnectionMultiplexer.Connect(redis_url+":6379,ssl=true,connectTimeout=300000");
            
            this.db = connection.GetDatabase();
        }
        
        private IDatabase db;
        
        /* A task_id is used as a unique key to reference the data in the control plane. 
        However, each task has several data points associated, 
        e.g., input data, output data, error, etc. 
        Thus, we have a special postfixes to provide unique keys for each task. 
        */
        private const string INPUT_POSTFIX = "-input";
        private const string OUTPUT_POSTFIX = "-output";
        private const string ERROR_POSTFIX = "-error";
        private const string PAYLOAD_POSTFIX = "-payload";
        
        
        public void put_input_from_utf8_string(string task_id, string data) {
            put_from_string(task_id, data, INPUT_POSTFIX);
        }
        
        public void put_payload_from_utf8_string(string task_id, string data) {
            put_from_string(task_id, data, PAYLOAD_POSTFIX);
        }
        
        public void put_input_from_bytes(string task_id, byte[] data) {
            put_from_bytes(task_id, data, INPUT_POSTFIX);
        }
        
        
        public string get_output_to_utf8_string(string task_id) {
            return get_to_utf8_string(task_id, OUTPUT_POSTFIX);
        }
        
        
        ///////////////////////////////////////////////////////////////////////////////////////////
        
        private string get_full_key(string key, string postfix) {
            return key + postfix;
        }
        
        private void put_from_string(string key, string data, string postfix) {
            db.StringSet(this.get_full_key(key, postfix), data);
        }
        
        private void put_from_bytes(string key, byte[] data, string postfix) {
            db.StringSet(this.get_full_key(key, postfix), data);
        }
        
        ///////////////////////////////////////////////////////////////////////////////////////////
        
        public string get_to_utf8_string(string key, string postfix) {
            return db.StringGet(this.get_full_key(key, postfix));
        }
        
        

    }
}
