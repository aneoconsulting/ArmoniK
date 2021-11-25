namespace HTCGrid
{
    public interface StorageInterface
    {
        public void put_input_from_utf8_string(string task_id, string data);
        public void put_payload_from_utf8_string(string task_id, string data);
        
        public void put_input_from_bytes(string task_id, byte[] data);
        
        
        public string get_output_to_utf8_string(string task_id);
    }
}