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
        private static IServiceContainer serviceContainer;
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

            HtcDataClient htcDataClient = new HtcDataClient(gridConfig_);
            htcDataClient.ConnectDB();

            HtcGridClient htcGridClient = new HtcGridClient(gridConfig_, htcDataClient);

            serviceContainer = new ServiceContainer();
            serviceContainer.htcDataClient = htcDataClient;
            serviceContainer.htcGridClient = htcGridClient;

            firstRun = true;

            // Grid initialize gridWorker_ = new()
            gridWorker = new GridWorker(serviceContainer);
            gridWorker.htcDataClient = htcDataClient;
            gridWorker.htcGridClient = htcGridClient;

            // gridWorker_ = new(new DelegateRequestRunnerFactory((runConfiguration, sessionId)
            //                                                   =>  new DistributedRequestRunnerWithAggregation(htcDataClient,
            //                                                                                   htcGridClient,
            //                                                                                   runConfiguration,
            //                                                                                   sessionId,
            //                                                                                   fastCompute: false,
            //                                                                                   useLowMem: false,
            //                                                                                   smallOutput: false)));

            gridWorker.OnStart();

            // girdWoorker_.onServiceCreate(serviceContainer)
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
                gridWorker.OnSessionEnter(inputTask.SessionId, inputTask.TaskId, inputTask.Payload);
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
