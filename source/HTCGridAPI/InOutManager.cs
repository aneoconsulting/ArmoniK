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
                return new InOutRedis(gridConfig);
            } else {
                // Unimplemented
                return null;
            }
        }
    }
}