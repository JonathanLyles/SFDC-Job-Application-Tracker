/**
 * Interface defining the contract for job board search strategies.
 * Each job board implementation must provide these core capabilities.
 */
public interface IJobBoardSearchStrategy {
  /**
   * Executes a job search using the provided criteria.
   * @param criteria The search parameters including keywords, location, work types
   * @return List of normalized job postings from the external API as domain objects
   */
  List<JobApplicationDomain> searchJobs(JobSearchCriteria criteria);

  /**
   * Validates if the provided criteria contains all required fields for this job board.
   * @param criteria The search parameters to validate
   * @return true if criteria is valid for this strategy, false otherwise
   */
  Boolean isValidCriteria(JobSearchCriteria criteria);

  /**
   * Returns the human-readable name of this job board.
   * @return The job board name (e.g., "Jooble", "Indeed")
   */
  String getBoardName();

  /**
   * Returns the set of required field names that must be populated in JobSearchCriteria.
   * @return Set of field names required by this specific job board
   */
  Set<String> getRequiredFields();
}
