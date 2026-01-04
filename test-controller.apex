// Simple test of our deployed classes
System.debug('Testing JobSearchController.getJobBoardInfo...');
try {
  Map<String, Object> info = JobSearchController.getJobBoardInfo();
  System.debug('JobBoard info retrieved: ' + info.size() + ' items');
  System.debug('Available boards: ' + info.get('availableBoards'));
} catch (Exception e) {
  System.debug('Error testing controller: ' + e.getMessage());
  System.debug('Stack trace: ' + e.getStackTraceString());
}
