using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

using Amazon.Lambda.Core;

using HTCGrid;
// using GridClient;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace mock_computation_image
{
    public class Function
    {
        
        /// <summary>
        /// A simple function that takes a string and returns both the upper and lower case version of the string.
        /// </summary>
        /// <param name="input"></param>
        /// <param name="context"></param>
        /// <returns></returns>
        public string FunctionHandler(ClientTask input, ILambdaContext context)
        {
            Console.WriteLine("Sleep for 1 hour");
            //Console.CancelKeyPress += OnSigInt;
            Console.WriteLine("Sleep for 1 hour");
            System.Threading.Thread.Sleep(input.sleepTimeMs);
            Console.WriteLine("Hello, World! :)" + input.firstName +"  "+ input.surname);
            
            
            GridConfig gridConfig = new GridConfig();
            
            
            HTCGridConnector gridConnector =  new HTCGridConnector(gridConfig);
            
 
            GridSession gs = gridConnector.CreateSession();
            
            ClientTask ct = new ClientTask();
            
            gs.SendTasks(new ClientTask[3]{ct, ct, ct});
            
        
            Console.WriteLine("Hello World from Client");
            
            
            // if (input.type == aggregate-task) {
            //     //aggregate
                
            // } else if (input.type == compute) {
            //     sdsdff
            // }
            
            // GridConfig gridConfig = new GridConfig();
            
            // HTCGridConnector gridConnector =  new HTCGridConnector(gridConfig);
 
            // GridSession gs = gridConnector.CreateSession();
            
            // ClientTask ct1 = new ClientTask();
            // ClientTask ct2 = new ClientTask();
            // ClientTask ct3 = new ClientTask();
            
            // ClientTask aggregate-task = new ClientTask(type=aggregate, parent=[ct1.task_id, ct2.task_id, ct3.task_id]);
            
            // gs.SendTasks(new ClientTask[4]{ct, ct, ct, aggregate-task});
            
            
            
            
            // OutputObject o = new OutputObject(sddsfldskfdfskl)
            // return o;
            return $"Welcome: {input.firstName} {input.surname}";
        }
        
        // SIGINT signal handler
        //static void OnSigInt(object sender, ConsoleCancelEventArgs e)
        //{
        //    Console.WriteLine("Hello, SigInt Catch");
        //    Console.WriteLine("Hello, SigInt Catch");
        //    Console.WriteLine("Hello, SigInt Catch");
        //    Console.WriteLine("Hello, SigInt Catch");
        //    Console.WriteLine("Hello, SigInt Catch");
        //    Console.WriteLine("Hello, SigInt Catch");
        //}
    }

    public record Casing(string Lower, string Upper);
}
