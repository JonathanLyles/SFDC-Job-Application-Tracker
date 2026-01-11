/**
 * @description Centralized test data factory for creating consistent test objects
 *              across all test classes in the Job Application Tracker application.
 *              Follows the Test Data Builder pattern to ensure maintainable and
 *              consistent test data creation.
 *
 * DESIGN PATTERN: Test Data Factory & Builder Pattern
 *
 * USAGE EXAMPLES:
 * ```apex
 * // Basic valid criteria for simple tests
 * JobSearchCriteria criteria = TestDataFactory.createValidCriteria();
 *
 * // Custom criteria with specific parameters
 * JobSearchCriteria criteria = TestDataFactory.createCriteriaBuilder()
 *     .withKeywords('Senior Developer')
 *     .withLocation('Remote')
 *     .withJobBoards(new List<String>{'indeed', 'jooble'})
 *     .build();
 *
 * // Sample job application for testing persistence
 * Job_Application__c job = TestDataFactory.createJobApplication();
 *
 * // Domain object for testing business logic
 * JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();
 * ```
 *
 * BENEFITS:
 * - Single point of change when domain objects evolve
 * - Consistent test data across all test classes
 * - Builder pattern for flexible test scenarios
 * - Reduces boilerplate code in individual tests
 */
@isTest
public class TestDataFactory {
  // Counter for unique data generation
  private static Integer counter = 1;

  /**
   * @description Creates basic valid JobSearchCriteria for simple test scenarios
   * @return JobSearchCriteria with standard test values
   */
  public static JobSearchCriteria createValidCriteria() {
    return JobSearchCriteria.create('Software Developer', 'Toronto')
      .withWorkTypes(new List<String>{ 'remote' })
      .withJobBoards(new List<String>{ 'jooble' });
  }

  /**
   * @description Creates JobSearchCriteria with empty job boards (search all boards)
   * @return JobSearchCriteria configured to search all available job boards
   */
  public static JobSearchCriteria createCriteriaForAllBoards() {
    return JobSearchCriteria.create('Java Developer', 'Vancouver')
      .withWorkTypes(new List<String>{ 'onsite', 'hybrid' })
      .withJobBoards(new List<String>()); // Empty = search all boards
  }

  /**
   * @description Creates JobSearchCriteria for testing validation failures
   * @return JobSearchCriteria with invalid data (empty keywords and location)
   */
  public static JobSearchCriteria createInvalidCriteria() {
    return JobSearchCriteria.create('', '') // Both empty should fail validation
      .withWorkTypes(new List<String>())
      .withJobBoards(new List<String>());
  }

  /**
   * @description Creates builder for custom JobSearchCriteria configuration
   * @return CriteriaBuilder for fluent test data creation
   */
  public static CriteriaBuilder createCriteriaBuilder() {
    return new CriteriaBuilder();
  }

  /**
   * @description Creates a sample JobApplicationDomain for testing business logic
   * @return JobApplicationDomain with realistic test data
   */
  public static JobApplicationDomain createSampleJobDomain() {
    return createSampleJobDomain('Software Engineer');
  }

  /**
   * @description Creates a sample JobApplicationDomain with custom title
   * @param title The job title for the domain object
   * @return JobApplicationDomain with specified title and test data
   */
  public static JobApplicationDomain createSampleJobDomain(String title) {
    JobApplicationDomain domain = new JobApplicationDomain();
    domain.title = title;
    domain.company = 'Test Company ' + counter;
    domain.location = 'Test City';
    domain.salary = '$80,000 - $100,000';
    domain.workType = 'Remote';
    domain.source = 'jooble';
    domain.description = 'Test job description for ' + title;
    domain.sourceUrl = 'https://test-job-' + counter + '.example.com';
    domain.externalId = 'test-job-' + counter;
    counter++;
    return domain;
  }

  /**
   * @description Creates Job_Application__c record for testing persistence
   * @return Job_Application__c record with test data (not inserted)
   */
  public static Job_Application__c createJobApplication() {
    return createJobApplication('Test Job ' + counter);
  }

  /**
   * @description Creates Job_Application__c record with custom title
   * @param title The job title
   * @return Job_Application__c record with test data (not inserted)
   */
  public static Job_Application__c createJobApplication(String title) {
    Job_Application__c job = new Job_Application__c();
    job.Position_Title__c = title;
    job.Company_Name__c = 'Test Company ' + counter;
    job.Location__c = 'Test Location';
    job.Salary__c = 75000;
    // job.Work_Type__c = 'Hybrid'; // Field doesn't exist
    // job.Source__c = 'indeed'; // Field doesn't exist
    job.Description__c = 'Test description for ' + title;
    job.URL__c = 'https://test-' + counter + '.example.com';
    // job.External_ID__c = 'test-ext-' + counter; // Field doesn't exist
    job.Status__c = 'New';
    counter++;
    return job;
  }

  /**
   * @description Creates and inserts Job_Application__c record for integration tests
   * @return Inserted Job_Application__c record with Id
   */
  public static Job_Application__c createAndInsertJobApplication() {
    Job_Application__c job = createJobApplication();
    insert job;
    return job;
  }

  /**
   * @description Creates multiple Job_Application__c records for bulk testing
   * @param count Number of records to create
   * @return List of Job_Application__c records (not inserted)
   */
  public static List<Job_Application__c> createJobApplications(Integer count) {
    List<Job_Application__c> jobs = new List<Job_Application__c>();
    for (Integer i = 0; i < count; i++) {
      jobs.add(createJobApplication('Bulk Test Job ' + i));
    }
    return jobs;
  }

  /**
   * @description Creates Contact record for testing trigger scenarios
   * @return Contact record with test data (not inserted)
   */
  public static Contact createTestContact() {
    Contact contact = new Contact();
    contact.FirstName = 'Test';
    contact.LastName = 'Contact ' + counter;
    contact.Email = 'test' + counter + '@example.com';
    contact.Phone = '555-0' + String.valueOf(counter).leftPad(3, '0');
    counter++;
    return contact;
  }

  /**
   * @description Creates and inserts Contact for integration tests
   * @return Inserted Contact record with Id
   */
  public static Contact createAndInsertTestContact() {
    Contact contact = createTestContact();
    insert contact;
    return contact;
  }

  /**
   * @description Creates JobSearchCompleted__e platform event for testing
   * @return JobSearchCompleted__e event with test data
   */
  public static JobSearchCompleted__e createJobSearchCompletedEvent() {
    return createJobSearchCompletedEvent('test-search-123');
  }

  /**
   * @description Creates JobSearchCompleted__e platform event with custom searchId
   * @param searchId The search identifier for the event
   * @return JobSearchCompleted__e event with specified searchId
   */
  public static JobSearchCompleted__e createJobSearchCompletedEvent(
    String searchId
  ) {
    JobSearchCompleted__e event = new JobSearchCompleted__e();
    event.SearchId__c = searchId;
    event.Status__c = 'SUCCESS';
    event.TotalResults__c = 5;
    event.ErrorMessage__c = null;
    return event;
  }

  /**
   * @description Builder class for creating custom JobSearchCriteria
   */
  public class CriteriaBuilder {
    private String keywords = 'Default Test Job';
    private String location = 'Default Test City';
    private List<String> workTypes = new List<String>{ 'remote' };
    private List<String> jobBoards = new List<String>{ 'jooble' };

    public CriteriaBuilder withKeywords(String keywords) {
      this.keywords = keywords;
      return this;
    }

    public CriteriaBuilder withLocation(String location) {
      this.location = location;
      return this;
    }

    public CriteriaBuilder withWorkTypes(List<String> workTypes) {
      this.workTypes = workTypes;
      return this;
    }

    public CriteriaBuilder withJobBoards(List<String> jobBoards) {
      this.jobBoards = jobBoards;
      return this;
    }

    public JobSearchCriteria build() {
      return JobSearchCriteria.create(keywords, location)
        .withWorkTypes(workTypes)
        .withJobBoards(jobBoards);
    }
  }
}
