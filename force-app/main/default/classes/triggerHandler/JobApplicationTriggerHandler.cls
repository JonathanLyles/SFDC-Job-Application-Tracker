/**
 * @description Trigger handler for Job_Application__c that manages task creation
 *              based on application status changes. Follows Kevin O'Hara pattern
 *              for bulk-safe, context-aware trigger execution.
 * @author Jonathan Lyles
 * @date 2026-01-03
 */
public class JobApplicationTriggerHandler extends TriggerHandler {
    
    /**
     * @description Handle after insert operations to create follow-up tasks
     */
    protected override void afterInsert() {
        JobApplicationTaskHelper.createFollowUpTasks(Trigger.new);
    }
    
    /**
     * @description Handle after update operations to manage status-based tasks
     */
    protected override void afterUpdate() {
        // Cast to get proper types
        List<Job_Application__c> newRecords = (List<Job_Application__c>) Trigger.new;
        List<Job_Application__c> oldRecords = (List<Job_Application__c>) Trigger.old;
        Map<Id, Job_Application__c> oldMap = (Map<Id, Job_Application__c>) Trigger.oldMap;
        
        // Handle status changes
        JobApplicationTaskHelper.handleStatusChanges(newRecords, oldMap);
        
        // Handle interview scheduling
        JobApplicationTaskHelper.handleInterviewScheduling(newRecords, oldMap);
    }
}