using System;
using System.IO;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

using StackExchange.Redis;

namespace HTCGrid
{

    public class RedisConfigurationFactory
    {

        public static ConfigurationOptions createConfiguration(GridConfig gridConfig) {
            var configurationOptions = new ConfigurationOptions
            {
                EndPoints = { $"{gridConfig.redis_url}:{gridConfig.redis_port}" },
                Ssl = bool.Parse(gridConfig.redis_with_ssl),
                ConnectTimeout = int.Parse(gridConfig.connection_redis_timeout)
            };

            switch (gridConfig.cluster_config.ToLower())
            {
                case "local":
                    configurationOptions.SslHost = "127.0.0.1";
                    break;
                case "cloud":
                    break;
                case "cluster":
                    configurationOptions.SslHost = System.Net.Dns.GetHostName();
                    break;
                default:
                    break;
            }

            if ((String.Equals(gridConfig.cluster_config.ToLower(), "local") && String.Equals(gridConfig.redis_with_ssl, "true"))
                || String.Equals(gridConfig.cluster_config.ToLower(), "cluster")) {

                if (!File.Exists(gridConfig.redis_ca_cert)) {
                    Console.WriteLine(gridConfig.redis_ca_cert + " was not found !");
                    throw new FileNotFoundException(gridConfig.redis_ca_cert + " was not found !");
                }

                if (!File.Exists(gridConfig.redis_client_pfx)) {
                    Console.WriteLine(gridConfig.redis_client_pfx + " was not found !");
                    throw new FileNotFoundException(gridConfig.redis_client_pfx + " was not found !");
                }

                // method to validate the certificate
                // https://github.com/StackExchange/StackExchange.Redis/issues/1113
                configurationOptions.CertificateValidation += (object sender, X509Certificate certificate, X509Chain chain, SslPolicyErrors sslPolicyErrors) => {
                    X509Certificate2 CertificateAuthority = new X509Certificate2(gridConfig.redis_ca_cert);
                    if (sslPolicyErrors == SslPolicyErrors.RemoteCertificateChainErrors)
                    {
                        var root = chain.ChainElements[chain.ChainElements.Count - 1].Certificate;
                        return CertificateAuthority.Equals(root);
                    }
					
                    if (sslPolicyErrors == SslPolicyErrors.None)
                        return true;

                    Console.WriteLine("");
                    Console.WriteLine("");
                    Console.WriteLine("Certificate error: {0}", sslPolicyErrors);
                    Console.WriteLine(certificate);
                    Console.WriteLine(chain);

                    return false;
                };

                configurationOptions.CertificateSelection += delegate {
                    var cert = new X509Certificate2(gridConfig.redis_client_pfx);
                    return cert;
                };
            }
            return configurationOptions;
        }
    }
}