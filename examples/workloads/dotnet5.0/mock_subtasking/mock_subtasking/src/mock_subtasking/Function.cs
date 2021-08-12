using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.IO;
using System.Text.Json;
using StackExchange.Redis;

using Amazon.Lambda.Core;

using HTCGrid;
// using GridClient;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace mock_subtasking
{
    public class Function
    {
        
        public string FunctionHandler(ClientTask inputTask, ILambdaContext context)
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
     
            
            ////////////////////////////////////////////////////////////////////
            //// 2. Get Trade Data from Cache //////////////////////////////////
            ////////////////////////////////////////////////////////////////////
            
            Console.WriteLine("Connecting");
            //ConnectionMultiplexer connection = ConnectionMultiplexer.Connect(gridConfig.redis_url+":6379,ssl=true");
			string redis_endpoint_url = String.Format("{0}:{1},ssl={2},connectTimeout={3}", gridConfig.redis_url, gridConfig.redis_port, gridConfig.redis_with_ssl, gridConfig.connection_redis_timeouts);
            ConnectionMultiplexer connection = ConnectionMultiplexer.Connect(redis_endpoint_url);
            IDatabase db = connection.GetDatabase();
            
            int trade_data = (int)db.StringGet(inputTask.trade_data_key);
            Console.WriteLine(trade_data);
            
            ////////////////////////////////////////////////////////////////////
            //// 3. Do computation /////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////
            
            trade_data = trade_data * 10;
            
            System.Threading.Thread.Sleep(inputTask.sleep_time_ms);
            

            ////////////////////////////////////////////////////////////////////
            //// 4. Launch Sub-tasks ///////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            if (inputTask.depth > 0) {
                
                
                HTCGridConnector gridConnector =  new HTCGridConnector(gridConfig);
            
                GridSession gs = gridConnector.CreateSession();
                
                List<ClientTask> tasksToProcess = new List<ClientTask>();
                
                for (int i = 0; i < inputTask.subtasks_count; i++) {
                    
                    ClientTask ct = new ClientTask(
                        inputTask.subtasks_count, 
                        inputTask.depth - 1, 
                        inputTask.trade_data_key,
                        inputTask.sleep_time_ms);
                        
                    tasksToProcess.Add(ct);
                }
                
                gs.SendTasks(tasksToProcess.ToArray());
            }
        
            Console.WriteLine("Hello World from Client-3");
            
            ////////////////////////////////////////////////////////////////////
            //// 4. Return Results /////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            return $"{trade_data}";
        }

    }

    public record Casing(string Lower, string Upper);
}
