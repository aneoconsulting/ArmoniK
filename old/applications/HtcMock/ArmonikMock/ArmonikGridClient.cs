using System.Collections.Generic;
using System.Linq;
using System;
using JetBrains.Annotations;

using Htc.Mock;
using Armonik.sdk;

namespace Armonik.Mock
{

    public class ArmonikGridClient : Htc.Mock.IGridClient
    {
        private ArmonikClient armonikClient_;
        public ArmonikGridClient(ArmonikClient armonikClient) => armonikClient_ = armonikClient;
        public byte[] GetResult(string id) => armonikClient_.GetData(id);
        public void WaitCompletion(string taskId) => armonikClient_.WaitCompletion(taskId);

        public void WaitSubtasksCompletion(string parentId) => armonikClient_.WaitSubtasksCompletion(parentId);
        public IEnumerable<string> SubmitTasks(string session, IEnumerable<byte[]> payloads) => armonikClient_.SubmitTasks(payloads);

        public string SubmitSubtask(string session, string parentId, byte[] payload) => armonikClient_.SubmitSubtask(parentId, payload);

        public IEnumerable<string> SubmitSubtasks(string session, string parentId, IEnumerable<byte[]> payloads)
        {
            throw new NotImplementedException("TODO : SubmitSubtasks");
        }

        public string SubmitTaskWithDependencies(string session, byte[] payload, IList<string> dependencies)
        {
            throw new NotImplementedException("TODO : SubmitTaskWithDependencies");
        }

        public IEnumerable<string> SubmitTaskWithDependencies(string session, IEnumerable<(byte[], IList<string>)> payloadWithDependencies)
        {
            throw new NotImplementedException("TODO : SubmitTaskWithDependencies");
        }

        public string SubmitSubtaskWithDependencies(string session, string parentId, byte[] payload, IList<string> dependencies)
        {
            throw new NotImplementedException("TODO : SubmitSubtaskWithDependencies");
        }
        public IEnumerable<string> SubmitSubtaskWithDependencies(string session, string parentId, IEnumerable<Tuple<byte[], IList<string>>> payloadWithDependencies)
        {
            throw new NotImplementedException("TODO : SubmitSubtaskWithDependencies");
        }

        public IEnumerable<string> SubmitTaskWithDependencies(string session, IEnumerable<Tuple<byte[], IList<string>>> payloadWithDependencies)
        {
            throw new NotImplementedException("TODO : SubmitTaskWithDependencies");
        }

        public IEnumerable<string> SubmitSubtaskWithDependencies(string session, string parentId, IEnumerable<(byte[], IList<string>)> payloadWithDependencies)
        {
            throw new NotImplementedException("TODO : SubmitSubtaskWithDependencies");
        }

        public void CancelSession(string session)
        {
            throw new NotImplementedException("TODO : CancelSession");
        }

        public IDisposable OpenSession(string session) => armonikClient_.OpenSession(session);

        public string CreateSession() => armonikClient_.CreateSession();

        public void CancelTask(string taskId)
        {
            throw new NotImplementedException("TODO : CancelTask");
        }

    }
}