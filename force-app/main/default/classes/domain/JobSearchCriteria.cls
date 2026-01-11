/**
 * Domain class representing normalized job search criteria.
 *
 * DESIGN PATTERN: Domain Model
 * This class encapsulates search parameters and validation logic, providing a clean
 * abstraction for job search criteria that can be used across different layers:
 *
 * UI LAYER (Lightning Web Components):
 *   - jobSearch LWC collects form inputs and delegates to controller:
 *     callApexMethod(keywords, location, workTypes)
 *   - Validates basic input before sending to backend:
 *     if (keywords || location) { callApexMethod(keywords, location, workTypes) }
 *
 * SERVICE LAYER (JobSearchService):
 *   - Receives criteria from controller and coordinates multi-board search:
 *     searchJobsAsync(JobSearchCriteria criteria)
 *   - Determines which boards to search based on criteria.selectedBoards
 *   - Passes criteria to appropriate strategy implementations
 *
 * STRATEGY LAYER (JoobleStrategy, IndeedStrategy):
 *   - Uses criteria.hasField() to check parameter availability:
 *     if (criteria.hasField('salaryMin')) { addSalaryFilter() }
 *   - Maps domain criteria to API-specific parameters:
 *     buildJoobleRequest(criteria.keywords, criteria.location)
 *
 * CONTROLLER LAYER (JobSearchController):
 *   - Creates criteria from LWC parameters and delegates to service:
 *     JobSearchCriteria criteria = new JobSearchCriteria(keywords, location, workTypes);
 *     return jobSearchService.searchJobsAsync(criteria);
 *
 * CONSTRUCTOR OVERLOADING PATTERN:
 * Two constructors provide flexibility while maintaining code reuse:
 * 1. Basic constructor: For searching all available job boards (default behavior)
 * 2. Extended constructor: For targeting specific job boards (selective search)
 *
 * This design supports both "search everywhere" and "search specific boards" scenarios
 * without code duplication, using constructor chaining for DRY principle.
 */
public with sharing class JobSearchCriteria {
  // Core search parameters - at least one of keywords or location is required
  public String keywords { get; set; }
  public String location { get; set; }
  public List<String> workTypes { get; set; }

  // Job board targeting - empty list means "search all boards"
  public List<String> selectedBoards { get; set; }

  // Additional optional criteria for advanced filtering
  public String salaryMin { get; set; }
  public String salaryMax { get; set; }
  public String experienceLevel { get; set; }

  /**
   * Basic constructor for searching all available job boards.
   *
   * USE CASE: When users want maximum job coverage across all integrated boards
   * BEHAVIOR: Sets selectedBoards to empty list, which signals the service layer
   *           to search all available job board strategies
   *
   * @param keywords Search terms for job titles, descriptions, etc.
   * @param location Geographic location for job search
   * @param workTypes List of employment types (full-time, part-time, contract, etc.)
   */
  public JobSearchCriteria(
    String keywords,
    String location,
    List<String> workTypes
  ) {
    this.keywords = keywords;
    this.location = location;
    // Defensive programming: ensure workTypes is never null
    this.workTypes = workTypes != null ? workTypes : new List<String>();
    // Empty selectedBoards signals "search all boards"
    this.selectedBoards = new List<String>();
  }

  /**
   * Extended constructor for selective job board searching.
   *
   * USE CASE: When users want to limit search to specific, trusted job boards
   *           or when certain boards are known to have better results for specific roles
   * BEHAVIOR: Uses constructor chaining to reuse basic initialization logic,
   *           then sets specific board selection
   *
   * CONSTRUCTOR CHAINING PATTERN:
   * Uses this() call to invoke the basic constructor, avoiding code duplication
   * and ensuring consistent initialization of core fields
   *
   * @param keywords Search terms for job titles, descriptions, etc.
   * @param location Geographic location for job search
   * @param workTypes List of employment types
   * @param selectedBoards Specific job boards to search (e.g., ["jooble", "indeed"])
   */
  public JobSearchCriteria(
    String keywords,
    String location,
    List<String> workTypes,
    List<String> selectedBoards
  ) {
    // Constructor chaining: reuse basic constructor logic
    this(keywords, location, workTypes);
    // Override selectedBoards with specific selection
    this.selectedBoards = selectedBoards != null
      ? selectedBoards
      : new List<String>();
  }

  /**
   * BUILDER PATTERN: Static factory method to reduce parameter count
   * Creates a criteria with only essential fields
   */
  public static JobSearchCriteria create(String keywords, String location) {
    return new JobSearchCriteria(keywords, location, new List<String>());
  }

  /**
   * BUILDER PATTERN: Fluent method to set job boards
   */
  public JobSearchCriteria withJobBoards(List<String> boards) {
    this.selectedBoards = boards != null ? boards : new List<String>();
    return this;
  }

  /**
   * BUILDER PATTERN: Fluent method to set work types
   */
  public JobSearchCriteria withWorkTypes(List<String> types) {
    this.workTypes = types != null ? types : new List<String>();
    return this;
  }

  /**
   * Validates if basic required fields are populated.
   *
   * BUSINESS RULE: At least one of keywords OR location must be provided
   * This prevents completely empty searches that would return too many results
   * and waste API calls to job board services.
   *
   * @return Boolean True if search criteria has enough information to proceed
   */
  public Boolean isValid() {
    return String.isNotBlank(keywords) || String.isNotBlank(location);
  }

  /**
   * Checks if a specific field has a value.
   *
   * UTILITY METHOD: Used by strategy implementations to determine which
   * search parameters to include in API calls. Different job boards
   * support different parameters, so strategies can check field availability
   * before building requests.
   *
   * @param fieldName The field to check (case-insensitive)
   * @return Boolean True if the field has a non-empty value
   */
  public Boolean hasField(String fieldName) {
    switch on fieldName.toLowerCase() {
      when 'keywords' {
        return String.isNotBlank(keywords);
      }
      when 'location' {
        return String.isNotBlank(location);
      }
      when 'worktypes' {
        return workTypes != null && !workTypes.isEmpty();
      }
      when 'salarymin' {
        return String.isNotBlank(salaryMin);
      }
      when 'salarymax' {
        return String.isNotBlank(salaryMax);
      }
      when 'experiencelevel' {
        return String.isNotBlank(experienceLevel);
      }
      when else {
        return false;
      }
    }
  }

  /**
   * Returns a string representation for logging purposes.
   *
   * DEBUGGING SUPPORT: Provides meaningful output for logging search criteria
   * in service layer operations, helping with troubleshooting and monitoring
   * without exposing sensitive data.
   *
   * @return String Formatted representation of key search parameters
   */
  public override String toString() {
    return String.format(
      'JobSearchCriteria[keywords={0}, location={1}, workTypes={2}, boards={3}]',
      new List<Object>{ keywords, location, workTypes, selectedBoards }
    );
  }
}
