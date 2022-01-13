using System;
using System.Runtime.Serialization;
using StackExchange.Redis;
using System.Collections.Generic;
using System.Collections;
using System.IO;
using System.Text.Json;
using System.Text;
using System.Threading;
using System.Linq;
using System.Diagnostics;

using HTCGrid;
using Armonik.sdk;

namespace HtcClient
{
    class SimpleStats
    {
        public int _run { get; set; }
        public string _test { get; set; }
        public long _ellapsedTime { get; set; }
        public int _nbTasks { get; set; }
        public int _sleep { get; set; }
        public string ToJson()
        {
            return JsonSerializer.Serialize(this);
        }
    }
    class Program
    {
        static void Main(string[] args)
        {
            Logger.Info("Hello Armonik Sample !");
            var armonik_wait_client = Environment.GetEnvironmentVariable("ARMONIK_DEBUG_WAIT_CLIENT");
            if (!String.IsNullOrEmpty(armonik_wait_client))
            {
                int arminik_debug_wait_client = int.Parse(armonik_wait_client);

                if (arminik_debug_wait_client > 0)
                {
                    Logger.Info($"Debug: Sleep {arminik_debug_wait_client} seconds");
                    Thread.Sleep(arminik_debug_wait_client * 1000);
                }
            }
            string agentConfigFileName = Environment.GetEnvironmentVariable("CLIENT_CONFIG_FILE");
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
                Logger.Error(ioEx.Message);
                Environment.Exit(-1);
            }

            GridConfig gridConfig = new GridConfig();
            gridConfig.Init(parsedConfig);
            //get envirnoment variable
            var var_env = Environment.GetEnvironmentVariable("ARMONIK_DEBUG_WAIT_TASK");
            if (!String.IsNullOrEmpty(var_env))
            {
                gridConfig.debug = int.Parse(var_env);
            }

            var client = new ArmonikClient(gridConfig);
            ClientStartup1(client, 3);
            // ClientStartup2(client);
            // TestNTasksClient(client, 50, 120, 7);
            // TestNTasksServer(client, 50, 120, 7);
        }

        public static void TestNTasksClient(ArmonikClient client, int nbTasks, int sleep, int nRuns)
        {
            for (int run = 0; run < nRuns; run++)
            {
                var clientPayload = new ClientPayload() { taskType = 3, sleep = sleep };
                byte[] payload = clientPayload.serialize();

                List<byte[]> payloads = new List<byte[]>(nbTasks);
                for (int i = 0; i < nbTasks; i++)
                {
                    payloads.Add(payload);
                }
                Stopwatch sw = Stopwatch.StartNew();
                var taskIds = client.SubmitTasks(payloads);
                foreach (var taskId in taskIds)
                {
                    client.WaitCompletion(taskId);
                }
                long elapsedMilliseconds = sw.ElapsedMilliseconds;
                Logger.Info($"Client called {nbTasks} tasks in {elapsedMilliseconds} ms");
                var stat = new SimpleStats() { _ellapsedTime = elapsedMilliseconds, _run = run, _test = "TestNTasksClient", _nbTasks = nbTasks, _sleep = sleep };
                Logger.Info("JSON Result : " + stat.ToJson());
                Thread.Sleep(10000);
            }
        }

        public static void TestNTasksServer(ArmonikClient client, int nbTasks, int sleep, int nRuns)
        {
            for (int run = 0; run < nRuns; run++)
            {
                List<int> numbers = new List<int>() { nbTasks };
                var clientPayload = new ClientPayload() { numbers = numbers, taskType = 4, sleep = sleep };
                Stopwatch sw = Stopwatch.StartNew();
                string taskId = client.SubmitTask(clientPayload.serialize());
                client.WaitCompletion(taskId);
                long elapsedMilliseconds = sw.ElapsedMilliseconds;

                Logger.Info($"Client called 1 tasks that spanws {nbTasks - 1} task on the server side in {elapsedMilliseconds} ms");
                var stat = new SimpleStats() { _ellapsedTime = elapsedMilliseconds, _run = run, _test = "TestNTasksServer", _nbTasks = nbTasks, _sleep = sleep };
                Logger.Info("JSON Result : " + stat.ToJson());
                Thread.Sleep(10000);
            }
        }

        public static void ClientStartup1(ArmonikClient client, int nbTasks)
        {
            List<int> numbers = new List<int>();
            for (int i = 0; i < nbTasks; i++)
            {
                numbers.Add(i + 1);
            }
            var clientPaylaod = new ClientPayload() { numbers = numbers, taskType = 1 };
            string taskId = client.SubmitTask(clientPaylaod.serialize());

            client.WaitCompletion(taskId);
            byte[] output = client.GetData(taskId);
            int result = BitConverter.ToInt32(output, 0);

            Logger.Info($"output result : {result}");
        }

        public static void ClientStartup2(ArmonikClient client)
        {
            List<int> numbers = new List<int>() { 2 };
            var clientPayload = new ClientPayload() { numbers = numbers, taskType = 2 };
            byte[] payload = clientPayload.serialize();
            StringBuilder outputMessages = new StringBuilder();
            outputMessages.AppendLine("In this serie of samples we're creating N jobs of one task.");
            outputMessages.AppendLine(@"In the loop we have :
    1 sending job of one task
    2 wait for result
    3 get associated payload");
            N_Jobs_of_1_Task(client, payload, 1, outputMessages);
            N_Jobs_of_1_Task(client, payload, 10, outputMessages);
            N_Jobs_of_1_Task(client, payload, 100, outputMessages);
            N_Jobs_of_1_Task(client, payload, 200, outputMessages);
            N_Jobs_of_1_Task(client, payload, 500, outputMessages);

            outputMessages.AppendLine("In this serie of samples we're creating 1 job of N tasks.");

            _1_Job_of_N_Tasks(client, payload, 1, outputMessages);
            _1_Job_of_N_Tasks(client, payload, 10, outputMessages);
            _1_Job_of_N_Tasks(client, payload, 100, outputMessages);
            _1_Job_of_N_Tasks(client, payload, 200, outputMessages);
            _1_Job_of_N_Tasks(client, payload, 500, outputMessages);

            Logger.Info(outputMessages.ToString());
        }

        private static void N_Jobs_of_1_Task(ArmonikClient client, byte[] payload, int nbTasks, StringBuilder outputMessages)
        {
            Stopwatch sw = Stopwatch.StartNew();
            int finalResult = 0;
            for (int i = 0; i < nbTasks; i++)
            {
                string taskId = client.SubmitTask(payload);
                client.WaitCompletion(taskId);
                byte[] taskResult = client.GetData(taskId);
                finalResult += BitConverter.ToInt32(taskResult);
            }
            long elapsedMilliseconds = sw.ElapsedMilliseconds;
            outputMessages.AppendLine($"Client called {nbTasks} jobs of one task in {elapsedMilliseconds} ms agregated result = {finalResult}");
        }

        private static void _1_Job_of_N_Tasks(ArmonikClient client, byte[] payload, int nbTasks, StringBuilder outputMessages)
        {
            List<byte[]> payloads = new List<byte[]>(nbTasks);
            for (int i = 0; i < nbTasks; i++)
            {
                payloads.Add(payload);
            }
            Stopwatch sw = Stopwatch.StartNew();
            int finalResult = 0;
            var taskIds = client.SubmitTasks(payloads);
            foreach (var taskId in taskIds)
            {
                client.WaitCompletion(taskId);
                byte[] taskResult = client.GetData(taskId);
                finalResult += BitConverter.ToInt32(taskResult);
            }
            long elapsedMilliseconds = sw.ElapsedMilliseconds;
            outputMessages.AppendLine($"Client called {nbTasks} tasks in {elapsedMilliseconds} ms agregated result = {finalResult}");
        }
    }
}
