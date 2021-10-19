using System;
using System.Collections.Generic;
using System.Linq;
using System.Collections;
using System.IO;

using System.Threading.Tasks;
using StackExchange.Redis;
using Newtonsoft.Json;
using System.Text.Json;

using Amazon.Lambda.Core;

using HTCGrid;
using Armonik.sdk;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace ArmonikSamples
{
    public class Function
    {
        private static GridWorker gridWorker;

        private static bool firstRun;
        private static GridConfig gridConfig_;

        static Function()
        {
            string agentConfigFileName = Environment.GetEnvironmentVariable("AGENT_CONFIG_FILE") ;

            if (agentConfigFileName == null) {
                //agentConfigFileName  = "/etc/agent/Agent_config.tfvars.json";
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
                LambdaLogger.Log("FileNotFoundException: " + JsonConvert.SerializeObject(ioEx.Message));
                throw ioEx;
            }

            gridConfig_ = new GridConfig();

            gridConfig_.Init(parsedConfig);

            firstRun = true;

            gridWorker = new GridWorker();

            gridWorker.RegisterServiceContainer(new ServiceContainer());
            gridWorker.OnStart();
        }

        public string FunctionHandler(HtcTask inputTask, ILambdaContext context)
        {
            ////////////////////////////////////////////////////////////////////
            //// 1. First extract payload, sessionId ///////////////////////////
            ////////////////////////////////////////////////////////////////////
            Console.WriteLine("Info: " + "New SessionId is coming from Armonik Client : " + inputTask.SessionId);

            ////////////////////////////////////////////////////////////////////
            //// 2. Do computation /////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            if (firstRun)
            {
                gridWorker.OnSessionEnter(gridConfig_, inputTask);
                firstRun = false;
            }

            Console.WriteLine("New Payload : ");


            gridWorker.Execute(inputTask.SessionId, inputTask.TaskId, inputTask.Payload);

            // trade_data = trade_data * 10;

            // System.Threading.Thread.Sleep(inputTask.sleep_time_ms);


            // // ////////////////////////////////////////////////////////////////
            // // 3. Launch Sub-tasks ///////////////////////////////////////////
            // // ////////////////////////////////////////////////////////////////

            Console.WriteLine("Info: " + "Task finished");

            ////////////////////////////////////////////////////////////////////
            //// 4. Return Results /////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            return "END OF TASK";
        }

    }

    public record Casing(string Lower, string Upper);
}
