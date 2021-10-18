using System;
using System.Runtime.Serialization;
using StackExchange.Redis;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Collections;
using System.IO;
using System.Text.Json;

using HTCGrid;

namespace csharp
{


    class Program
    {
        static void Main(string[] args)
        {
            string agentConfigFileName = Environment.GetEnvironmentVariable("AGENT_CONFIG_FILE") ;
            if (agentConfigFileName == null) {
                agentConfigFileName  = "/etc/agent/Agent_config.tfvars.json";
            }
            JsonDocument  parsedConfig = null ;
            try
            {

                FileStream fsSource = new FileStream(agentConfigFileName,FileMode.Open, FileAccess.Read);
                parsedConfig = JsonDocument.Parse(fsSource) ;

            }
            catch (FileNotFoundException ioEx)
            {
                Console.WriteLine(ioEx.Message);
            }

            ////////////////////////////////////////////////////////////////////
            //// 1. HTC-Grid Connection ////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            GridConfig gridConfig = new GridConfig();
            gridConfig.Init(parsedConfig);

            HTCGridConnector gridConnector =  new HTCGridConnector(gridConfig);

            GridSession gridSession = gridConnector.CreateSession();

            ////////////////////////////////////////////////////////////////////
            //// 2. CACHE WARM UP STAGE ////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            Console.WriteLine("Connecting");
			string redis_endpoint_url = String.Format("{0},ssl={1},connectTimeout={2}", gridConfig.redis_endpoint_url, gridConfig.redis_with_ssl, gridConfig.connection_redis_timeout);
            ConnectionMultiplexer connection = ConnectionMultiplexer.Connect(redis_endpoint_url);
			

            IDatabase db = connection.GetDatabase();

            db.StringSet("trade_data_key_1", 100);
            db.StringSet("trade_data_key_2", 200);
            db.StringSet("trade_data_key_3", 300);


            ////////////////////////////////////////////////////////////////////
            //// 2. HTC-Grid Connection ////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////


            GridContext context = new GridContext();
            context.tasks_priority = 0;

            gridSession.SetContext(context);

            ////////////////////////////////////////////////////////////////////
            //// 3. Tasks preparation  /////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            ClientTask clientTask_1 = new ClientTask(
                0,                  // fixed number of sub tasks per level
                0,                  // fixed number of sub tasks levels
                "trade_data_key_1", // reference to cached trade data
                1000                // mock compute time (ms)
                );

            ClientTask clientTask_2 = new ClientTask(1, 0, "trade_data_key_2", 1000);
            ClientTask clientTask_3 = new ClientTask(1, 0, "trade_data_key_3", 1000);

            List<ClientTask> tasksToProcess = new List<ClientTask>();
            for(int i = 0; i < 1; i++)
            {
                tasksToProcess.Add(new ClientTask(0, 0, "trade_data_key_2", 10*i));
                //Console.WriteLine("Value of i: {0}", i);
            }
            //tasksToProcess.Add(clientTask_1);
            //tasksToProcess.Add(clientTask_2);
            //tasksToProcess.Add(clientTask_3);
            


            ////////////////////////////////////////////////////////////////////
            //// 4. Tasks submission  //////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            gridSession.SendTasks(tasksToProcess.ToArray());

            context.tasks_priority = 1;
            gridSession.SendTasks(tasksToProcess.ToArray());

            context.tasks_priority = 2;
            gridSession.SendTasks(tasksToProcess.ToArray());

            ////////////////////////////////////////////////////////////////////
            //// 5. Results collection /////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////


            Hashtable processedTasks = new Hashtable();
            for (int i = 0; i < 100 ; i++) {
                System.Threading.Thread.Sleep(1000);
                var sessionResponse = gridSession.CheckResults();

                if (sessionResponse == null) {
                    continue;
                }

                List<string> finishedTasks = sessionResponse.Finished;

                if (finishedTasks == null) {
                    continue;
                }

                foreach(string taskId in finishedTasks) {

                    if (!processedTasks.ContainsKey(taskId)) {

                        processedTasks.Add(taskId, taskId);

                        var serializedString = db.StringGet(taskId+"-output");
                        var base64EncodedBytes = System.Convert.FromBase64String(serializedString);
                        var result = System.Text.Encoding.UTF8.GetString(base64EncodedBytes);

                        Console.WriteLine(String.Format("\tTaskId {0} \t Result: {1}", taskId, result));
                    }
                }

                if (sessionResponse.Metadata.TasksInResponse == gridSession.GetSessionSize()) {
                    Console.WriteLine(String.Format("\tTaskId {0} Result: {1}",
                        sessionResponse.Metadata.TasksInResponse , tasksToProcess.Count));
                    break;
                }
            }
        }
    }
}
