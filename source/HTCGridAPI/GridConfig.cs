using System;
using System.IO;
using Newtonsoft.Json.Linq;
using System.Text.Json;

namespace HTCGrid
{
    public class  GridConfig {

        public GridConfig() {
            this.debug = 0; 
        }

        public string GetValue(JsonElement config, string key, bool lower=false)
        {
            string value = "";

            try
            {
                value = lower ? config.GetProperty(key).GetString().ToLower() : config.GetProperty(key).GetString();
                return value;
            }
            catch (Exception ex)
            {
                return value;
            }
        }

        public void Init(JsonDocument parsedConfiguration) {
            JsonElement root = parsedConfiguration.RootElement;
            this.grid_storage_service = GetValue(root, "grid_storage_service");
			this.private_api_gateway_url = GetValue(root, "private_api_gateway_url"); 
			this.api_gateway_key = GetValue(root, "api_gateway_key");
			this.redis_with_ssl = GetValue(root, "redis_with_ssl", true);
			this.redis_endpoint_url = GetValue(root, "redis_endpoint_url");
			this.redis_port = GetValue(root, "redis_port");
			this.cluster_config = GetValue(root, "cluster_config");
			this.redis_ca_cert = GetValue(root, "redis_ca_cert");
            this.redis_client_pfx = GetValue(root, "redis_client_pfx");
            this.connection_redis_timeout = GetValue(root, "connection_redis_timeout");
        }

        public string grid_storage_service;
		public string private_api_gateway_url;
        public string api_gateway_key;
		public string redis_with_ssl;
        public string redis_endpoint_url;   
        public string redis_port;
		public string cluster_config;
        public string redis_ca_cert;
        public string redis_client_pfx;
		public string connection_redis_timeout;      
        public int debug;
    }
}
