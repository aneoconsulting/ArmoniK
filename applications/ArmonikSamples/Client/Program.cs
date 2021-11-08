using System;
using System.Runtime.Serialization;
using StackExchange.Redis;
using Newtonsoft.Json;
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
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello Armonik Sample !");
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

            GridConfig gridConfig = new GridConfig();
            gridConfig.Init(parsedConfig);
            //get envirnoment variable
            var var_env = Environment.GetEnvironmentVariable("ARMONIK_DEBUG_WAIT_TASK");
            if (!String.IsNullOrEmpty(var_env))
            {
                gridConfig.debug = int.Parse(var_env);
            }

            var dataClient = new HtcDataClient(gridConfig);

            var htcGridClient = new HtcGridClient(gridConfig, dataClient);

            dataClient.ConnectDB();

            ClientStartup1(dataClient, htcGridClient, 3);
            // ClientStartup2(dataClient, htcGridClient);
            // TestNTasksClient(dataClient, htcGridClient, 50);
            // TestNTasksServer(dataClient, htcGridClient, 50);
        }

        public static void TestNTasksClient(HtcDataClient dataClient, HtcGridClient htcGridClient, int nbTasks)
        {
            var clientPayload = new ClientPayload() { taskType = 3 };
            byte[] payload = clientPayload.serialize();

            List<byte[]> payloads = new List<byte[]>(nbTasks);
            for (int i = 0; i < nbTasks; i++)
            {
                payloads.Add(payload);
            }
            Stopwatch sw = Stopwatch.StartNew();
            int finalResult = 0;
            var taskIds = htcGridClient.SubmitTasks(payloads);
            foreach (var taskId in taskIds)
            {
                htcGridClient.WaitCompletion(taskId);
            }
            long elapsedMilliseconds = sw.ElapsedMilliseconds;
            Logger.Log($"Client called {nbTasks} tasks in {elapsedMilliseconds} ms");
        }

        public static void TestNTasksServer(HtcDataClient dataClient, HtcGridClient htcGridClient, int nbTasks)
        {
            List<int> numbers = new List<int>() { nbTasks };
            var clientPayload = new ClientPayload() { numbers = numbers, taskType = 4 };
            Stopwatch sw = Stopwatch.StartNew();
            string taskId = htcGridClient.SubmitTask(clientPayload.serialize());
            htcGridClient.WaitCompletion(taskId);
            long elapsedMilliseconds = sw.ElapsedMilliseconds;

            Logger.Log($"Client called 1 tasks that spanws {nbTasks - 1} task on the server side in {elapsedMilliseconds} ms");
        }

        public static void ClientStartup1(HtcDataClient dataClient, HtcGridClient htcGridClient, int nbTasks)
        {
            List<int> numbers = new List<int>();
            for (int i = 0; i < nbTasks; i++)
            {
                numbers.Add(i);
            }
            var clientPaylaod = new ClientPayload() { numbers = numbers, taskType = 1 };
            string taskId = htcGridClient.SubmitTask(clientPaylaod.serialize());

            htcGridClient.WaitCompletion(taskId);
            byte[] output = dataClient.GetData(taskId);
            int result = BitConverter.ToInt32(output, 0);

            Logger.Log($"output result : {result}");
        }

        public static void ClientStartup2(HtcDataClient dataClient, HtcGridClient htcGridClient)
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
            N_Jobs_of_1_Task(dataClient, htcGridClient, payload, 1, outputMessages);
            N_Jobs_of_1_Task(dataClient, htcGridClient, payload, 10, outputMessages);
            N_Jobs_of_1_Task(dataClient, htcGridClient, payload, 100, outputMessages);
            N_Jobs_of_1_Task(dataClient, htcGridClient, payload, 200, outputMessages);
            N_Jobs_of_1_Task(dataClient, htcGridClient, payload, 500, outputMessages);

            outputMessages.AppendLine("In this serie of samples we're creating 1 job of N tasks.");

            _1_Job_of_N_Tasks(dataClient, htcGridClient, payload, 1, outputMessages);
            _1_Job_of_N_Tasks(dataClient, htcGridClient, payload, 10, outputMessages);
            _1_Job_of_N_Tasks(dataClient, htcGridClient, payload, 100, outputMessages);
            _1_Job_of_N_Tasks(dataClient, htcGridClient, payload, 200, outputMessages);
            _1_Job_of_N_Tasks(dataClient, htcGridClient, payload, 500, outputMessages);

            Logger.Log(outputMessages.ToString());
        }

        private static void N_Jobs_of_1_Task(HtcDataClient dataClient, HtcGridClient htcGridClient, byte[] payload, int nbTasks, StringBuilder outputMessages)
        {
            Stopwatch sw = Stopwatch.StartNew();
            int finalResult = 0;
            for (int i = 0; i < nbTasks; i++)
            {
                string taskId = htcGridClient.SubmitTask(payload);
                htcGridClient.WaitCompletion(taskId);
                byte[] taskResult = dataClient.GetData(taskId);
                finalResult += BitConverter.ToInt32(taskResult);
            }
            long elapsedMilliseconds = sw.ElapsedMilliseconds;
            outputMessages.AppendLine($"Client called {nbTasks} jobs of one task in {elapsedMilliseconds} ms agregated result = {finalResult}");
        }

        private static void _1_Job_of_N_Tasks(HtcDataClient dataClient, HtcGridClient htcGridClient, byte[] payload, int nbTasks, StringBuilder outputMessages)
        {
            List<byte[]> payloads = new List<byte[]>(nbTasks);
            for (int i = 0; i < nbTasks; i++)
            {
                payloads.Add(payload);
            }
            Stopwatch sw = Stopwatch.StartNew();
            int finalResult = 0;
            var taskIds = htcGridClient.SubmitTasks(payloads);
            foreach (var taskId in taskIds)
            {
                htcGridClient.WaitCompletion(taskId);
                byte[] taskResult = dataClient.GetData(taskId);
                finalResult += BitConverter.ToInt32(taskResult);
            }
            long elapsedMilliseconds = sw.ElapsedMilliseconds;
            outputMessages.AppendLine($"Client called {nbTasks} tasks in {elapsedMilliseconds} ms agregated result = {finalResult}");
        }
    }
}