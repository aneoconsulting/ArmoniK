using System;
using System.Runtime.Serialization;
using StackExchange.Redis;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Collections;
using System.IO;
using System.Text.Json;
using System.Threading;

using HTCGrid;
using Armonik.sdk;

namespace HtcClient
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello Armonik Sample !");
             var armonik_wait_client = Environment.GetEnvironmentVariable("ARMONIK_DEBUG_WAIT_CLIENT");
             if(!String.IsNullOrEmpty(armonik_wait_client))
             {
                int arminik_debug_wait_client = int.Parse(armonik_wait_client);

             if (arminik_debug_wait_client > 0)
            {
                Console.WriteLine($"Debug: Sleep {arminik_debug_wait_client} seconds");
                Thread.Sleep(arminik_debug_wait_client * 1000);
            }
            }
            string agentConfigFileName = Environment.GetEnvironmentVariable("AGENT_CONFIG_FILE");
            if (agentConfigFileName == null)
            {
                agentConfigFileName = "/etc/agent/Agent_config.tfvars.json";
            }
            JsonDocument parsedConfig = null;
            try
            {
                FileStream fsSource = new FileStream(agentConfigFileName, FileMode.Open, FileAccess.Read);
                parsedConfig = JsonDocument.Parse(fsSource);
            }
            catch (FileNotFoundException ioEx)
            {
                Console.WriteLine(ioEx.Message);
                Environment.Exit(-1);
            }

            ////////////////////////////////////////////////////////////////////
            //// 1. HTC-Grid Connection ////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            GridConfig gridConfig = new GridConfig();
            gridConfig.Init(parsedConfig);
            //get envirnoment variable
            var var_env = Environment.GetEnvironmentVariable("ARMONIK_DEBUG_WAIT_TASK");
             if(!String.IsNullOrEmpty(var_env))
             {
                gridConfig.debug = int.Parse(var_env);
             }



            // Code below is standard.
            var dataClient = new HtcDataClient(gridConfig);

            var htcGridclient = new HtcGridClient(gridConfig, dataClient);

            dataClient.ConnectDB();

            // var client = new Client(htcGridclient, dataClient);

            // // Timespan(heures, minutes, secondes)
            // // RunConfiguration runConfiguration = RunConfiguration.XSmall; // result : Aggregate_1871498793_result
            // RunConfiguration runConfiguration = new RunConfiguration(new TimeSpan(0, 0, 0, 0, 100), 10, 1, 1, 1);

            // client.Start(runConfiguration);
            // Console.WriteLine("");
            // Console.WriteLine("");
            // Console.WriteLine("");
            // client.Start(runConfiguration);
            // Console.WriteLine("");
            // Console.WriteLine("");
            // Console.WriteLine("");
            // client.Start(runConfiguration);
            // Console.WriteLine("");
            // Console.WriteLine("");
            // Console.WriteLine("");
            // client.Start(runConfiguration);
        }
    }
}