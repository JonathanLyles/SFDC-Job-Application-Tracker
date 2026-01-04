/**
 * Concrete strategy implementation for Indeed job board API integration.
 * Handles Indeed-specific API calls, response parsing, and data normalization.
 */
public class IndeedStrategy implements IJobBoardSearchStrategy {
  private static final String BOARD_NAME = 'Indeed';
  private static final String NAMED_CREDENTIAL = 'Indeed_API';
  private static final String API_ENDPOINT = '/ads/apisearch';

  /**
   * Search jobs using Indeed API.
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
          'Indeed API error: ' +
            response.getStatus() +
            ' - ' +
            response.getBody()
        );
      }
    } catch (Exception e) {
      System.debug(
        LoggingLevel.ERROR,
        'IndeedStrategy search failed: ' + e.getMessage()
      );
      throw new ApiException('Failed to search Indeed: ' + e.getMessage(), e);
    }

    return results;
  }

  /**
   * Validates search criteria against Indeed requirements.
   */
  public Boolean isValidCriteria(JobSearchCriteria criteria) {
    // Indeed requires keywords and location
    return criteria.hasField('keywords') && criteria.hasField('location');
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
    return new Set<String>{ 'keywords', 'location' };
  }

  /**
   * Builds HTTP request for Indeed API.
   */
  private HttpRequest buildSearchRequest(JobSearchCriteria criteria) {
    HttpRequest request = new HttpRequest();

    // Build query parameters
    List<String> queryParams = new List<String>();
    queryParams.add(
      'publisher=' + EncodingUtil.urlEncode(getPublisherId(), 'UTF-8')
    );
    queryParams.add('q=' + EncodingUtil.urlEncode(criteria.keywords, 'UTF-8'));
    queryParams.add('l=' + EncodingUtil.urlEncode(criteria.location, 'UTF-8'));
    queryParams.add('format=json');
    queryParams.add('v=2');
    queryParams.add('limit=25');

    String endpoint =
      'callout:' +
      NAMED_CREDENTIAL +
      API_ENDPOINT +
      '?' +
      String.join(queryParams, '&');

    request.setEndpoint(endpoint);
    request.setMethod('GET');
    request.setHeader('User-Agent', 'Salesforce Job Application Tracker');

    return request;
  }

  /**
   * Parse Indeed API response into JobApplicationDomain objects.
   */
  private List<JobApplicationDomain> parseJobResponse(String responseBody) {
    List<JobApplicationDomain> jobs = new List<JobApplicationDomain>();

    try {
      Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(
        responseBody
      );
      List<Object> resultsData = (List<Object>) responseData.get('results');

      if (resultsData != null) {
        for (Object jobObj : resultsData) {
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
        'Failed to parse Indeed response: ' + e.getMessage()
      );
      throw new ApiException(
        'Failed to parse Indeed response: ' + e.getMessage(),
        e
      );
    }

    return jobs;
  }

  /**
   * Parse individual job data from Indeed response.
   */
  private JobApplicationDomain parseJobData(Map<String, Object> jobData) {
    JobApplicationDomain job = new JobApplicationDomain();

    // Map Indeed fields to Job_Application__c
    job.externalId = String.valueOf(jobData.get('jobkey'));
    job.title = String.valueOf(jobData.get('jobtitle'));
    job.company = String.valueOf(jobData.get('company'));
    job.location = String.valueOf(jobData.get('formattedLocation'));
    job.description = String.valueOf(jobData.get('snippet'));
    job.sourceUrl = String.valueOf(jobData.get('url'));
    job.source = BOARD_NAME;

    // Parse salary if available
    String salaryMin = String.valueOf(jobData.get('salarymin'));
    String salaryMax = String.valueOf(jobData.get('salarymax'));
    if (String.isNotBlank(salaryMin) && String.isNotBlank(salaryMax)) {
      job.salary = '$' + salaryMin + ' - $' + salaryMax;
    }

    // Parse date
    String dateStr = String.valueOf(jobData.get('date'));
    if (String.isNotBlank(dateStr)) {
      try {
        job.datePosted = DateTime.valueOf(dateStr);
      } catch (Exception e) {
        System.debug(
          LoggingLevel.WARN,
          'Failed to parse date for Indeed job: ' + dateStr
        );
      }
    }

    // Indeed-specific fields
    Object indeedApply = jobData.get('indeedApply');
    job.jobType = String.valueOf(jobData.get('jobtype'));

    return job;
  }

  /**
   * Get publisher ID from custom settings or metadata.
   * In production, this would come from Named Credential or Custom Settings.
   */
  private String getPublisherId() {
    // For demo purposes, using a placeholder
    // In real implementation, this would be retrieved from Named Credential
    return 'YOUR_PUBLISHER_ID';
  }

  /**
   * Custom exception for API-related errors.
   */
  public class ApiException extends Exception {
  }
}
