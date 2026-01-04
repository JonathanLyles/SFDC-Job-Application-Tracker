// Test Job Application object
System.debug('Testing Job Application object creation...');
Job_Application__c testApp = new Job_Application__c(
  Company_Name__c = 'Test Company'
);
System.debug('Success: ' + testApp);

// Test JobSearchController
System.debug('Testing JobSearchController.getJobBoardInfo...');
try {
  Map<String, Object> info = JobSearchController.getJobBoardInfo();
  System.debug('JobBoard info retrieved: ' + info);
} catch (Exception e) {
  System.debug('Error testing controller: ' + e.getMessage());
}
