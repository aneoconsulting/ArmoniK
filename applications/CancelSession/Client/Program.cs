using System;
using System.Runtime.Serialization;
using Newtonsoft.Json;
using System.Collections.Generic;
using System.Collections;
using System.IO;
using System.Text.Json;
using System.Threading;

using HTCGrid;
using HTCGrid.Common;


namespace HtcClient
{
    class Program
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Hello Cancel Task!");

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

            HTCGridConnector gridConnector =  new HTCGridConnector(gridConfig);

            GridSession gridSession = gridConnector.CreateSession();

            ////////////////////////////////////////////////////////////////////
            //// 2. HTC-Grid Connection ////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            GridContext context = new GridContext();
            context.tasks_priority = 0;

            gridSession.SetContext(context);

            ////////////////////////////////////////////////////////////////////
            //// 3. Tasks preparation  /////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            HtcTask clientTask_1 = new HtcTask(){subtasks_count = 1, depth = 0, sleep_time_ms = 10000, sessionId_ = gridSession.SessionId};
            HtcTask clientTask_2 = new HtcTask(){subtasks_count = 1, depth = 0, sleep_time_ms = 10000, sessionId_ = gridSession.SessionId};
            HtcTask clientTask_3 = new HtcTask(){subtasks_count = 1, depth = 0, sleep_time_ms = 10000, sessionId_ = gridSession.SessionId};

            List<HtcTask> tasksToProcess = new List<HtcTask>();
            tasksToProcess.Add(clientTask_1);
            tasksToProcess.Add(clientTask_2);
            tasksToProcess.Add(clientTask_3);

            ////////////////////////////////////////////////////////////////////
            //// 4. Tasks submission  //////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            gridSession.SendTasks(tasksToProcess.ToArray());

            ////////////////////////////////////////////////////////////////////
            //// 5. Tasks cancellation  ////////////////////////////////////////
            ////////////////////////////////////////////////////////////////////

            var response = gridSession.CancelSession();
            Console.WriteLine($"cancel response = {response}");

        }
    }
}