using System;
using System.Collections.Generic;
using System.Linq;
using System.Collections;
using System.IO;

using System.Threading.Tasks;
using System.Threading;
using StackExchange.Redis;
using Newtonsoft.Json;
using System.Text.Json;

using Amazon.Lambda.Core;

using HTCGrid;
using HTCGrid.Common;

using Htc.Mock;
using Htc.Mock.RequestRunners;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace mock_integration
{
    public class Function
    {

        private static readonly GridWorker gridWorker_;
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


            gridWorker_ = new(new DelegateRequestRunnerFactory((runConfiguration, sessionId)
                                                              =>  new DistributedRequestRunnerWithAggregation(htcDataClient,
                                                                                              htcGridClient,
                                                                                              runConfiguration,
                                                                                              sessionId,
                                                                                              fastCompute: false,
                                                                                              useLowMem: false,
                                                                                              smallOutput: false)));
        }

        public string FunctionHandler(HtcTask inputTask, ILambdaContext context)
        {
            if (inputTask.debug)
            {
                Console.WriteLine("Debug: Sleep 1 minute");
                Thread.Sleep(60000);
            }
            ////////////////////////////////////////////////////////////////////
            //// 1. First extract payload, sessionId ///////////////////////////
            ////////////////////////////////////////////////////////////////////
            Console.WriteLine("Info: " + "New SessionId is coming from Mock : " + inputTask.SessionId);

            ////////////////////////////////////////////////////////////////////
            //// 2. Do computation /////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            byte[] payload = inputTask.Payload;

            Console.WriteLine("New Payload : ");


            gridWorker_.Execute(inputTask.SessionId, inputTask.TaskId, payload);
            // trade_data = trade_data * 10;

            // System.Threading.Thread.Sleep(inputTask.sleep_time_ms);


            ////////////////////////////////////////////////////////////////////
            //// 3. Launch Sub-tasks ///////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            if (inputTask.depth > 0) {


            //     GridConfig gridConfig = new GridConfig();

            //     HTCGridConnector gridConnector =  new HTCGridConnector(gridConfig);

            //     GridSession gs = gridConnector.CreateSession();

            //     List<ClientTask> tasksToProcess = new List<ClientTask>();

            //     for (int i = 0; i < inputTask.subtasks_count; i++) {

            //         ClientTask ct = new ClientTask(
            //             inputTask.subtasks_count,
            //             inputTask.depth - 1,
            //             inputTask.trade_data_key,
            //             inputTask.sleep_time_ms);

            //         tasksToProcess.Add(ct);
            //     }

            //     gs.SendTasks(tasksToProcess.ToArray());
            }

            Console.WriteLine("Info: " + "Hello HtcGrid from Client-Mock");

            ////////////////////////////////////////////////////////////////////
            //// 4. Return Results /////////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            return "TODO";
        }

    }

    public record Casing(string Lower, string Upper);
}
