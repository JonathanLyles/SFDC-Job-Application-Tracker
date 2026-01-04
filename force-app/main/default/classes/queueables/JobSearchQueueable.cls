/**
 * Queueable Job: Asynchronous Job Search Processing
 * ================================================
 *
 * This queueable class handles asynchronous job search operations, allowing
 * the system to process multiple job board API calls without blocking the
 * user interface.
 */
public with sharing class JobSearchQueueable implements Queueable, Database.AllowsCallouts {
  private JobSearchCriteria criteria;
  private String searchId;

  /**
   * Constructor for queueable job search
   * @param criteria Search parameters
   * @param searchId Unique identifier for tracking this request
   */
  public JobSearchQueueable(JobSearchCriteria criteria, String searchId) {
    this.criteria = criteria;
    this.searchId = searchId;
  }

  /**
   * Execute the asynchronous job search
   * @param context Queueable context
   */
  public void execute(QueueableContext context) {
    try {
      // Get available strategies for selected boards
      List<IJobBoardSearchStrategy> strategies = JobBoardStrategyRegistry.createStrategies(
        criteria.selectedBoards
      );
      List<JobApplicationDomain> allResults = new List<JobApplicationDomain>();

      // Execute search across all selected job boards
      for (IJobBoardSearchStrategy strategy : strategies) {
        if (strategy.isValidCriteria(criteria)) {
          List<JobApplicationDomain> results = strategy.searchJobs(criteria);
          if (results != null) {
            allResults.addAll(results);
          }
        }
      }

      // Filter valid results
      List<JobApplicationDomain> validResults = new List<JobApplicationDomain>();
      for (JobApplicationDomain job : allResults) {
        if (job.isValid()) {
          validResults.add(job);
        }
      }

      // Store results (implementation would depend on storage mechanism)
      // For now, we'll use debug logs
      Logger.info('Job search completed successfully')
        .setField('SearchId__c', searchId)
        .setField('ValidResults', validResults.size());
    } catch (Exception e) {
      Logger.error('Error in job search queueable')
        .setField('SearchId__c', searchId)
        .setException(e);
    }
    
    Logger.saveLog();
  }
}
