How the application works, in my own words:

Job Application Tracker is a Salesforce native application where users can search for job postings across several job boards (Currently Jooble, Google Jobs), save the jobs to Salesforce and track the job application lifecycle. 

Job Application Tracker can be launched from the App Launcher. (Currently available for System Administrator Profile).

The application has the following navigation items: Home (red), Job Applications, Accounts, Contacts, Tasks.

Job_Application__c is a custom object for storing job postings.

jobSearch is a custom Lightning Web Component. The component has a form where the user can enter Keywords, Location, and Work Types (Remote, Onsite, Hybrid). There's a business rule enforcing that one of Keywords, or Location must be entered. (TODO: Explain why this rule is enforced and how it is done)

When the user clicks the search button, handleSearch() runs. (onclick event)

If there are jobs returned from the search they are displayed on a table (conditional rendering). The results are paginated, set to 10 results per page. There are filters which the user can use to narrow the results by title, salary, company, location, work type, or source(job board). The user can select a job to save as a record in Salesforce. 

handleSearch() calls searchJobs from JobSearchController.cls asynchronously and sends the search parameters (keywords, location, workTypes), and returns the searchId.

searchJobs() calls JobSearchCriteria.create() to create the job search criteria

JobSearchCriteria represents normalized job search criteria. isValid() verifies that at least one of keywords or location is provided. This is a business rule. hasField() checks if specific fields have a value. 

JobSearchCriteria calls JobSearchService.searchJobsAsync(JobSearchCriteria criteria) to queue the async search. 

JobSearchService.searchJobsAsync() creates a searchId. Then it creates and queues the orchestrator queueable, sending the searchId and criteria. Then it returns the searchId to searchJobsAsync(), which returns it to searchJobs(), which returns it to handleSearch().


JobSearchOrchestratorQueueable determines if one board will be searched, or if multiple boards will be searched.

If a single board, it enqueues a new SingleBoardSearchQueueable and sends the searchId, criteria, and the selectedBoard

If multiple boards, it enqueues a new CompositeBoardSearchQueueable and sends the searchId, criteria, and the selectedBoards



 


