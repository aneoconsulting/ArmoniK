using System;
using System.Collections.Generic;  

using HTCGrid;

namespace HTCGrid {
    
    
    public class GridContext {
        
        public GridContext() {
        }
        
        public int tasks_priority = 0;
        
    }
    
    public class StatsRecord {
        public StatsRecord(string label, int timestamp) {
            this.label = label;
            this.tstmp = timestamp;
        }
        public string label;
        public int tstmp;
    }
    
    public class GridStats {
        public GridStats() {
        
            stage1_grid_api_01_task_creation_tstmp = new StatsRecord(" ", 1);
            stage1_grid_api_02_task_submission_tstmp = new StatsRecord("upload_data_to_storage", 1);
            
            stage2_sbmtlmba_01_invocation_tstmp = new StatsRecord("grid_api_2_lambda_ms", 1);
            stage2_sbmtlmba_02_before_batch_write_tstmp = new StatsRecord("task_construction_ms", 1);
            
            stage3_agent_01_task_acquired_sqs_tstmp = new StatsRecord("sqs_queuing_time_ms", 1);
            stage3_agent_02_task_acquired_ddb_tstmp = new StatsRecord("ddb_task_claiming_time_ms", 1);
            
            stage4_agent_01_user_code_finished_tstmp = new StatsRecord("user_code_exec_time_ms", 1);
            stage4_agent_02_S3_stdout_delivered_tstmp = new StatsRecord("S3_stdout_upload_time_ms", 1);
            
        }
        
        public StatsRecord  stage1_grid_api_01_task_creation_tstmp;
        public StatsRecord  stage1_grid_api_02_task_submission_tstmp;
        
        public StatsRecord  stage2_sbmtlmba_01_invocation_tstmp;
        public StatsRecord  stage2_sbmtlmba_02_before_batch_write_tstmp;
        
        public StatsRecord  stage3_agent_01_task_acquired_sqs_tstmp;
        public StatsRecord  stage3_agent_02_task_acquired_ddb_tstmp;
        
        public StatsRecord  stage4_agent_01_user_code_finished_tstmp;
        public StatsRecord  stage4_agent_02_S3_stdout_delivered_tstmp;
        
    }
    
    public class TaskList {
        
        public TaskList(List<string> gridTaskIDs) {
            // tasks = new Task[gridTaskIDs.Count];
            
            // for (int i = 0; i < gridTaskIDs.Count; i++) {
            //     tasks[i] = new Task(gridTaskIDs[i]);
            // }
            tasks = gridTaskIDs.ToArray();
            
        }
        
        public string[] tasks;
    }
    
    public class  GridSubmissionContainer {         
        
        public GridSubmissionContainer(string session_id, List<string> gridTaskIDs, GridContext context) {
            
            this.session_id = session_id;
            tasks_list = new TaskList(gridTaskIDs);
            
            stats = new GridStats();
            
            
            
            this.context = context;
        }
        
        public string session_id;
        
        public TaskList tasks_list;
        
        public GridStats stats;
        
        public GridContext context;
        
    }
    
    
    
}
