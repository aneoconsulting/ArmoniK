using System;
using System.Runtime.Serialization;
using StackExchange.Redis;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Collections;
using System.IO;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using System.Diagnostics;
using System.Linq;
using HTCGrid;
using Armonik.Mock;
using Armonik.sdk;
using Htc.Mock;
using Htc.Mock.Core;

namespace HtcClient
{
    public static class HtcMockClientExt
    {
        public static void ParallelExec(this Client client, RunConfiguration runConfiguration, string conf, int nRun)
        {
            Stopwatch sw = Stopwatch.StartNew();
            var tasks = Enumerable.Repeat(runConfiguration, nRun)
                .Select(configuration => Task.Run(() => client.Start(configuration)))
                .ToList();
            Task.WhenAll(tasks).Wait();
            long elapsedMilliseconds = sw.ElapsedMilliseconds;
            var stat = new SimpleStats() { _ellapsedTime = elapsedMilliseconds, _conf = conf, _test = "AsyncExec", _nRun = nRun };
            Logger.Info("JSON Result : " + stat.ToJson());
        }
        public static void SeqExec(this Client client, RunConfiguration runConfiguration, string conf, int nRun)
        {
            Stopwatch sw = Stopwatch.StartNew();
            for (int i = 0; i < nRun; i++)
            {
                client.Start(runConfiguration);
            }
            long elapsedMilliseconds = sw.ElapsedMilliseconds;
            var stat = new SimpleStats() { _ellapsedTime = elapsedMilliseconds, _conf = conf, _test = "SeqExec", _nRun = nRun };
            Logger.Info("JSON Result : " + stat.ToJson());
        }
    }

    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello Mock!");
            var armonik_wait_client = Environment.GetEnvironmentVariable("ARMONIK_DEBUG_WAIT_CLIENT");
            if (!String.IsNullOrEmpty(armonik_wait_client))
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
            if (!String.IsNullOrEmpty(var_env))
            {
                gridConfig.debug = int.Parse(var_env);
            }



            // Code below is standard.
            var amonikClient = new ArmonikClient(gridConfig);
            var armonikGridClient = new ArmonikGridClient(amonikClient);
            var armonikDataClient = new ArmonikDataClient(amonikClient);

            var client = new Client(armonikGridClient, armonikDataClient);

            // Timespan(heures, minutes, secondes)
            // RunConfiguration runConfiguration = RunConfiguration.XSmall; // result : Aggregate_1871498793_result
            // RunConfiguration runConfiguration = new RunConfiguration(new TimeSpan(0, 0, 0, 0, 100), 10, 1, 1, 1);
            client.ParallelExec(RunConfiguration.XSmall, "XSmall", 5);
            client.SeqExec(RunConfiguration.XSmall, "XSmall", 5);
        }

    }
    class SimpleStats
    {
        public long _ellapsedTime { get; set; }
        public string _conf { get; set; }
        public string _test { get; set; }
        public int _nRun { get; set; }
        public string ToJson()
        {
            return System.Text.Json.JsonSerializer.Serialize(this);
        }
    }
}
