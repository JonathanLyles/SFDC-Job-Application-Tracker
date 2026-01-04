/**
 * @description Orchestrates job search execution by determining whether to route
 *              to single board or composite (multi-board) search queueables.
 *              This is the main entry point for async job search execution.
 * @author Jonathan Lyles
 * @date 2026-01-03
 */
public class JobSearchOrchestratorQueueable implements Queueable {
  private String searchId;
  private JobSearchCriteria criteria;

  /**
   * @description Constructor for orchestration queueable
   * @param searchId Unique identifier for tracking this search workflow
   * @param criteria Domain object containing search parameters
   */
  public JobSearchOrchestratorQueueable(
    String searchId,
    JobSearchCriteria criteria
  ) {
    this.searchId = searchId;
    this.criteria = criteria;
  }

  /**
   * @description Main execution method that routes to appropriate search strategy
   * @param context QueueableContext from Salesforce platform
   */
  public void execute(QueueableContext context) {
    Logger.info('JobSearchOrchestratorQueueable.execute() starting')
      .setField('SearchId__c', searchId)
      .setField('Criteria', criteria);

    try {
      List<String> selectedBoards = criteria.selectedBoards;
      if (selectedBoards == null || selectedBoards.isEmpty()) {
        publishFailureEvent('No job boards selected for search');
        return;
      }

      if (selectedBoards.size() == 1) {
        // Single board scenario
        System.debug(
          'JobSearchOrchestratorQueueable.execute() - routing to single board: ' +
          selectedBoards[0]
        );
        System.enqueueJob(
          new SingleBoardSearchQueueable(searchId, criteria, selectedBoards[0])
        );
      } else {
        // Composite (multi-board) scenario
        System.debug(
          'JobSearchOrchestratorQueueable.execute() - routing to composite boards: ' +
          selectedBoards
        );
        System.enqueueJob(
          new CompositeBoardSearchQueueable(searchId, criteria, selectedBoards)
        );
      }
    } catch (Exception e) {
      System.debug(
        'JobSearchOrchestratorQueueable.execute() - ERROR: ' + e.getMessage()
      );
      publishFailureEvent('Orchestration failed: ' + e.getMessage());
    }
  }

  /**
   * @description Publishes failure event when orchestration encounters errors
   * @param errorMessage Details of the failure
   */
  private void publishFailureEvent(String errorMessage) {
    Logger.error('JobSearchOrchestratorQueueable publishing failure event')
      .setField('SearchId__c', searchId)
      .setField('ErrorMessage', errorMessage);
    
    JobSearchCompleted__e event = new JobSearchCompleted__e(
      SearchId__c = searchId,
      Status__c = 'FAILURE',
      ErrorMessage__c = errorMessage,
      TotalResults__c = 0
    );

    EventBus.publish(event);
    Logger.saveLog();
  }
}
