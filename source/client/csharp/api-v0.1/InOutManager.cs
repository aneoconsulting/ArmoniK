using System;
namespace HTCGrid
{
    public class InOutManager
    {
        
        public InOutManager(GridConfig gridConfig) {
            this.gridConfig = gridConfig;
        }
        
        private GridConfig gridConfig;
        
        public StorageInterface GetStorageConnector() {
            
            if (String.Equals(gridConfig.grid_storage_service, "REDIS")) {
                return new InOutRedis(
                    gridConfig.redis_url,
                    gridConfig.redis_port, 
                    gridConfig.redis_with_ssl, 
                    gridConfig.connection_redis_timeout
                );
            } else {
                // Unimplemented
                return null;
            }
        }
    }
}