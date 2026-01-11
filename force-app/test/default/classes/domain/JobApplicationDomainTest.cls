/**
 * @description Comprehensive test class for JobApplicationDomain.cls
 *              Tests data validation, business rules, transformations, and edge cases
 *              for the core domain model representing unified job postings.
 *
 * COVERAGE TARGET: 95% (Domain Layer Critical Business Rules)
 *
 * TEST STRATEGY:
 * - Constructor Testing: Verify object creation with valid/invalid parameters
 * - Validation Testing: Ensure business rules are properly enforced
 * - Transformation Testing: Verify domain → Salesforce and domain → LWC conversions
 * - Edge Case Testing: Handle null values, empty strings, malformed data
 * - Business Logic Testing: Salary parsing, data normalization, formatting
 *
 * DESIGN PATTERNS USED:
 * - Test Data Factory: Centralized test object creation
 * - Arrange-Act-Assert: Clear test structure
 * - Parameterized Testing: Multiple scenarios in single test method
 */
@isTest
public class JobApplicationDomainTest {
  /**
   * @description Test suite for domain object construction and initialization
   */
  @isTest
  public static void testDefaultConstructor() {
    // Arrange & Act
    JobApplicationDomain domain = new JobApplicationDomain();

    // Assert
    System.assertNotEquals(
      null,
      domain,
      'Default constructor should create domain object'
    );
    System.assertNotEquals(
      null,
      domain.skills,
      'Skills list should be initialized'
    );
    System.assertEquals(
      0,
      domain.skills.size(),
      'Skills list should be empty by default'
    );
  }

  @isTest
  public static void testParameterizedConstructor() {
    // Arrange
    String testExternalId = 'test-job-123';
    String testTitle = 'Software Engineer';
    String testCompany = 'TechCorp';
    String testSource = 'jooble';

    // Act
    JobApplicationDomain domain = new JobApplicationDomain(
      testExternalId,
      testTitle,
      testCompany,
      testSource
    );

    // Assert
    System.assertEquals(
      testExternalId,
      domain.externalId,
      'External ID should be set correctly'
    );
    System.assertEquals(
      testTitle,
      domain.title,
      'Title should be set correctly'
    );
    System.assertEquals(
      testCompany,
      domain.company,
      'Company should be set correctly'
    );
    System.assertEquals(
      testSource,
      domain.source,
      'Source should be set correctly'
    );
    System.assertNotEquals(
      null,
      domain.skills,
      'Skills list should be initialized'
    );
  }

  /**
   * @description Test suite for domain object validation business rules
   */
  @isTest
  public static void testValidationWithValidData() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();

    // Act
    Boolean isValid = domain.isValid();

    // Assert
    System.assertEquals(
      true,
      isValid,
      'Valid domain object should pass validation'
    );
  }

  @isTest
  public static void testValidationWithMissingExternalId() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();
    domain.externalId = null;

    // Act
    Boolean isValid = domain.isValid();

    // Assert
    System.assertEquals(
      false,
      isValid,
      'Domain object without external ID should fail validation'
    );
  }

  @isTest
  public static void testValidationWithEmptyTitle() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();
    domain.title = '';

    // Act
    Boolean isValid = domain.isValid();

    // Assert
    System.assertEquals(
      false,
      isValid,
      'Domain object with empty title should fail validation'
    );
  }

  @isTest
  public static void testValidationWithBlankCompany() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();
    domain.company = '   '; // Whitespace only

    // Act
    Boolean isValid = domain.isValid();

    // Assert
    System.assertEquals(
      false,
      isValid,
      'Domain object with blank company should fail validation'
    );
  }

  @isTest
  public static void testValidationWithMissingSource() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();
    domain.source = null;

    // Act
    Boolean isValid = domain.isValid();

    // Assert
    System.assertEquals(
      false,
      isValid,
      'Domain object without source should fail validation'
    );
  }

  /**
   * @description Test suite for Lightning Web Component transformation
   */
  @isTest
  public static void testToLWCMapWithCompleteData() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();
    domain.externalId = 'lwc-test-123';
    domain.datePosted = DateTime.now();
    domain.jobType = 'Full-time';
    domain.experienceLevel = 'Mid-level';

    // Act
    Map<String, Object> lwcMap = domain.toLWCMap();

    // Assert
    System.assertNotEquals(null, lwcMap, 'LWC map should be created');
    System.assertEquals(
      domain.externalId,
      lwcMap.get('id'),
      'External ID should map to id field'
    );
    System.assertEquals(
      domain.title,
      lwcMap.get('title'),
      'Title should be mapped correctly'
    );
    System.assertEquals(
      domain.company,
      lwcMap.get('company'),
      'Company should be mapped correctly'
    );
    System.assertEquals(
      domain.location,
      lwcMap.get('location'),
      'Location should be mapped correctly'
    );
    System.assertEquals(
      domain.salary,
      lwcMap.get('salary'),
      'Salary should be mapped correctly'
    );
    System.assertEquals(
      domain.workType,
      lwcMap.get('workType'),
      'Work type should be mapped correctly'
    );
    System.assertEquals(
      domain.source,
      lwcMap.get('source'),
      'Source should be mapped correctly'
    );
    System.assertEquals(
      domain.description,
      lwcMap.get('description'),
      'Description should be mapped correctly'
    );
    System.assertEquals(
      domain.sourceUrl,
      lwcMap.get('sourceUrl'),
      'Source URL should be mapped correctly'
    );
    System.assertEquals(
      domain.datePosted,
      lwcMap.get('datePosted'),
      'Date posted should be mapped correctly'
    );
    System.assertEquals(
      domain.jobType,
      lwcMap.get('jobType'),
      'Job type should be mapped correctly'
    );
    System.assertEquals(
      domain.experienceLevel,
      lwcMap.get('experienceLevel'),
      'Experience level should be mapped correctly'
    );
  }

  @isTest
  public static void testToLWCMapWithNullValues() {
    // Arrange
    JobApplicationDomain domain = new JobApplicationDomain();
    domain.externalId = 'null-test-456';
    domain.title = 'Test Job';
    domain.company = 'Test Company';
    domain.source = 'test';
    // Leave other fields null

    // Act
    Map<String, Object> lwcMap = domain.toLWCMap();

    // Assert
    System.assertNotEquals(
      null,
      lwcMap,
      'LWC map should be created even with null values'
    );
    System.assertEquals(
      domain.externalId,
      lwcMap.get('id'),
      'External ID should be mapped'
    );
    System.assertEquals(
      null,
      lwcMap.get('location'),
      'Null location should remain null'
    );
    System.assertEquals(
      null,
      lwcMap.get('salary'),
      'Null salary should remain null'
    );
    System.assertEquals(
      null,
      lwcMap.get('datePosted'),
      'Null date posted should remain null'
    );
  }

  /**
   * @description Test suite for Salesforce record transformation
   */
  @isTest
  public static void testToJobApplicationRecordWithCompleteData() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();
    domain.salary = '$85,000 - $95,000';

    // Act
    Job_Application__c record = domain.toJobApplicationRecord();

    // Assert
    System.assertNotEquals(
      null,
      record,
      'Job application record should be created'
    );
    System.assertEquals(
      domain.title,
      record.Position_Title__c,
      'Title should be mapped to Position_Title__c'
    );
    System.assertEquals(
      domain.company,
      record.Company_Name__c,
      'Company should be mapped to Company_Name__c'
    );
    System.assertEquals(
      domain.location,
      record.Location__c,
      'Location should be mapped correctly'
    );
    System.assertEquals(
      domain.description,
      record.Description__c,
      'Description should be mapped correctly'
    );
    System.assertEquals(
      domain.sourceUrl,
      record.URL__c,
      'Source URL should be mapped to URL__c'
    );
    System.assertEquals(
      'Interested',
      record.Status__c,
      'Default status should be Interested'
    );
    System.assertNotEquals(
      null,
      record.Salary__c,
      'Salary should be parsed and mapped'
    );
  }

  @isTest
  public static void testToJobApplicationRecordWithNullSalary() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();
    domain.salary = null;

    // Act
    Job_Application__c record = domain.toJobApplicationRecord();

    // Assert
    System.assertEquals(
      null,
      record.Salary__c,
      'Null salary should remain null in record'
    );
  }

  @isTest
  public static void testToJobApplicationRecordWithEmptySalary() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();
    domain.salary = '';

    // Act
    Job_Application__c record = domain.toJobApplicationRecord();

    // Assert
    System.assertEquals(
      null,
      record.Salary__c,
      'Empty salary should be null in record'
    );
  }

  /**
   * @description Test suite for salary parsing business logic
   */
  @isTest
  public static void testSalaryParsingWithSimpleAmount() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();
    domain.salary = '$75,000';

    // Act
    Job_Application__c record = domain.toJobApplicationRecord();

    // Assert
    System.assertEquals(
      75000,
      record.Salary__c,
      'Simple salary amount should be parsed correctly'
    );
  }

  @isTest
  public static void testSalaryParsingWithRange() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();
    domain.salary = '$80,000 - $120,000';

    // Act
    Job_Application__c record = domain.toJobApplicationRecord();

    // Assert
    System.assertEquals(
      80000,
      record.Salary__c,
      'Should parse minimum value from salary range'
    );
  }

  @isTest
  public static void testSalaryParsingWithTextDescription() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();
    domain.salary = 'Competitive salary $90,000 annually';

    // Act
    Job_Application__c record = domain.toJobApplicationRecord();

    // Assert
    System.assertEquals(
      90000,
      record.Salary__c,
      'Should extract number from descriptive salary text'
    );
  }

  @isTest
  public static void testSalaryParsingWithInvalidFormat() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();
    domain.salary = 'Negotiable salary TBD';

    // Act
    Job_Application__c record = domain.toJobApplicationRecord();

    // Assert
    System.assertEquals(
      null,
      record.Salary__c,
      'Invalid salary format should result in null'
    );
  }

  @isTest
  public static void testSalaryParsingWithEuropeanFormat() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();
    domain.salary = '€75.000 - €90.000';

    // Act
    Job_Application__c record = domain.toJobApplicationRecord();

    // Assert
    System.assertEquals(
      75000,
      record.Salary__c,
      'Should handle European number format (periods as thousands separator)'
    );
  }

  /**
   * @description Test suite for string representation and debugging
   */
  @isTest
  public static void testToStringMethod() {
    // Arrange
    JobApplicationDomain domain = new JobApplicationDomain(
      'toString-test-789',
      'QA Engineer',
      'Quality Corp',
      'indeed'
    );

    // Act
    String stringRepresentation = domain.toString();

    // Assert
    System.assertNotEquals(
      null,
      stringRepresentation,
      'toString should return a value'
    );
    System.assert(
      stringRepresentation.contains('toString-test-789'),
      'Should contain external ID'
    );
    System.assert(
      stringRepresentation.contains('QA Engineer'),
      'Should contain title'
    );
    System.assert(
      stringRepresentation.contains('Quality Corp'),
      'Should contain company'
    );
    System.assert(
      stringRepresentation.contains('indeed'),
      'Should contain source'
    );
  }

  /**
   * @description Test suite for skills collection functionality
   */
  @isTest
  public static void testSkillsInitialization() {
    // Arrange & Act
    JobApplicationDomain domain1 = new JobApplicationDomain();
    JobApplicationDomain domain2 = new JobApplicationDomain(
      'test',
      'title',
      'company',
      'source'
    );

    // Assert
    System.assertNotEquals(
      null,
      domain1.skills,
      'Default constructor should initialize skills'
    );
    System.assertNotEquals(
      null,
      domain2.skills,
      'Parameterized constructor should initialize skills'
    );
    System.assertEquals(
      0,
      domain1.skills.size(),
      'Skills should be empty initially'
    );
    System.assertEquals(
      0,
      domain2.skills.size(),
      'Skills should be empty initially'
    );
  }

  @isTest
  public static void testSkillsManipulation() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();

    // Act
    domain.skills.add('Java');
    domain.skills.add('Spring Boot');
    domain.skills.add('REST APIs');

    // Assert
    System.assertEquals(3, domain.skills.size(), 'Should have 3 skills added');
    System.assert(domain.skills.contains('Java'), 'Should contain Java skill');
    System.assert(
      domain.skills.contains('Spring Boot'),
      'Should contain Spring Boot skill'
    );
    System.assert(
      domain.skills.contains('REST APIs'),
      'Should contain REST APIs skill'
    );
  }

  /**
   * @description Test suite for edge cases and boundary conditions
   */
  @isTest
  public static void testWithExtremelyLongValues() {
    // Arrange
    String longString = 'A'.repeat(1000); // 1000 character string
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();

    // Act
    domain.title = longString;
    domain.description = longString;

    // Assert
    System.assertEquals(
      longString,
      domain.title,
      'Should handle extremely long title'
    );
    System.assertEquals(
      longString,
      domain.description,
      'Should handle extremely long description'
    );
    System.assertEquals(
      true,
      domain.isValid(),
      'Should still be valid with long strings'
    );
  }

  @isTest
  public static void testWithSpecialCharacters() {
    // Arrange
    JobApplicationDomain domain = TestDataFactory.createSampleJobDomain();
    domain.title = 'Senior C++ / .NET Developer (Remote)';
    domain.company = 'Tech & Co.';
    domain.location = 'São Paulo, BR';
    domain.salary = '£50,000-£70,000 p.a.';

    // Act
    Boolean isValid = domain.isValid();
    Map<String, Object> lwcMap = domain.toLWCMap();
    Job_Application__c record = domain.toJobApplicationRecord();

    // Assert
    System.assertEquals(
      true,
      isValid,
      'Should handle special characters in validation'
    );
    System.assertNotEquals(
      null,
      lwcMap,
      'Should handle special characters in LWC transformation'
    );
    System.assertNotEquals(
      null,
      record,
      'Should handle special characters in Salesforce transformation'
    );
  }
}
