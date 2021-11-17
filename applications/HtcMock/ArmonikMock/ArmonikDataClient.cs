using System.Collections.Generic;
using System.Linq;
using System;
using JetBrains.Annotations;

using Htc.Mock;
using Armonik.sdk;

namespace Armonik.Mock
{

    public class ArmonikDataClient : Htc.Mock.IDataClient
    {
        private ArmonikClient armonikClient_;
        public ArmonikDataClient(ArmonikClient armonikClient) => armonikClient_ = armonikClient;
        public byte[] GetData(string key) => armonikClient_.GetData(key);
        public void StoreData(string key, byte[] data) => armonikClient_.StoreData(key, data);
    }
}