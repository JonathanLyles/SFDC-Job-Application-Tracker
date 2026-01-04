/**
 * @description Executes search against a single job board. This is the core execution
 *              unit that performs HTTP callouts, parses responses, and persists results.
 *              Used both independently for single-board searches and as child queueables
 *              in composite fan-out scenarios.
 * @author Jonathan Lyles
 * @date 2026-01-03
 */
public class SingleBoardSearchQueueable implements Queueable, Database.AllowsCallouts {
  private String searchId;
  private JobSearchCriteria criteria;
  private String jobBoard;
  private Boolean isCompositeChild;

  /**
   * @description Constructor for single board search
   * @param searchId Unique identifier for tracking this search workflow
   * @param criteria Domain object containing search parameters
   * @param jobBoard Name of the job board to search
   */
  public SingleBoardSearchQueueable(
    String searchId,
    JobSearchCriteria criteria,
    String jobBoard
  ) {
    this(searchId, criteria, jobBoard, false);
  }

  /**
   * @description Constructor for composite child queueable
   * @param searchId Unique identifier for tracking this search workflow
   * @param criteria Domain object containing search parameters
   * @param jobBoard Name of the job board to search
   * @param isCompositeChild True if this is part of a composite search
   */
  public SingleBoardSearchQueueable(
    String searchId,
    JobSearchCriteria criteria,
    String jobBoard,
    Boolean isCompositeChild
  ) {
    this.searchId = searchId;
    this.criteria = criteria;
    this.jobBoard = jobBoard;
    this.isCompositeChild = isCompositeChild;
  }

  /**
   * @description Main execution method that performs the job search
   * @param context QueueableContext from Salesforce platform
   */
  public void execute(QueueableContext context) {
    Logger.info('SingleBoardSearchQueueable.execute() starting')
      .setField('SearchId__c', searchId)
      .setField('JobBoard', jobBoard)
      .setField('IsChildOfComposite', isChildOfComposite);

    String status = 'SUCCESS';
    String errorMessage = null;
    Integer totalResults = 0;

    try {
      // Resolve strategy for this job board
      IJobBoardSearchStrategy strategy = JobBoardStrategyRegistry.createStrategy(
        jobBoard
      );

      Logger.debug('Strategy resolved for job board')
        .setField('SearchId__c', searchId)
        .setField('JobBoard', jobBoard);
        'SingleBoardSearchQueueable.execute() - strategy resolved: ' + strategy
      );

      // Execute search via strategy
      List<JobApplicationDomain> results = strategy.searchJobs(criteria);
      totalResults = results != null ? results.size() : 0;

      Logger.info('Search completed with results')
        .setField('SearchId__c', searchId)
        .setField('JobBoard', jobBoard)
        .setField('TotalResults', totalResults);

      // Persist results if any found
      if (totalResults > 0) {
        persistResults(results);
      }
    } catch (Exception e) {
      Logger.error('SingleBoardSearchQueueable.execute() failed')
        .setField('SearchId__c', searchId)
        .setField('JobBoard', jobBoard)
        .setException(e);
      );
      status = 'FAILURE';
      errorMessage = e.getMessage();
    }

    // Publish completion event (for single board) or notify tracking service (for composite)
    if (isCompositeChild) {
      // Notify tracking service for fan-in coordination
      notifyTrackingService(status, totalResults, errorMessage);
    } else {
      // Publish completion event directly for single board searches
      publishCompletionEvent(status, totalResults, errorMessage);
    }
    
    Logger.saveLog();
  }

  /**
   * @description Persists job application results to Salesforce
   * @param results List of job applications to persist
   */
  private void persistResults(List<JobApplicationDomain> results) {
    List<Job_Application__c> recordsToInsert = new List<Job_Application__c>();

    for (JobApplicationDomain result : results) {
      recordsToInsert.add(result.toJobApplicationRecord());
    }

    if (!recordsToInsert.isEmpty()) {
      insert recordsToInsert;
      Logger.info('Records inserted successfully')
        .setField('SearchId__c', searchId)
        .setField('JobBoard', jobBoard)
        .setField('RecordCount', recordsToInsert.size());
    }
  }

  /**
   * @description Notifies tracking service of completion (used in composite searches)
   * @param status SUCCESS, PARTIAL_SUCCESS, or FAILURE
   * @param totalResults Number of results found
   * @param errorMessage Error details if applicable
   */
  private void notifyTrackingService(
    String status,
    Integer totalResults,
    String errorMessage
  ) {
    System.debug(
      'SingleBoardSearchQueueable.notifyTrackingService() - board: ' +
        jobBoard +
        ', status: ' +
        status
    );
    JobSearchTrackingService.notifyBoardCompletion(
      searchId,
      jobBoard,
      status,
      totalResults,
      errorMessage
    );
  }

  /**
   * @description Publishes completion event for single board searches
   * @param status SUCCESS, PARTIAL_SUCCESS, or FAILURE
   * @param totalResults Number of results found
   * @param errorMessage Error details if applicable
   */
  private void publishCompletionEvent(
    String status,
    Integer totalResults,
    String errorMessage
  ) {
    JobSearchCompleted__e event = new JobSearchCompleted__e(
      SearchId__c = searchId,
      Status__c = status,
      JobBoardsProcessed__c = jobBoard,
      TotalResults__c = totalResults,
      ErrorMessage__c = errorMessage
    );

    EventBus.publish(event);
    Logger.info('Completion event published')
      .setField('SearchId__c', searchId)
      .setField('Status', status)
      .setField('TotalResults', totalResults);
    Logger.saveLog();
  }

  /**
   * @description Custom exception for job search errors
   */
  public class JobSearchException extends Exception {
  }
}
