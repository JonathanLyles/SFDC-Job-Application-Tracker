
IJobBoardSearchStrategy jooble = new JoobleStrategy();
List<String> selectedJobBoards = new List<String>{ 'Jooble' };
JobSearchCriteria criteria = new JobSearchCriteria('Salesforce Developer', 'United States', selectedJobBoards);
List<JobApplicationDomain> results = jooble.searchJobs(criteria);
System.debug(results);

List<String> selectedJobBoards = new List<String>{ 'Jooble' };
List<String> workTypes = new List<String>{ 'Hybrid' };
String results = JobSearchController.searchJobs('Salesforce Developer', 'United States', selectedJobBoards, workTypes);
System.debug('results: ' + results);

Map<String, Object> status = JobSearchController.getSearchStatus('JSR-20260103182639-520');
System.debug('Status results: ' + status); 