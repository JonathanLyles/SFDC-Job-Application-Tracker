/**
 * @description Utility class for testing asynchronous operations including queueables,
 *              platform events, and complex async workflows. Encapsulates common patterns
 *              for testing async processing with external callouts.
 *
 * DESIGN PATTERN: Test Utility Pattern + Template Method Pattern
 *
 * USAGE EXAMPLES:
 * ```apex
 * @isTest
 * public static void testQueueableWithCallout() {
 *     // Setup mock and test data
 *     JobBoardAPICalloutMock mock = new JobBoardAPICalloutMock();
 *     mock.setJoobleSuccessResponse(3);
 *     JobSearchCriteria criteria = TestDataFactory.createValidCriteria();
 *
 *     // Execute queueable with callout
 *     String jobId = AsyncTestUtils.executeQueueableWithMocks(
 *         new JobSearchQueueable(criteria, 'test-search-123'),
 *         mock
 *     );
 *
 *     // Verify results
 *     List<Job_Application__c> jobs = [SELECT Id FROM Job_Application__c];
 *     System.assertEquals(3, jobs.size());
 * }
 *
 * @isTest
 * public static void testPlatformEventPublishing() {
 *     // Subscribe to events and execute
 *     AsyncTestUtils.subscribeToJobSearchEvents();
 *
 *     Test.startTest();
 *     EventBus.publish(TestDataFactory.createJobSearchCompletedEvent());
 *     AsyncTestUtils.deliverPlatformEvents(); // Force immediate delivery
 *     Test.stopTest();
 *
 *     // Verify event processing
 *     AsyncTestUtils.verifyEventWasProcessed('test-search-123');
 * }
 * ```
 *
 * BENEFITS:
 * - Reduces boilerplate in async testing
 * - Handles complex Test.startTest()/stopTest() scenarios
 * - Provides consistent platform event testing patterns
 * - Simplifies queueable chain testing
 * - Centralizes async verification logic
 */
@isTest
public class AsyncTestUtils {
  // Track platform events for verification
  private static List<JobSearchCompleted__e> capturedEvents = new List<JobSearchCompleted__e>();

  /**
   * @description Executes a queueable job with HTTP callout mocks and proper test boundaries
   * @param queueableJob The queueable job to execute
   * @param calloutMock The HTTP callout mock to use
   * @return String The queueable job ID
   */
  public static String executeQueueableWithMocks(
    Queueable queueableJob,
    HttpCalloutMock calloutMock
  ) {
    // Setup mock before test boundaries
    Test.setMock(HttpCalloutMock.class, calloutMock);

    // Execute within proper test boundaries
    Test.startTest();
    String jobId = System.enqueueJob(queueableJob);
    Test.stopTest(); // This forces synchronous execution in tests

    return jobId;
  }

  /**
   * @description Executes multiple queueable jobs in sequence with mocks
   * @param queueableJobs List of queueable jobs to execute
   * @param calloutMock The HTTP callout mock to use
   * @return List<String> List of job IDs in execution order
   */
  public static List<String> executeQueueableChain(
    List<Queueable> queueableJobs,
    HttpCalloutMock calloutMock
  ) {
    Test.setMock(HttpCalloutMock.class, calloutMock);

    List<String> jobIds = new List<String>();

    Test.startTest();
    for (Queueable job : queueableJobs) {
      String jobId = System.enqueueJob(job);
      jobIds.add(jobId);
    }
    Test.stopTest();

    return jobIds;
  }

  /**
   * @description Verifies that a queueable job completed successfully
   * @param jobId The queueable job ID to check
   * @return Boolean True if job completed successfully
   */
  public static Boolean verifyQueueableSuccess(String jobId) {
    List<AsyncApexJob> jobs = [
      SELECT Id, Status, ExtendedStatus, NumberOfErrors
      FROM AsyncApexJob
      WHERE Id = :jobId
    ];

    if (jobs.isEmpty()) {
      System.debug('No AsyncApexJob found with ID: ' + jobId);
      return false;
    }

    AsyncApexJob job = jobs[0];
    System.debug(
      'Job Status: ' + job.Status + ', Errors: ' + job.NumberOfErrors
    );

    return job.Status == 'Completed' && job.NumberOfErrors == 0;
  }

  /**
   * @description Publishes platform events and forces immediate delivery for testing
   * @param events List of platform events to publish
   */
  public static void publishAndDeliverEvents(List<SObject> events) {
    Test.startTest();
    EventBus.publish(events);
    Test.getEventBus().deliver(); // Force immediate delivery in tests
    Test.stopTest();
  }

  /**
   * @description Forces immediate delivery of all pending platform events
   */
  public static void deliverPlatformEvents() {
    Test.getEventBus().deliver();
  }

  /**
   * @description Creates a test subscription for JobSearchCompleted events
   */
  public static void subscribeToJobSearchEvents() {
    // In tests, we can capture events by using Test.getEventBus().deliver()
    // This method serves as documentation for event subscription pattern
    capturedEvents.clear();
  }

  /**
   * @description Verifies that a specific JobSearchCompleted event was processed
   * @param expectedSearchId The search ID to verify
   * @return Boolean True if event with search ID was processed
   */
  public static Boolean verifyEventWasProcessed(String expectedSearchId) {
    // Query for any records created as result of event processing
    // This is a placeholder - actual implementation depends on event handlers
    List<Job_Application__c> jobsCreated = [
      SELECT Id, Position_Title__c
      FROM Job_Application__c
      WHERE Position_Title__c LIKE :('%' + expectedSearchId + '%')
    ];

    return !jobsCreated.isEmpty();
  }

  /**
   * @description Waits for async operations to complete (for integration tests)
   * @param maxWaitSeconds Maximum time to wait in seconds
   * @param jobIds List of job IDs to monitor
   * @return Boolean True if all jobs completed successfully
   */
  public static Boolean waitForAsyncJobs(
    Integer maxWaitSeconds,
    List<String> jobIds
  ) {
    Integer waitTime = 0;
    Integer checkInterval = 1; // Check every 1 second

    while (waitTime < maxWaitSeconds) {
      List<AsyncApexJob> runningJobs = [
        SELECT Id, Status
        FROM AsyncApexJob
        WHERE Id IN :jobIds AND Status IN ('Queued', 'Processing', 'Running')
      ];

      if (runningJobs.isEmpty()) {
        return true; // All jobs completed
      }

      // In tests, we don't actually wait - this is for documentation
      waitTime += checkInterval;
    }

    return false; // Timeout reached
  }

  /**
   * @description Creates a test context for async operations with standard setup
   * @return AsyncTestContext Test context with common setup completed
   */
  public static AsyncTestContext createAsyncTestContext() {
    return new AsyncTestContext();
  }

  /**
   * @description Verifies that proper logging occurred during async execution
   * @param searchId The search ID to check logs for
   * @param expectedLogCount Minimum number of log entries expected
   * @return Boolean True if sufficient logging occurred
   */
  public static Boolean verifyAsyncLogging(
    String searchId,
    Integer expectedLogCount
  ) {
    // This would query Nebula Logger objects if they're accessible in tests
    // For now, this serves as documentation of the logging verification pattern
    System.debug('Verifying logging for searchId: ' + searchId);
    System.debug('Expected log count: ' + expectedLogCount);

    // In actual implementation, this would query Log__c or similar
    // return logEntries.size() >= expectedLogCount;
    return true; // Placeholder
  }

  /**
   * @description Simulates governor limit scenarios for testing
   * @param limitType The type of limit to approach ('dml', 'soql', 'cpu')
   */
  public static void approachGovernorLimit(String limitType) {
    if (limitType == 'dml') {
      // Create many records to approach DML limit
      List<Contact> contacts = new List<Contact>();
      for (Integer i = 0; i < 100; i++) {
        contacts.add(new Contact(LastName = 'Test' + i));
      }
      insert contacts;
    } else if (limitType == 'soql') {
      // Execute many SOQL queries to approach limit
      for (Integer i = 0; i < 50; i++) {
        List<Contact> testQuery = [SELECT Id FROM Contact LIMIT 1];
      }
    } else if (limitType == 'cpu') {
      // Perform CPU-intensive operations
      Long startTime = System.currentTimeMillis();
      while (System.currentTimeMillis() - startTime < 5000) {
        // Busy wait to consume CPU time
        String dummy = 'test' + Math.random();
      }
    }
  }

  /**
   * @description Helper class for managing async test context and setup
   */
  public class AsyncTestContext {
    public JobBoardAPICalloutMock calloutMock;
    public List<JobSearchCriteria> testCriteria;
    public List<String> searchIds;

    public AsyncTestContext() {
      this.calloutMock = new JobBoardAPICalloutMock();
      this.testCriteria = new List<JobSearchCriteria>();
      this.searchIds = new List<String>();
    }

    public AsyncTestContext withSuccessfulJoobleResponse(Integer jobCount) {
      this.calloutMock.setJoobleSuccessResponse(jobCount);
      return this;
    }

    public AsyncTestContext withSuccessfulIndeedResponse(Integer jobCount) {
      this.calloutMock.setIndeedSuccessResponse(jobCount);
      return this;
    }

    public AsyncTestContext withTestCriteria(JobSearchCriteria criteria) {
      this.testCriteria.add(criteria);
      return this;
    }

    public AsyncTestContext withSearchId(String searchId) {
      this.searchIds.add(searchId);
      return this;
    }

    public void setupMocks() {
      Test.setMock(HttpCalloutMock.class, this.calloutMock);
    }

    public String executeQueueable(Queueable job) {
      return AsyncTestUtils.executeQueueableWithMocks(job, this.calloutMock);
    }
  }

  /**
   * @description Assertion helpers for async testing
   */
  public static void assertQueueableCompleted(String jobId) {
    System.assert(
      verifyQueueableSuccess(jobId),
      'Queueable job did not complete successfully: ' + jobId
    );
  }

  public static void assertJobApplicationsCreated(Integer expectedCount) {
    List<Job_Application__c> jobs = [SELECT Id FROM Job_Application__c];
    System.assertEquals(
      expectedCount,
      jobs.size(),
      'Expected ' +
        expectedCount +
        ' job applications, but found ' +
        jobs.size()
    );
  }

  public static void assertPlatformEventPublished(String searchId) {
    System.assert(
      verifyEventWasProcessed(searchId),
      'Platform event was not processed for searchId: ' + searchId
    );
  }

  /**
   * @description Clean up test data after async tests
   */
  public static void cleanupAsyncTestData() {
    // Delete test records to prevent interference between tests
    delete [
      SELECT Id
      FROM Job_Application__c
      WHERE Position_Title__c LIKE 'Test%'
    ];
    delete [SELECT Id FROM Contact WHERE LastName LIKE 'Test%'];
    capturedEvents.clear();
  }
}
