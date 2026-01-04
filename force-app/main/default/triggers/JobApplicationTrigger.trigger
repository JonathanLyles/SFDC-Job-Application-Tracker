/**
 * @description Trigger for Job_Application__c object that delegates all logic
 *              to JobApplicationTriggerHandler following Kevin O'Hara pattern.
 *              This ensures bulk-safe, context-aware processing of DML operations.
 * @author Jonathan Lyles
 * @date 2026-01-03
 */
trigger JobApplicationTrigger on Job_Application__c (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    new JobApplicationTriggerHandler().run();
}