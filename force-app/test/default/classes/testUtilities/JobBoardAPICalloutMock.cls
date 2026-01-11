/**
 * @description HTTP Callout Mock framework for testing external job board API integrations.
 *              Implements Strategy Pattern to route different endpoints to specific mock handlers.
 *              Provides realistic mock responses for Jooble, Indeed, and other job board APIs.
 *
 * DESIGN PATTERN: Strategy Pattern + Mock Object Pattern
 *
 * USAGE EXAMPLES:
 * ```apex
 * @isTest
 * public static void testJoobleIntegration() {
 *     // Setup mock for successful Jooble response
 *     JobBoardAPICalloutMock mock = new JobBoardAPICalloutMock();
 *     mock.setJoobleSuccessResponse(5); // 5 job results
 *     Test.setMock(HttpCalloutMock.class, mock);
 *
 *     // Execute test
 *     Test.startTest();
 *     JoobleStrategy strategy = new JoobleStrategy();
 *     List<JobApplicationDomain> results = strategy.searchJobs(criteria);
 *     Test.stopTest();
 *
 *     // Verify
 *     System.assertEquals(5, results.size());
 * }
 *
 * @isTest
 * public static void testAPIFailure() {
 *     // Setup mock for API failure
 *     JobBoardAPICalloutMock mock = new JobBoardAPICalloutMock();
 *     mock.setErrorResponse(500, 'Internal Server Error');
 *     Test.setMock(HttpCalloutMock.class, mock);
 *
 *     // Test error handling
 *     // ...
 * }
 * ```
 *
 * BENEFITS:
 * - Consistent mock responses across all tests
 * - Easy to simulate different API scenarios (success, failure, empty results)
 * - Realistic JSON responses based on actual API documentation
 * - Supports multiple job board APIs from single mock framework
 */
@isTest
public class JobBoardAPICalloutMock implements HttpCalloutMock {
  // Strategy pattern: Map endpoints to specific response handlers
  private Map<String, ResponseHandler> endpointHandlers = new Map<String, ResponseHandler>();

  // Default responses for different scenarios
  private ResponseHandler defaultHandler;

  /**
   * @description Main mock response method required by HttpCalloutMock interface
   * @param req The HTTP request being mocked
   * @return HTTPResponse Mock response based on endpoint and configuration
   */
  public HTTPResponse respond(HTTPRequest req) {
    String endpoint = req.getEndpoint();

    // Route to specific handler based on endpoint
    ResponseHandler handler = getHandlerForEndpoint(endpoint);

    if (handler != null) {
      return handler.generateResponse(req);
    }

    // Fallback to default error response
    return createErrorResponse(
      404,
      'Mock not configured for endpoint: ' + endpoint
    );
  }

  /**
   * @description Configure mock to return successful Jooble API response
   * @param jobCount Number of jobs to include in mock response
   */
  public void setJoobleSuccessResponse(Integer jobCount) {
    JoobleResponseHandler handler = new JoobleResponseHandler();
    handler.setSuccessResponse(jobCount);
    endpointHandlers.put('jooble', handler);
    endpointHandlers.put('Jooble', handler); // Case variations
  }

  /**
   * @description Configure mock to return successful Indeed API response
   * @param jobCount Number of jobs to include in mock response
   */
  public void setIndeedSuccessResponse(Integer jobCount) {
    IndeedResponseHandler handler = new IndeedResponseHandler();
    handler.setSuccessResponse(jobCount);
    endpointHandlers.put('indeed', handler);
    endpointHandlers.put('Indeed', handler); // Case variations
  }

  /**
   * @description Configure mock to return empty results (no jobs found)
   * @param jobBoard The job board to configure ('jooble', 'indeed', etc.)
   */
  public void setEmptyResponse(String jobBoard) {
    ResponseHandler handler = getOrCreateHandler(jobBoard);
    handler.setEmptyResponse();
  }

  /**
   * @description Configure mock to return API error response
   * @param statusCode HTTP status code for the error
   * @param errorMessage Error message to include in response
   */
  public void setErrorResponse(Integer statusCode, String errorMessage) {
    this.defaultHandler = new ErrorResponseHandler(statusCode, errorMessage);
  }

  /**
   * @description Configure mock for specific endpoint with custom response
   * @param endpoint The API endpoint to mock
   * @param statusCode HTTP status code
   * @param responseBody JSON response body
   */
  public void setCustomResponse(
    String endpoint,
    Integer statusCode,
    String responseBody
  ) {
    CustomResponseHandler handler = new CustomResponseHandler(
      statusCode,
      responseBody
    );
    endpointHandlers.put(endpoint.toLowerCase(), handler);
  }

  /**
   * @description Configure mock to simulate timeout scenario
   * @param jobBoard The job board to configure for timeout
   */
  public void setTimeoutResponse(String jobBoard) {
    ResponseHandler handler = getOrCreateHandler(jobBoard);
    handler.setTimeout();
  }

  /**
   * @description Gets the appropriate response handler for an endpoint
   * @param endpoint The API endpoint URL
   * @return ResponseHandler for the endpoint, or default handler
   */
  private ResponseHandler getHandlerForEndpoint(String endpoint) {
    String lowerEndpoint = endpoint.toLowerCase();

    // Check for job board specific patterns
    if (lowerEndpoint.contains('jooble')) {
      return endpointHandlers.get('jooble');
    } else if (lowerEndpoint.contains('indeed')) {
      return endpointHandlers.get('indeed');
    }

    // Check direct endpoint mapping
    for (String key : endpointHandlers.keySet()) {
      if (lowerEndpoint.contains(key.toLowerCase())) {
        return endpointHandlers.get(key);
      }
    }

    return defaultHandler;
  }

  /**
   * @description Gets or creates handler for a specific job board
   * @param jobBoard The job board identifier
   * @return ResponseHandler for the job board
   */
  private ResponseHandler getOrCreateHandler(String jobBoard) {
    String key = jobBoard.toLowerCase();
    ResponseHandler handler = endpointHandlers.get(key);

    if (handler == null) {
      if (key.contains('jooble')) {
        handler = new JoobleResponseHandler();
      } else if (key.contains('indeed')) {
        handler = new IndeedResponseHandler();
      } else {
        handler = new GenericResponseHandler();
      }
      endpointHandlers.put(key, handler);
    }

    return handler;
  }

  /**
   * @description Creates a standard error HTTP response
   * @param statusCode HTTP status code
   * @param message Error message
   * @return HTTPResponse with error details
   */
  private HTTPResponse createErrorResponse(Integer statusCode, String message) {
    HTTPResponse response = new HTTPResponse();
    response.setStatusCode(statusCode);
    response.setStatus('Error');
    response.setBody('{"error": "' + message + '"}');
    response.setHeader('Content-Type', 'application/json');
    return response;
  }

  /**
   * @description Base class for handling API responses
   */
  public abstract class ResponseHandler {
    protected Integer statusCode = 200;
    protected String responseBody = '{}';
    protected Boolean isTimeout = false;

    public abstract HTTPResponse generateResponse(HTTPRequest req);

    public void setTimeout() {
      this.isTimeout = true;
    }

    public void setEmptyResponse() {
      this.statusCode = 200;
      this.responseBody = generateEmptyResponseBody();
    }

    protected abstract String generateEmptyResponseBody();
  }

  /**
   * @description Handler for Jooble API responses
   */
  public class JoobleResponseHandler extends ResponseHandler {
    public void setSuccessResponse(Integer jobCount) {
      this.statusCode = 200;
      this.responseBody = generateJoobleResponse(jobCount);
    }

    public override HTTPResponse generateResponse(HTTPRequest req) {
      HTTPResponse response = new HTTPResponse();
      response.setStatusCode(statusCode);
      response.setStatus('OK');
      response.setBody(responseBody);
      response.setHeader('Content-Type', 'application/json');
      return response;
    }

    protected override String generateEmptyResponseBody() {
      return '{"totalCount": 0, "jobs": []}';
    }

    private String generateJoobleResponse(Integer jobCount) {
      List<String> jobs = new List<String>();

      for (Integer i = 1; i <= jobCount; i++) {
        String job =
          '{' +
          '"title": "Test Job ' +
          i +
          '",' +
          '"company": "Test Company ' +
          i +
          '",' +
          '"location": "Test Location ' +
          i +
          '",' +
          '"salary": "$' +
          (50000 + (i * 10000)) +
          '",' +
          '"type": "full-time",' +
          '"link": "https://test-job-' +
          i +
          '.example.com",' +
          '"snippet": "Test job description ' +
          i +
          '",' +
          '"updated": "2024-01-0' +
          Math.mod(i, 9) +
          'T10:00:00Z"' +
          '}';
        jobs.add(job);
      }

      return '{' +
        '"totalCount": ' +
        jobCount +
        ',' +
        '"jobs": [' +
        String.join(jobs, ',') +
        ']' +
        '}';
    }
  }

  /**
   * @description Handler for Indeed API responses
   */
  public class IndeedResponseHandler extends ResponseHandler {
    public void setSuccessResponse(Integer jobCount) {
      this.statusCode = 200;
      this.responseBody = generateIndeedResponse(jobCount);
    }

    public override HTTPResponse generateResponse(HTTPRequest req) {
      HTTPResponse response = new HTTPResponse();
      response.setStatusCode(statusCode);
      response.setStatus('OK');
      response.setBody(responseBody);
      response.setHeader('Content-Type', 'application/json');
      return response;
    }

    protected override String generateEmptyResponseBody() {
      return '{"results": [], "count": 0}';
    }

    private String generateIndeedResponse(Integer jobCount) {
      List<String> jobs = new List<String>();

      for (Integer i = 1; i <= jobCount; i++) {
        String job =
          '{' +
          '"jobTitle": "Indeed Test Job ' +
          i +
          '",' +
          '"company": "Indeed Company ' +
          i +
          '",' +
          '"formattedLocation": "Indeed Location ' +
          i +
          '",' +
          '"salary": "$' +
          (60000 + (i * 5000)) +
          '",' +
          '"jobType": "FullTime",' +
          '"url": "https://indeed-job-' +
          i +
          '.example.com",' +
          '"snippet": "Indeed job description ' +
          i +
          '",' +
          '"date": "2024-01-0' +
          Math.mod(i, 9) +
          '"' +
          '}';
        jobs.add(job);
      }

      return '{' +
        '"results": [' +
        String.join(jobs, ',') +
        '],' +
        '"count": ' +
        jobCount +
        '}';
    }
  }

  /**
   * @description Generic response handler for other job boards
   */
  public class GenericResponseHandler extends ResponseHandler {
    public void setSuccessResponse(Integer jobCount) {
      this.statusCode = 200;
      this.responseBody = '{"status": "success", "count": ' + jobCount + '}';
    }

    public override HTTPResponse generateResponse(HTTPRequest req) {
      HTTPResponse response = new HTTPResponse();
      response.setStatusCode(statusCode);
      response.setStatus('OK');
      response.setBody(responseBody);
      response.setHeader('Content-Type', 'application/json');
      return response;
    }

    protected override String generateEmptyResponseBody() {
      return '{"status": "success", "count": 0, "results": []}';
    }
  }

  /**
   * @description Handler for custom responses
   */
  public class CustomResponseHandler extends ResponseHandler {
    public CustomResponseHandler(Integer statusCode, String responseBody) {
      this.statusCode = statusCode;
      this.responseBody = responseBody;
    }

    public override HTTPResponse generateResponse(HTTPRequest req) {
      HTTPResponse response = new HTTPResponse();
      response.setStatusCode(statusCode);
      response.setStatus(statusCode == 200 ? 'OK' : 'Error');
      response.setBody(responseBody);
      response.setHeader('Content-Type', 'application/json');
      return response;
    }

    protected override String generateEmptyResponseBody() {
      return responseBody; // Use provided body as-is
    }
  }

  /**
   * @description Handler for error responses
   */
  public class ErrorResponseHandler extends ResponseHandler {
    private String errorMessage;

    public ErrorResponseHandler(Integer statusCode, String errorMessage) {
      this.statusCode = statusCode;
      this.errorMessage = errorMessage;
      this.responseBody = '{"error": "' + errorMessage + '"}';
    }

    public override HTTPResponse generateResponse(HTTPRequest req) {
      HTTPResponse response = new HTTPResponse();
      response.setStatusCode(statusCode);
      response.setStatus('Error');
      response.setBody(responseBody);
      response.setHeader('Content-Type', 'application/json');
      return response;
    }

    protected override String generateEmptyResponseBody() {
      return responseBody; // Error response is the same
    }
  }
}
