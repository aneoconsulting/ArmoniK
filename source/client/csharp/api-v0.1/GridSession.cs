using System;
using System.Runtime.Serialization;
using System.Collections.Generic;
using Newtonsoft.Json;

using HttpApi.Api;
using HttpApi.Client;
using HttpApi.Model;
using Microsoft.IdentityModel.Tokens;



namespace HTCGrid
{
    public class GridSession {

        // Builder class from the HTCGridConnector class.
        // can be created only through HTCGridConnector not by a client explicitly.
        public GridSession(string session_id, StorageInterface storageInterface, GridConfig gridConfig)
        {
            Console.WriteLine(String.Format("Instanciating Grid Session [{0}]", session_id));

            this.session_id = session_id;

            this.storageInterface = storageInterface;

            SetUpHTTPConnection(gridConfig);

            Console.WriteLine("GridSession created");
        }

        private string session_id;

        public string SessionId { get { return session_id; } set { session_id = value; } }


        private StorageInterface storageInterface;

        private DefaultApi apiInstance;

        // Incremented for each invocation of SendTasks
        private int submissions_count = 0;

        // Counts total number of submitted tasks across all invocations of SendTask
        private int submitted_tasks_count = 0;

        private GridContext context;

        public GridContext GetContext() {
            return this.context;
        }

        public void SetContext(GridContext context) {
            this.context = context;
        }

        // cosnt private SessionCallback callback;


        // const SessionAttributes sa; // priority, etc. dictonary, (versioning strategy?)

        private void SetUpHTTPConnection(GridConfig gridConfig)
        {

            Configuration apiConfig = new Configuration();

            apiConfig.BasePath = gridConfig.private_api_gateway_url;
            apiConfig.ApiKey.Add("x-api-key", gridConfig.api_gateway_key);
            apiConfig.ApiKey.Add("api_key", gridConfig.api_gateway_key);
            Console.WriteLine($"(GridSession) apigateway baseUrl: {apiConfig.BasePath}");

            this.apiInstance = new DefaultApi(apiConfig);
        }

        public int GetSessionSize() {
            return this.submitted_tasks_count;
        }


        public string[] SendTasks(GridTask[] gridTasks)
        {

            List<string> new_task_ids = new List<string>();

            // <1.> Upload all tasks into the DataPlane
            int i = this.submitted_tasks_count;
            foreach (GridTask task in gridTasks)
            {
                //TODO : Check if task_id doesn't exist in control plane before
                string task_id = String.Format(
                    "{0}_{1}", // NOTE: must be underscroll '_'
                    this.session_id,
                    Guid.NewGuid().ToString());

                new_task_ids.Add(task_id);

                var client_task_base64 = strinToBase64(JsonConvert.SerializeObject(task));

                storageInterface.put_input_from_utf8_string(task_id, client_task_base64);

                i++;
            }
            this.submitted_tasks_count = i;

            // <2.> Upload arguments for submit_task Lambda into the DataPlane
            // TODO
            // string submission_id = String.Format("{0}.{0}", this.session_id, this.submissions_count);
            string submission_id = String.Format("{0}+submission_id{1}", session_id, Guid.NewGuid().ToString());
            Console.WriteLine("(GridSession) submission_id: "+ submission_id);
            this.submissions_count += 1;

            GridSubmissionContainer gsc = new GridSubmissionContainer(session_id, new_task_ids, context);

            var submission = strinToBase64(JsonConvert.SerializeObject(gsc));

            storageInterface.put_payload_from_utf8_string(submission_id, submission);

            // <3.> Invoke submit_tasks Lambda with the reference to the submission id
            try {
                var res = apiInstance.SubmitPost(submission_id);
                Console.WriteLine(res);
            }
            catch (ApiException e)
            {
                Console.WriteLine("Exception when calling DefaultApi.SubmitPost: " + e.Message);
                Console.WriteLine("Status Code: " + e.ErrorCode);
                Console.WriteLine(e.StackTrace);
            }
            return new_task_ids.ToArray();
        }

        private string strinToBase64(string serializedJson) {

            var serializedJsonBytes = System.Text.Encoding.UTF8.GetBytes(serializedJson);

            var serializedJsonBytesBase64 = System.Convert.ToBase64String(serializedJsonBytes);

            return serializedJsonBytesBase64;
        }

        private class GetResultsContainer {
            public GetResultsContainer(string session_id) {
                this.session_id = session_id;
            }
            public string session_id;
        }

        // For the testing purposes. but not requied
        public GetResponse CheckResults()
        {
            try
            {
                GetResultsContainer grc = new GetResultsContainer(this.session_id);

                string client_task_string = JsonConvert.SerializeObject(grc);

                var client_task_bytes = System.Text.Encoding.UTF8.GetBytes(client_task_string);

                var client_task_base64 = System.Convert.ToBase64String(client_task_bytes);

                // storageInterface.put_input_from_utf8_string(task_id, client_task_base64);

                // Console.WriteLine(this.session_id);
                // Console.WriteLine(client_task_base64);
                GetResponse res = apiInstance.ResultGet(client_task_base64);

                return res;
            }
            catch (ApiException e)
            {
                Console.WriteLine("Exception when calling DefaultApi.CheckResults: " + e.Message);
                Console.WriteLine("Status Code: " + e.ErrorCode);
                Console.WriteLine(e.StackTrace);
                return null;
            }
        }

        // public void CloseSession(doCancel=False) {
        //     // check if anything is still running --> cancel it.
        //     // or
        //     // wait for all callbacks are completed.
        // }
    }
}