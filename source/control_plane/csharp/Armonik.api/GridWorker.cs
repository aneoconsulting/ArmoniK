/* GridWorker.cs is part of the Htc.Mock solution.

   Copyright (c) 2021-2021 ANEO.
     D. DUBUC (https://github.com/ddubuc)

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

*/


using System;


namespace Armonik
{
    namespace sdk
    {
        public class GridWorker : IGridWorker
        {
            private IServiceContainer serviceContainer;
            private SessionContext sessionContext;
            private ServiceContext serviceContext;

            public GridWorker(IServiceContainer iServiceContainer)
            {
                serviceContainer = iServiceContainer;
                sessionContext = new SessionContext();
                serviceContext = new ServiceContext();
                serviceContext.ApplicationName = "ArmonikSamples";
                serviceContext.ServiceName = "ArmonikSamples";
            }

            public void OnStart()
            {
                serviceContainer.OnCreateService(serviceContext);
            }

            public void OnSessionEnter(string session, string taskId, byte[] payload)
            {
                sessionContext.SessionId = session;
                sessionContext.clientLibVersion = "1.0.0";
                serviceContainer.OnSessionEnter(sessionContext);
            }

            public byte[] Execute(string session, string taskId, byte[] payload)
            {
                TaskContext taskContext = new TaskContext();
                taskContext.TaskId = taskId;
                taskContext.TaskInput = payload;
                taskContext.SessionId = session;

                serviceContainer.OnInvoke(sessionContext, taskContext);

                //TODO get result from redis or only request result ???
                return new byte[0];
            }

            public void OnSessionLeave()
            {
                serviceContainer.OnSessionLeave(sessionContext);
            }

            public void onExit()
            {
                serviceContainer.OnDestroyService(serviceContext);
            }
        }
    }
}