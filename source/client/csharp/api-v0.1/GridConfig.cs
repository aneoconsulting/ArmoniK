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
			Console.WriteLine($"grid_storage_service: {grid_storage_service}");

            this.private_api_gateway_url = root.GetProperty("private_api_gateway_url").GetString();
			Console.WriteLine($"private_api_gateway_url: {private_api_gateway_url}");

            this.api_gateway_key = root.GetProperty("api_gateway_key").GetString();
			Console.WriteLine($"api_gateway_key: {api_gateway_key}");

            this.redis_with_ssl = root.GetProperty("redis_with_ssl").GetString().ToLower();
			Console.WriteLine($"redis_with_ssl: {redis_with_ssl}");

			this.redis_endpoint_url = String.Equals(this.redis_with_ssl, "false") ? root.GetProperty("redis_endpoint_url_without_ssl").GetString() : root.GetProperty("redis_endpoint_url").GetString();
			Console.WriteLine($"redis_endpoint_url: {redis_endpoint_url}");

            this.cluster_config = root.GetProperty("cluster_config").GetString();
			Console.WriteLine($"cluster_config: {cluster_config}");

            if ((String.Equals(this.cluster_config.ToLower(), "local") && String.Equals(this.redis_with_ssl, "true"))
                || String.Equals(this.cluster_config.ToLower(), "cluster")) {
                this.redis_ca_cert = root.GetProperty("redis_ca_cert").GetString();
                this.redis_client_pfx = root.GetProperty("redis_client_pfx").GetString();
            } else {
                this.redis_ca_cert = "";
                this.redis_client_pfx = "";
            }
			Console.WriteLine($"redis_ca_cert: {redis_ca_cert}");
            Console.WriteLine($"redis_client_pfx: {redis_client_pfx}");

			this.connection_redis_timeout = root.GetProperty("connection_redis_timeout").GetString();
			Console.WriteLine($"connection_redis_timeout: {connection_redis_timeout}");
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
