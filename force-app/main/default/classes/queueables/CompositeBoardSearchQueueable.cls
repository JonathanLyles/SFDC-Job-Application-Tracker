/**
 * @description Orchestrates fan-out execution for multi-board job searches.
 *              Enqueues multiple SingleBoardSearchQueueable instances and coordinates
 *              with JobSearchTrackingService for fan-in completion detection.
 * @author Jonathan Lyles
 * @date 2026-01-03
 */
public class CompositeBoardSearchQueueable implements Queueable {
  private String searchId;
  private JobSearchCriteria criteria;
  private List<String> jobBoards;

  /**
   * @description Constructor for composite board search
   * @param searchId Unique identifier for tracking this search workflow
   * @param criteria Domain object containing search parameters
   * @param jobBoards List of job board names to search
   */
  public CompositeBoardSearchQueueable(
    String searchId,
    JobSearchCriteria criteria,
    List<String> jobBoards
  ) {
    this.searchId = searchId;
    this.criteria = criteria;
    this.jobBoards = jobBoards;
  }

  /**
   * @description Main execution method that fans out to multiple single board searches
   * @param context QueueableContext from Salesforce platform
   */
  public void execute(QueueableContext context) {
    System.debug(
      'CompositeBoardSearchQueueable.execute() - searchId: ' + searchId
    );
    System.debug(
      'CompositeBoardSearchQueueable.execute() - boards: ' + jobBoards
    );

    try {
      // Initialize tracking for this composite search
      initializeTracking();

      // Fan-out: enqueue SingleBoardSearchQueueable for each job board
      for (String board : jobBoards) {
        System.debug(
          'CompositeBoardSearchQueueable.execute() - enqueuing board: ' + board
        );
        System.enqueueJob(
          new SingleBoardSearchQueueable(searchId, criteria, board, true)
        );
      }

      System.debug(
        'CompositeBoardSearchQueueable.execute() - fan-out complete, ' +
          jobBoards.size() +
          ' boards enqueued'
      );
    } catch (Exception e) {
      System.debug(
        'CompositeBoardSearchQueueable.execute() - ERROR: ' + e.getMessage()
      );
      publishFailureEvent('Composite fan-out failed: ' + e.getMessage());
    }
  }

  /**
   * @description Initializes tracking state for the composite search
   */
  private void initializeTracking() {
    System.debug(
      'CompositeBoardSearchQueueable.initializeTracking() - searchId: ' +
      searchId
    );
    JobSearchTrackingService.initializeCompositeSearch(searchId, jobBoards);
  }

  /**
   * @description Publishes failure event when fan-out encounters errors
   * @param errorMessage Details of the failure
   */
  private void publishFailureEvent(String errorMessage) {
    JobSearchCompleted__e event = new JobSearchCompleted__e(
      SearchId__c = searchId,
      Status__c = 'FAILURE',
      JobBoardsProcessed__c = String.join(jobBoards, ','),
      ErrorMessage__c = errorMessage,
      TotalResults__c = 0
    );

    EventBus.publish(event);
  }
}
