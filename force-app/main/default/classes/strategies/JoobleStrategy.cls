/**
 * Concrete strategy implementation for Jooble job board API integration.
 * Handles Jooble-specific API calls, response parsing, and data normalization.
 */
public class JoobleStrategy implements IJobBoardSearchStrategy {
  private static final String BOARD_NAME = 'Jooble';
  private static final String NAMED_CREDENTIAL = 'JoobleNamedCredential';
  private static final String API_ENDPOINT = '/api/'; //TODO: Probably don't need for Jooble

  /**
   * Search jobs using Jooble API.
   */
  public List<JobApplicationDomain> searchJobs(JobSearchCriteria criteria) {
    List<JobApplicationDomain> results = new List<JobApplicationDomain>();

    try {
      // Build request
      HttpRequest request = buildSearchRequest(criteria);

      // Execute API call
      Http http = new Http();
      HttpResponse response = http.send(request);

      // Parse response
      if (response.getStatusCode() == 200) {
        results = parseJobResponse(response.getBody());
      } else {
        throw new ApiException(
          'Jooble API error: ' +
            response.getStatus() +
            ' - ' +
            response.getBody()
        );
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'JoobleStrategy search failed: ' + e.getMessage()
      );
      throw new ApiException('Failed to search Jooble: ' + e.getMessage(), e);
    }

    return results;
  }

  /**
   * Validates search criteria against Jooble requirements.
   */
  public Boolean isValidCriteria(JobSearchCriteria criteria) {
    // Jooble requires at least keywords OR location
    return criteria.hasField('keywords') || criteria.hasField('location');
  }

  /**
   * Returns the job board name.
   */
  public String getBoardName() {
    return BOARD_NAME;
  }

  /**
   * Returns required fields for this job board.
   */
  public Set<String> getRequiredFields() {
    return new Set<String>{ 'keywords OR location' };
  }

  /**
   * Builds HTTP request for Jooble API.
   */
  private HttpRequest buildSearchRequest(JobSearchCriteria criteria) {
    HttpRequest request = new HttpRequest();
    request.setEndpoint('callout:' + NAMED_CREDENTIAL);
    request.setMethod('POST');
    request.setHeader('Content-Type', 'application/json');

    // Build request body
    Map<String, Object> requestBody = new Map<String, Object>{
      'keywords' => criteria.keywords,
      'location' => criteria.location,
      'page' => '1'
    };

    request.setBody(JSON.serialize(requestBody));

    return request;
  }

  /**
   * Parse Jooble API response into JobApplicationDomain objects.
   */
  private List<JobApplicationDomain> parseJobResponse(String responseBody) {
    List<JobApplicationDomain> jobs = new List<JobApplicationDomain>();

    try {
      Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(
        responseBody
      );
      List<Object> jobsData = (List<Object>) responseData.get('jobs');

      if (jobsData != null) {
        for (Object jobObj : jobsData) {
          Map<String, Object> jobData = (Map<String, Object>) jobObj;
          JobApplicationDomain job = parseJobData(jobData);
          if (job.isValid()) {
            jobs.add(job);
          }
        }
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'Failed to parse Jooble response: ' + e.getMessage()
      );
      throw new ApiException(
        'Failed to parse Jooble response: ' + e.getMessage(),
        e
      );
    }

    return jobs;
  }

  /**
   * Parse individual job data from Jooble response.
   */
  private JobApplicationDomain parseJobData(Map<String, Object> jobData) {
    JobApplicationDomain job = new JobApplicationDomain();

    // Map Jooble fields to Job_Application__c
    job.externalId = String.valueOf(jobData.get('id'));
    job.title = String.valueOf(jobData.get('title'));
    job.company = String.valueOf(jobData.get('company'));
    job.location = String.valueOf(jobData.get('location'));
    job.description = String.valueOf(jobData.get('snippet'));
    job.salary = String.valueOf(jobData.get('salary'));
    job.sourceUrl = String.valueOf(jobData.get('link'));
    job.source = BOARD_NAME;
    job.workType = String.valueOf(jobData.get('type'));

    // Parse date if available
    String dateStr = String.valueOf(jobData.get('updated'));
    if (String.isNotBlank(dateStr)) {
      try {
        job.datePosted = DateTime.valueOf(dateStr);
      } catch (Exception e) {
        System.debug(
          LoggingLevel.WARN,
          'Failed to parse date for Jooble job: ' + dateStr
        );
      }
    }

    return job;
  }

  //TODO: Probably don't need this for Jooble
  /**
   * Get API key from custom settings or metadata.
   * In production, this would come from Named Credential or Custom Settings.
   */
  private String getApiKey() {
    // For demo purposes, using a placeholder
    // In real implementation, this would be retrieved from Named Credential
    return 'YOUR_API_KEY';
  }

  /**
   * Custom exception for API-related errors.
   */
  public class ApiException extends Exception {
  }
}
