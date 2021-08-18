using System;
using System.IO;
using Newtonsoft.Json.Linq;
using System.Text.Json;

namespace HTCGrid
{
    public class  GridConfig {

        public GridConfig() {
        }

        public void Init(JsonDocument parsedConfiguration) {
            JsonElement root = parsedConfiguration.RootElement;
            this.grid_storage_service = root.GetProperty("grid_storage_service").GetString();
			this.private_api_gateway_url = root.GetProperty("private_api_gateway_url").GetString();
			this.api_gateway_key = root.GetProperty("api_gateway_key").GetString();
			this.redis_with_ssl = root.GetProperty("redis_with_ssl").GetString().ToLower();
			this.redis_endpoint_url = String.Equals(this.redis_with_ssl, "false") ? root.GetProperty("redis_endpoint_url_without_ssl").GetString() : root.GetProperty("redis_endpoint_url").GetString();
			this.cluster_config = root.GetProperty("cluster_config").GetString();

            if ((String.Equals(this.cluster_config.ToLower(), "local") && String.Equals(this.redis_with_ssl, "true"))
                || String.Equals(this.cluster_config.ToLower(), "cluster")) {
                this.redis_ca_cert = root.GetProperty("redis_ca_cert").GetString();
                this.redis_client_pfx = root.GetProperty("redis_client_pfx").GetString();
            } else {
                this.redis_ca_cert = "";
                this.redis_client_pfx = "";
            }

			this.connection_redis_timeout = root.GetProperty("connection_redis_timeout").GetString();
        }

        public string grid_storage_service;
		public string private_api_gateway_url;
        public string api_gateway_key;
		public string redis_with_ssl;
        public string redis_endpoint_url;   
		public string cluster_config;
        public string redis_ca_cert;
        public string redis_client_pfx;
		public string connection_redis_timeout;        
    }
}
