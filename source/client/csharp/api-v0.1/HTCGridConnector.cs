using System;
// using GridSession;

namespace HTCGrid
{
    
    public class  HTCGridConnector {         
        public HTCGridConnector(GridConfig gridConfig) {
            
            this.gridConfig = gridConfig;
    
    
            this.iom = new InOutManager(gridConfig);
            
            this.storageInterface = this.iom.GetStorageConnector();
            
            // GridSession gs = new GridSession(this.iom);
            
            // InOutRedis ior = new InOutRedis("asdas");
        }
    
    
        private InOutManager iom;
        private StorageInterface storageInterface;
        
        private GridConfig gridConfig;
        
        
        public GridSession CreateSession() {
            // potentially creates a separate connection. 
            
            return new GridSession(
                this.get_safe_session_id(),
                this.storageInterface, 
                this.gridConfig
                );
                
        }
        
        public GridSession OpenSession(string sessionId)
        {
            Console.WriteLine("HtcGridConnector : OpenSession with Id : " + sessionId);
            return new GridSession(sessionId, this.storageInterface, this.gridConfig);
        }
        
        
        private string get_safe_session_id() {
            Guid guid = Guid.NewGuid();
            
            string session_id = String.Format(
                "{0}", 
                // DateTimeOffset.Now.ToUnixTimeSeconds(), 
                guid); // TODO
                
            return session_id;
        }
        
        
        // public bool UploadData(KeyValuePairs[] ) {
        //     this.InOutManager() {
        //         StackExchange
        //         Redis.Client
        //     }
        // }
        
        
        // public <TBD> DownlaodData(string[] keys) {
        //     InOutManager() {
        //         StackExchange
        //         Redis.Client
        //     }
        // }
    
    }
    
}
