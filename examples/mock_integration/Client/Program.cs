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

           RunConfiguration runConfiguration = new RunConfiguration(new TimeSpan(0, 1, 30),
                                                 5,
                                                 1,
                                                 1,
                                                 1);
                                                 
            /*RunConfiguration runConfiguration = new RunConfiguration(new TimeSpan(0, 30, 0),
                                                 100,
                                                 1,
                                                 3,
                                                 1);
            
            RunConfiguration runConfiguration = new RunConfiguration(new TimeSpan(10, 0, 0),
                                                 1000000,
                                                 1,
                                                 3,
                                                 4);                                             

            RunConfiguration runConfiguration = new RunConfiguration(new TimeSpan(3.6, 0, 0),
                                                 400000,
                                                 1,
                                                 3,
                                                 3, maxDurationMs : 30000);
                                                 
            RunConfiguration runConfiguration = new RunConfiguration(new TimeSpan(36, 0, 0),
                                                 4000000,
                                                 1,
                                                 3,
                                                 3, maxDurationMs : 30000);*/
            client.Start(runConfiguration);
        }
    }
}