using System;
using System.Text;
using StackExchange.Redis;
using HTCGrid;
using System.Collections;
using System.Collections.Generic;

namespace Armonik.sdk
{

    public class HtcDataClient : IDataClient
    {
        private GridConfig gridConfig_;
        private ConnectionMultiplexer connection_;
        private IDatabase db_;
        public HtcDataClient(GridConfig gridConfig)
        {
            gridConfig_ = gridConfig;
        }

        public void ConnectDB()
        {
            var configurationOptions = RedisConfigurationFactory.createConfiguration(gridConfig_);
            Console.WriteLine($"(HtcDataClient) Redis Connecting to URL: ({configurationOptions.EndPoints[0]}, ssl={configurationOptions.Ssl}, connectTimeout={configurationOptions.ConnectTimeout})");
            connection_ = ConnectionMultiplexer.Connect(configurationOptions);
            Console.WriteLine("(HtcDataClient) Redis Connecting successful");
            db_ = connection_.GetDatabase();
        }

        public byte[] GetData(string key)
        {
            return db_.StringGet(key);
        }

        public void StoreData(string key, byte[] data)
        {
            db_.StringSet(key, data);
        }

        public Queue<string> getSubTaskId(string taskId)
        {
            byte[] data = GetData(String.Format("{0}-subtasks", taskId));

            if (data?.Length > 0)
            {
                string list_taskId = Encoding.ASCII.GetString(data) + String.Format(";{0}", taskId);
                return new Queue<string>(list_taskId.Split(";"));
            }
            else
                return new Queue<string>();
        }



        public void AddSubTaskId(string parentId, string taskId)
        {
            byte[] data = GetData(String.Format("{0}-subtasks", taskId));
            if (data?.Length > 0)
            {
                string list_taskId = Encoding.ASCII.GetString(data) + String.Format(";{0}", taskId);
                StoreData(String.Format("{0}-subtasks", parentId), Encoding.ASCII.GetBytes(list_taskId));
            }
            else
            {
                StoreData(String.Format("{0}-subtasks", parentId), Encoding.ASCII.GetBytes(taskId));
            }
        }
    }
}
