// Test creating a Job Application record
System.debug('Testing Job Application record creation...');

// Create the record via DML
Job_Application__c testJob = new Job_Application__c();
testJob.put('Company_Name__c', 'Test Company');
testJob.put('Position_Title__c', 'Software Engineer');
testJob.put('Status__c', 'Applied');

try {
  insert testJob;
  System.debug('Successfully created Job Application: ' + testJob.Id);

  // Query it back
  Job_Application__c queried = [
    SELECT Id, Name, Company_Name__c, Position_Title__c, Status__c
    FROM Job_Application__c
    WHERE Id = :testJob.Id
  ];
  System.debug('Queried record: ' + queried);
} catch (Exception e) {
  System.debug('Error creating record: ' + e.getMessage());
  System.debug('Stack trace: ' + e.getStackTraceString());
}
