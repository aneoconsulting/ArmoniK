using System;
using System.Runtime.Serialization;
using StackExchange.Redis;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Collections;
using System.IO;
using System.Text.Json;

using HTCGrid;
using HTCGrid.Common;
using Htc.Mock;
using Htc.Mock.Core;

namespace HtcClient
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello Mock!");

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

            // Code below is standard.
            var dataClient = new HtcDataClient(gridConfig);

            var htcGridclient = new HtcGridClient(gridConfig, dataClient);

            dataClient.ConnectDB();

            var client = new Client(htcGridclient, dataClient);

            // Timespan(heures, minutes, secondes)
            // RunConfiguration runConfiguration = RunConfiguration.XSmall; // result : Aggregate_1871498793_result
            RunConfiguration runConfiguration = new RunConfiguration(new TimeSpan(0, 0, 0, 0, 100), 10, 1, 1, 1);

            client.Start(runConfiguration);
            client.Start(runConfiguration);
            client.Start(runConfiguration);
            client.Start(runConfiguration);
        }
    }
}