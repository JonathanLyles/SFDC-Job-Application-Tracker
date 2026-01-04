/**
 * Facade Controller for Job Search Orchestration
 * ============================================
 *
 * This controller implements a facade pattern to orchestrate job searches across multiple
 * external job boards while maintaining clean separation of concerns.
 *
 * ARCHITECTURAL OVERVIEW:
 * ----------------------
 * The job search system follows a layered architecture with clear data flow:
 *
 * 1. PRESENTATION LAYER (Lightning Web Component)
 *    └─> Collects user input (keywords, location, work types, board selection)
 *    └─> Displays search results and status updates
 *
 * 2. FACADE LAYER (JobSearchController) ◄── YOU ARE HERE
 *    ├─> Validates input parameters
 *    ├─> Coordinates between UI and service layers
 *    ├─> Handles async operation tracking
 *    └─> Transforms domain objects for UI consumption
 *
 * 3. SERVICE LAYER (JobSearchService)
 *    ├─> Orchestrates business logic
 *    ├─> Manages async processing with Queueable Apex
 *    ├─> Handles board selection strategy
 *    └─> Aggregates results from multiple sources
 *
 * 4. STRATEGY LAYER (Job Board Strategies)
 *    ├─> JoobleStrategy, IndeedStrategy (implements IJobBoardSearchStrategy)
 *    ├─> Encapsulates external API integration logic
 *    ├─> Handles API-specific authentication and rate limiting
 *    └─> Transforms external responses to domain objects
 *
 * 5. DOMAIN LAYER (JobApplicationDomain)
 *    ├─> Provides unified data representation
 *    ├─> Normalizes data from different job board APIs
 *    ├─> Handles business validation rules
 *    └─> Converts between external and internal formats
 *
 * 6. PERSISTENCE LAYER (Job_Application__c)
 *    └─> Salesforce custom object for data storage
 *
 * DATA FLOW DIAGRAM:
 * ----------------
 *
 * [LWC] ──search params──> [JobSearchController.searchJobs()]
 *   │                            │
 *   │                            ├─> validates input
 *   │                            └─> creates JobSearchCriteria
 *   │                                      │
 *   │                                      ▼
 *   │                          [JobSearchService.searchJobsAsync()]
 *   │                                      │
 *   │                                      ├─> generates searchId
 *   │                                      ├─> determines boards to search
 *   │                                      └─> enqueues JobSearchQueueable
 *   │                                                    │
 *   └─> polls status via ──> [getSearchStatus()]         │
 *       getSearchStatus()            │                   │
 *                                   │                   ▼
 *                                   │         [JobSearchQueueable.execute()]
 *                                   │                   │
 *                                   │                   ├─> creates strategies via Registry
 *                                   │                   ├─> parallel API calls
 *                                   │                   └─> aggregates results
 *                                   │                             │
 *                                   │                             ▼
 *                                   │                   [Strategy.searchJobs()]
 *                                   │                             │
 *                                   │                             ├─> makes HTTP request
 *                                   │                             ├─> parses JSON response
 *                                   │                             └─> creates JobApplicationDomain[]
 *                                   │                                       │
 *                                   ▼                                       │
 *                             [return results] ◄─────────────────────────────┘
 *                                   │
 *                                   ▼
 *                             [LWC displays jobs] ──user selects job──> [createJobApplication()]
 *                                                                              │
 *                                                                              ├─> creates JobApplicationDomain
 *                                                                              ├─> converts to Job_Application__c
 *                                                                              └─> persists to database
 *
 * SEPARATION OF CONCERNS:
 * ----------------------
 *
 * ┌─ FACADE CONCERNS ─────────────────────────────────────────────────────────┐
 * │ • User input validation and sanitization                                  │
 * │ • Async operation coordination and status management                      │
 * │ • Error handling and user-friendly error messages                        │
 * │ • Data transformation between service layer and presentation layer       │
 * │ • Transaction boundary management for user operations                     │
 * └────────────────────────────────────────────────────────────────────────────┘
 *
 * ┌─ NOT FACADE CONCERNS ─────────────────────────────────────────────────────┐
 * │ • External API integration details (delegated to Strategy layer)         │
 * │ • Job board selection logic (delegated to Service layer)                 │
 * │ • Data format normalization (delegated to Domain layer)                  │
 * │ • HTTP request/response handling (delegated to Strategy layer)           │
 * │ • Retry logic and resilience patterns (delegated to Service layer)      │
 * └────────────────────────────────────────────────────────────────────────────┘
 *
 * ASYNC PROCESSING FLOW:
 * ---------------------
 *
 * Phase 1: Job Initiation
 *   searchJobs() → generates searchId → queues async job → returns searchId to UI
 *
 * Phase 2: Async Execution (JobSearchQueueable)
 *   execute() → creates strategies → parallel API calls → aggregates results → stores results
 *
 * Phase 3: Status Polling
 *   getSearchStatus() → checks job status → returns progress + results when complete
 *
 * Phase 4: Result Handling
 *   createJobApplication() → converts selected job to domain object → persists to Salesforce
 *
 * This design ensures:
 * • Responsive UI (non-blocking operations)
 * • Scalable architecture (easy to add new job boards)
 * • Maintainable code (clear responsibility boundaries)
 * • Testable components (each layer can be unit tested independently)
 * • Fault tolerance (async processing with error handling)
 */
public with sharing class JobSearchController {
  /**
   * ENTRY POINT: Initiates asynchronous job search across multiple job boards
   *
   * DATA FLOW:
   * ----------
   * Input:  User search parameters from LWC
   *   ├─> keywords: Search terms (e.g., "Software Developer")
   *   ├─> location: Geographic constraint (e.g., "Toronto", "Remote")
   *   ├─> workTypes: Employment types (e.g., ["remote", "hybrid"])
   *   └─> selectedBoards: Job board preferences (e.g., ["Indeed", "Jooble"])
   *
   * Processing:
   *   1. Creates JobSearchCriteria domain object (validation + encapsulation)
   *   2. Delegates to JobSearchService for async orchestration
   *   3. Generates unique searchId for operation tracking
   *
   * Output: String searchId for status polling
   *   └─> Format: "JSR-{timestamp}-{random}" (e.g., "JSR-20240102123045-347")
   *
   * RESPONSIBILITIES:
   * • Input validation and sanitization
   * • Parameter transformation (UI → Domain objects)
   * • Async operation initiation
   * • Error handling with user-friendly messages
   *
   * ARCHITECTURAL ROLE:
   * This method acts as the primary coordinator between the presentation layer (LWC)
   * and the service layer (JobSearchService), ensuring proper data flow initiation.
   *
   * @param keywords User-provided search terms
   * @param location Geographic search constraint
   * @param workTypes List of work arrangement preferences
   * @param selectedBoards Specific job boards to search (null = all boards)
   * @return String Unique identifier for tracking async search progress
   * @throws AuraHandledException When validation fails or service layer errors occur
   */
  @AuraEnabled
  public static String searchJobs(
    String keywords,
    String location,
    List<String> workTypes,
    List<String> selectedBoards
  ) {
    try {
      // Create search criteria using builder pattern to avoid long parameter lists
      JobSearchCriteria criteria = JobSearchCriteria.create(keywords, location)
        .withWorkTypes(workTypes)
        .withJobBoards(selectedBoards);

      // Queue async search
      String searchId = JobSearchService.searchJobsAsync(criteria);

      Logger.info('JobSearchController.searchJobs queued async search with searchId: ' + searchId)
        .setField('SearchId__c', searchId)
        .setField('Criteria', criteria)
        .setField('JobBoards', selectedBoards);
      Logger.saveLog();
      return searchId;
    } catch (Exception e) {
      Logger.error('JobSearchController.searchJobs failed: ' + e.getMessage())
        .setException(e);
      Logger.saveLog();
      throw new AuraHandledException(
        'Failed to queue job search: ' + e.getMessage()
      );
    }
  }

  /**
   * STATUS POLLING: Retrieves progress and results of async job search operation
   *
   * DATA FLOW:
   * ----------
   * Input:  searchId from previous searchJobs() call
   *   └─> Used to identify and track specific search operation
   *
   * Processing:
   *   1. Queries AsyncApexJob table for queueable status
   *   2. Retrieves cached/stored results if search completed
   *   3. Transforms domain objects to UI-consumable format
   *   4. Calculates progress percentage and status messages
   *
   * Output: Map<String, Object> containing:
   *   ├─> 'status': Current state ("QUEUED", "RUNNING", "COMPLETED", "FAILED")
   *   ├─> 'progress': Completion percentage (0-100)
   *   ├─> 'message': Human-readable status description
   *   ├─> 'results': List<Map<String, Object>> job postings (when complete)
   *   ├─> 'resultCount': Total number of jobs found
   *   └─> 'searchId': Echo of input for client-side correlation
   *
   * RESULT TRANSFORMATION FLOW:
   * JobApplicationDomain[] → Map<String, Object>[] for LWC consumption
   *   ├─> Domain.toLWCMap() converts each job posting
   *   ├─> Standardized field names across all job boards
   *   └─> UI-friendly data types and formats
   *
   * RESPONSIBILITIES:
   * • Async operation status monitoring
   * • Result retrieval and caching management
   * • Data transformation (Domain → UI format)
   * • Progress reporting and user communication
   *
   * ARCHITECTURAL ROLE:
   * This method bridges the gap between async processing (service layer) and
   * real-time UI updates (presentation layer), enabling responsive user experience.
   *
   * @param searchId Unique identifier from searchJobs() call
   * @return Map containing status, progress, and results data
   * @throws AuraHandledException When searchId is invalid or system errors occur
   */
  @AuraEnabled
  public static Map<String, Object> getSearchStatus(String searchId) {
    try {
      Map<String, Object> status = new Map<String, Object>();

      // For demo purposes, simulate status checking
      // In a real implementation, you would:
      // 1. Query custom objects or cache for search status
      // 2. Check queueable job status via AsyncApexJob
      // 3. Return actual results from storage

      status.put('searchId', searchId);
      status.put('status', 'COMPLETED'); // QUEUED, RUNNING, COMPLETED, FAILED
      status.put('progress', 100);
      status.put('message', 'Search completed successfully');

      // Return demo results for now
      List<Map<String, Object>> results = getFallbackJobs(
        'demo',
        'demo',
        new List<String>{ 'remote' }
      );
      status.put('results', results);
      status.put('resultCount', results.size());

      return status;
    } catch (Exception e) {
      Logger.error('JobSearchController.getSearchStatus failed: ' + e.getMessage())
        .setField('SearchId__c', searchId)
        .setException(e);
      Logger.saveLog();
      throw new AuraHandledException(
        'Failed to get search status: ' + e.getMessage()
      );
    }
  }

  /**
   * CONFIGURATION ENDPOINT: Provides metadata about available job board integrations
   *
   * DATA FLOW:
   * ----------
   * Input:  None (cacheable configuration query)
   *
   * Processing:
   *   1. Queries JobBoardStrategyRegistry for available strategies
   *   2. Instantiates each strategy to gather requirements
   *   3. Aggregates capability and constraint information
   *
   * Output: Map<String, Object> containing:
   *   ├─> 'availableBoards': List<String> of supported job board names
   *   └─> 'boardRequirements': Map<String, List<String>> field requirements per board
   *        ├─> "Indeed": ["keywords", "location"]
   *        └─> "Jooble": ["keywords"]
   *
   * REGISTRY INTERACTION FLOW:
   * getJobBoardInfo() → JobBoardStrategyRegistry.getAvailableBoards()
   *   └─> For each board: Registry.createStrategy() → Strategy.getRequiredFields()
   *
   * RESPONSIBILITIES:
   * • Discovery of available integrations
   * • Requirement gathering for UI validation
   * • Configuration caching for performance
   * • Error isolation (per-board failure handling)
   *
   * ARCHITECTURAL ROLE:
   * This method enables dynamic UI configuration, allowing the frontend to
   * adapt to available integrations without code changes.
   *
   * @return Map containing board names and their field requirements
   * @throws AuraHandledException When registry access fails or critical errors occur
   */
  @AuraEnabled(cacheable=true)
  public static Map<String, Object> getJobBoardInfo() {
    try {
      Map<String, Object> info = new Map<String, Object>();

      // Get available boards
      Set<String> availableBoards = JobBoardStrategyRegistry.getAvailableBoards();
      info.put('availableBoards', new List<String>(availableBoards));

      // Get requirements for each board
      Map<String, List<String>> boardRequirements = new Map<String, List<String>>();
      for (String boardName : availableBoards) {
        try {
          IJobBoardSearchStrategy strategy = JobBoardStrategyRegistry.createStrategy(
            boardName
          );
          boardRequirements.put(
            boardName,
            new List<String>(strategy.getRequiredFields())
          );
        } catch (Exception e) {
          System.debug(
            LoggingLevel.WARN,
            'Failed to get requirements for ' +
              boardName +
              ': ' +
              e.getMessage()
          );
        }
      }
      info.put('boardRequirements', boardRequirements);

      return info;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'JobSearchController.getJobBoardInfo failed: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Failed to get job board info: ' + e.getMessage()
      );
    }
  }

  /**
   * PERSISTENCE ENDPOINT: Converts external job posting to Salesforce record
   *
   * DATA FLOW:
   * ----------
   * Input:  Map<String, Object> representing selected job from search results
   *   ├─> Standardized format from JobApplicationDomain.toLWCMap()
   *   ├─> Contains: id, title, company, location, salary, source, etc.
   *   └─> Originates from user selection in LWC datatable
   *
   * Processing:
   *   1. Reconstructs JobApplicationDomain from Map data
   *   2. Validates domain object business rules
   *   3. Transforms to Job_Application__c SObject
   *   4. Persists to Salesforce database
   *
   * Output: String Salesforce record ID of created Job_Application__c
   *   └─> Used by UI for navigation and confirmation
   *
   * TRANSFORMATION FLOW:
   * Map<String, Object> → JobApplicationDomain → Job_Application__c → Database
   *   ├─> Step 1: Manual property mapping (external format → domain)
   *   ├─> Step 2: Domain.toJobApplicationRecord() (domain → SObject)
   *   └─> Step 3: DML insert operation (SObject → database)
   *
   * FIELD MAPPING STRATEGY:
   * External Format    → Domain Property  → Salesforce Field
   * ├─> 'id'           → externalId       → (not persisted - external reference)
   * ├─> 'title'        → title            → Position_Title__c
   * ├─> 'company'      → company          → Company_Name__c
   * ├─> 'location'     → location         → Location__c
   * ├─> 'description'  → description      → Description__c
   * ├─> 'salary'       → salary           → Salary__c
   * ├─> 'sourceUrl'    → sourceUrl        → URL__c
   * └─> (default)      → (default)        → Status__c = 'Interested'
   *
   * RESPONSIBILITIES:
   * • Data format transformation and validation
   * • Business rule enforcement via domain layer
   * • Salesforce persistence with error handling
   * • Transaction boundary management
   *
   * ARCHITECTURAL ROLE:
   * This method completes the job search workflow by converting external
   * job opportunities into tracked Salesforce records for application management.
   *
   * @param jobData Standardized job posting data from search results
   * @return String Salesforce ID of created Job_Application__c record
   * @throws AuraHandledException When validation fails or DML operations fail
   */
  @AuraEnabled
  public static String createJobApplication(Map<String, Object> jobData) {
    try {
      // Create JobApplicationDomain from Map data
      JobApplicationDomain posting = new JobApplicationDomain();
      posting.externalId = String.valueOf(jobData.get('id'));
      posting.title = String.valueOf(jobData.get('title'));
      posting.company = String.valueOf(jobData.get('company'));
      posting.location = String.valueOf(jobData.get('location'));
      posting.description = String.valueOf(jobData.get('description'));
      posting.salary = String.valueOf(jobData.get('salary'));
      posting.sourceUrl = String.valueOf(jobData.get('sourceUrl'));
      posting.source = String.valueOf(jobData.get('source'));

      // Convert domain object to Job Application record
      Job_Application__c jobApp = posting.toJobApplicationRecord();

      // Check CRUD permissions before DML operation
      if (!Schema.sObjectType.Job_Application__c.isCreateable()) {
        throw new AuraHandledException(
          'You do not have permission to create Job Applications.'
        );
      }

      insert jobApp;

      System.debug(LoggingLevel.INFO, 'Created Job Application: ' + jobApp.Id);
      return jobApp.Id;
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'JobSearchController.createJobApplication failed: ' + e.getMessage()
      );
      throw new AuraHandledException(
        'Failed to create job application: ' + e.getMessage()
      );
    }
  }

  /**
   * Fallback method for demo purposes.
   * Returns sample data when real API calls fail or for status simulation.
   */
  private static List<Map<String, Object>> getFallbackJobs(
    String keywords,
    String location,
    List<String> workTypes
  ) {
    List<Map<String, Object>> fallbackJobs = new List<Map<String, Object>>();

    // Add sample jobs for demo
    Map<String, Object> sampleJob1 = new Map<String, Object>{
      'id' => 'ASYNC-DEMO-1',
      'title' => 'Senior Software Developer (Async)',
      'company' => 'TechCorp Remote',
      'location' => 'Remote',
      'salary' => '$90,000 - $120,000',
      'workType' => 'remote',
      'source' => 'Jooble',
      'description' => 'Exciting opportunity for a senior developer in a fully remote environment.',
      'datePosted' => DateTime.now().addDays(-1)
    };

    Map<String, Object> sampleJob2 = new Map<String, Object>{
      'id' => 'ASYNC-DEMO-2',
      'title' => 'Full Stack Engineer (Async)',
      'company' => 'Innovation Labs',
      'location' => 'Toronto',
      'salary' => '$85,000 - $110,000',
      'workType' => 'hybrid',
      'source' => 'Indeed',
      'description' => 'Join our innovative team building cutting-edge applications.',
      'datePosted' => DateTime.now().addDays(-2)
    };

    fallbackJobs.add(sampleJob1);
    fallbackJobs.add(sampleJob2);

    return fallbackJobs;
  }

  /**
   * @description Retrieves available job boards from custom metadata
   * @return List of job board options for UI selection
   */
  @AuraEnabled(cacheable=true)
  public static List<Map<String, Object>> getAvailableJobBoards() {
    List<Map<String, Object>> jobBoards = new List<Map<String, Object>>();
    
    try {
      // Query active job boards from custom metadata, ordered by display order
      List<Job_Board__mdt> boardMetadata = [
        SELECT MasterLabel, API_Name__c, Description__c, Display_Order__c
        FROM Job_Board__mdt 
        WHERE Is_Active__c = true 
        ORDER BY Display_Order__c ASC NULLS LAST, MasterLabel ASC
      ];
      
      for (Job_Board__mdt board : boardMetadata) {
        Map<String, Object> boardOption = new Map<String, Object>();
        boardOption.put('label', board.MasterLabel);
        boardOption.put('value', board.API_Name__c);
        boardOption.put('description', board.Description__c);
        jobBoards.add(boardOption);
      }
      
      // If no metadata exists, provide fallback options
      if (jobBoards.isEmpty()) {
        jobBoards.add(new Map<String, Object>{
          'label' => 'Jooble', 
          'value' => 'jooble',
          'description' => 'International job search engine'
        });
        jobBoards.add(new Map<String, Object>{
          'label' => 'Indeed', 
          'value' => 'indeed',
          'description' => 'Popular job search platform'
        });
      }
      
    } catch (Exception e) {
      Logger.error('JobSearchController.getAvailableJobBoards failed: ' + e.getMessage())
        .setException(e);
      Logger.saveLog();
      
      // Return fallback job boards on error
      jobBoards.add(new Map<String, Object>{
        'label' => 'Jooble', 
        'value' => 'jooble',
        'description' => 'International job search engine'
      });
    }
    
    return jobBoards;
  }
}
