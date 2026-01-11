/**
 * @description Comprehensive test class for JobSearchCriteria.cls
 *              Tests builder pattern, validation, business rules, and parameter handling
 *              for the core search criteria domain model.
 *
 * COVERAGE TARGET: 95% (Critical Search Parameter Validation)
 *
 * TEST STRATEGY:
 * - Constructor Testing: Verify object creation with valid/invalid parameters
 * - Builder Pattern Testing: Verify fluent API construction methods
 * - Validation Testing: Ensure parameter validation and business rules
 * - Edge Case Testing: Handle null values, empty strings, invalid parameters
 * - Business Logic Testing: Field checking, toString representation
 *
 * DESIGN PATTERNS USED:
 * - Test Data Factory: Centralized test object creation
 * - Arrange-Act-Assert: Clear test structure
 * - Data-Driven Testing: Multiple parameter combinations
 */
@isTest
public class JobSearchCriteriaTest {
  /**
   * @description Test suite for JobSearchCriteria construction
   */
  @isTest
  public static void testBasicConstructor() {
    // Arrange & Act
    JobSearchCriteria criteria = new JobSearchCriteria(
      'Software Engineer',
      'Toronto',
      new List<String>{ 'full-time' }
    );

    // Assert
    System.assertNotEquals(
      null,
      criteria,
      'Constructor should create criteria object'
    );
    System.assertEquals(
      'Software Engineer',
      criteria.keywords,
      'Keywords should be set correctly'
    );
    System.assertEquals(
      'Toronto',
      criteria.location,
      'Location should be set correctly'
    );
    System.assertNotEquals(
      null,
      criteria.workTypes,
      'Work types should be initialized'
    );
    System.assertEquals(
      1,
      criteria.workTypes.size(),
      'Should have one work type'
    );
    System.assertNotEquals(
      null,
      criteria.selectedBoards,
      'Selected boards should be initialized'
    );
    System.assertEquals(
      0,
      criteria.selectedBoards.size(),
      'Should have no selected boards (search all)'
    );
  }

  @isTest
  public static void testExtendedConstructor() {
    // Arrange
    List<String> workTypes = new List<String>{ 'full-time', 'contract' };
    List<String> selectedBoards = new List<String>{ 'jooble', 'indeed' };

    // Act
    JobSearchCriteria criteria = new JobSearchCriteria(
      'Java Developer',
      'Vancouver',
      workTypes,
      selectedBoards
    );

    // Assert
    System.assertEquals(
      'Java Developer',
      criteria.keywords,
      'Keywords should be set correctly'
    );
    System.assertEquals(
      'Vancouver',
      criteria.location,
      'Location should be set correctly'
    );
    System.assertEquals(
      2,
      criteria.workTypes.size(),
      'Should have two work types'
    );
    System.assertEquals(
      2,
      criteria.selectedBoards.size(),
      'Should have two selected boards'
    );
    System.assertEquals(
      true,
      criteria.selectedBoards.contains('jooble'),
      'Should contain jooble'
    );
    System.assertEquals(
      true,
      criteria.selectedBoards.contains('indeed'),
      'Should contain indeed'
    );
  }

  @isTest
  public static void testStaticCreateMethod() {
    // Arrange & Act
    JobSearchCriteria criteria = JobSearchCriteria.create(
      'Python Developer',
      'Montreal'
    );

    // Assert
    System.assertEquals(
      'Python Developer',
      criteria.keywords,
      'Keywords should be set correctly'
    );
    System.assertEquals(
      'Montreal',
      criteria.location,
      'Location should be set correctly'
    );
    System.assertNotEquals(
      null,
      criteria.workTypes,
      'Work types should be initialized'
    );
    System.assertEquals(
      0,
      criteria.workTypes.size(),
      'Work types should be empty by default'
    );
    System.assertNotEquals(
      null,
      criteria.selectedBoards,
      'Selected boards should be initialized'
    );
    System.assertEquals(
      0,
      criteria.selectedBoards.size(),
      'Selected boards should be empty (search all)'
    );
  }

  @isTest
  public static void testConstructorWithNullWorkTypes() {
    // Arrange & Act
    JobSearchCriteria criteria = new JobSearchCriteria(
      'QA Tester',
      'Ottawa',
      null
    );

    // Assert
    System.assertNotEquals(
      null,
      criteria.workTypes,
      'Work types should be initialized even when null passed'
    );
    System.assertEquals(
      0,
      criteria.workTypes.size(),
      'Work types should be empty list when null passed'
    );
  }

  @isTest
  public static void testConstructorWithNullSelectedBoards() {
    // Arrange & Act
    JobSearchCriteria criteria = new JobSearchCriteria(
      'DevOps Engineer',
      'Calgary',
      new List<String>{ 'full-time' },
      null
    );

    // Assert
    System.assertNotEquals(
      null,
      criteria.selectedBoards,
      'Selected boards should be initialized even when null passed'
    );
    System.assertEquals(
      0,
      criteria.selectedBoards.size(),
      'Selected boards should be empty list when null passed'
    );
  }

  /**
   * @description Test suite for builder pattern implementation
   */
  @isTest
  public static void testWithJobBoardsMethod() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create(
      'Full Stack Developer',
      'Edmonton'
    );
    List<String> jobBoards = new List<String>{ 'linkedin', 'jooble' };

    // Act
    JobSearchCriteria result = criteria.withJobBoards(jobBoards);

    // Assert
    System.assertEquals(
      criteria,
      result,
      'Should return same instance for chaining'
    );
    System.assertEquals(
      2,
      criteria.selectedBoards.size(),
      'Should have two selected boards'
    );
    System.assertEquals(
      true,
      criteria.selectedBoards.contains('linkedin'),
      'Should contain linkedin'
    );
    System.assertEquals(
      true,
      criteria.selectedBoards.contains('jooble'),
      'Should contain jooble'
    );
  }

  @isTest
  public static void testWithJobBoardsNullHandling() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create(
      'Data Scientist',
      'Winnipeg'
    );

    // Act
    JobSearchCriteria result = criteria.withJobBoards(null);

    // Assert
    System.assertEquals(
      criteria,
      result,
      'Should return same instance for chaining'
    );
    System.assertNotEquals(
      null,
      criteria.selectedBoards,
      'Selected boards should not be null'
    );
    System.assertEquals(
      0,
      criteria.selectedBoards.size(),
      'Selected boards should be empty when null passed'
    );
  }

  @isTest
  public static void testWithWorkTypesMethod() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create(
      'Backend Developer',
      'Halifax'
    );
    List<String> workTypes = new List<String>{
      'full-time',
      'part-time',
      'contract'
    };

    // Act
    JobSearchCriteria result = criteria.withWorkTypes(workTypes);

    // Assert
    System.assertEquals(
      criteria,
      result,
      'Should return same instance for chaining'
    );
    System.assertEquals(
      3,
      criteria.workTypes.size(),
      'Should have three work types'
    );
    System.assertEquals(
      true,
      criteria.workTypes.contains('full-time'),
      'Should contain full-time'
    );
    System.assertEquals(
      true,
      criteria.workTypes.contains('part-time'),
      'Should contain part-time'
    );
    System.assertEquals(
      true,
      criteria.workTypes.contains('contract'),
      'Should contain contract'
    );
  }

  @isTest
  public static void testWithWorkTypesNullHandling() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create(
      'Frontend Developer',
      'Victoria'
    );

    // Act
    JobSearchCriteria result = criteria.withWorkTypes(null);

    // Assert
    System.assertEquals(
      criteria,
      result,
      'Should return same instance for chaining'
    );
    System.assertNotEquals(
      null,
      criteria.workTypes,
      'Work types should not be null'
    );
    System.assertEquals(
      0,
      criteria.workTypes.size(),
      'Work types should be empty when null passed'
    );
  }

  @isTest
  public static void testBuilderChaining() {
    // Arrange & Act
    JobSearchCriteria criteria = JobSearchCriteria.create(
        'Mobile Developer',
        'Saskatoon'
      )
      .withWorkTypes(new List<String>{ 'remote', 'hybrid' })
      .withJobBoards(new List<String>{ 'indeed', 'linkedin', 'jooble' });

    // Assert
    System.assertEquals(
      'Mobile Developer',
      criteria.keywords,
      'Keywords should be set'
    );
    System.assertEquals(
      'Saskatoon',
      criteria.location,
      'Location should be set'
    );
    System.assertEquals(
      2,
      criteria.workTypes.size(),
      'Should have two work types'
    );
    System.assertEquals(
      3,
      criteria.selectedBoards.size(),
      'Should have three selected boards'
    );
  }

  /**
   * @description Test suite for validation business rules
   */
  @isTest
  public static void testIsValidWithValidCriteria() {
    // Arrange
    JobSearchCriteria criteria = TestDataFactory.createValidCriteria();

    // Act
    Boolean isValid = criteria.isValid();

    // Assert
    System.assertEquals(true, isValid, 'Valid criteria should pass validation');
  }

  @isTest
  public static void testIsValidWithOnlyKeywords() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create(
      'Software Engineer',
      ''
    );

    // Act
    Boolean isValid = criteria.isValid();

    // Assert
    System.assertEquals(
      true,
      isValid,
      'Criteria with only keywords should be valid'
    );
  }

  @isTest
  public static void testIsValidWithOnlyLocation() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create('', 'Toronto');

    // Act
    Boolean isValid = criteria.isValid();

    // Assert
    System.assertEquals(
      true,
      isValid,
      'Criteria with only location should be valid'
    );
  }

  @isTest
  public static void testIsValidWithBothEmpty() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create('', '');

    // Act
    Boolean isValid = criteria.isValid();

    // Assert
    System.assertEquals(
      false,
      isValid,
      'Criteria with both keywords and location empty should be invalid'
    );
  }

  @isTest
  public static void testIsValidWithNullValues() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create(null, null);

    // Act
    Boolean isValid = criteria.isValid();

    // Assert
    System.assertEquals(
      false,
      isValid,
      'Criteria with null keywords and location should be invalid'
    );
  }

  @isTest
  public static void testIsValidWithWhitespaceOnly() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create('   ', '   ');

    // Act
    Boolean isValid = criteria.isValid();

    // Assert
    System.assertEquals(
      false,
      isValid,
      'Criteria with whitespace-only values should be invalid'
    );
  }

  /**
   * @description Test suite for hasField functionality
   */
  @isTest
  public static void testHasFieldKeywords() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create('Java Developer', '');

    // Act & Assert
    System.assertEquals(
      true,
      criteria.hasField('keywords'),
      'Should have keywords field'
    );
    System.assertEquals(
      true,
      criteria.hasField('KEYWORDS'),
      'Should be case-insensitive'
    );
    System.assertEquals(
      false,
      criteria.hasField('location'),
      'Should not have location field'
    );
  }

  @isTest
  public static void testHasFieldLocation() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create('', 'Vancouver');

    // Act & Assert
    System.assertEquals(
      false,
      criteria.hasField('keywords'),
      'Should not have keywords field'
    );
    System.assertEquals(
      true,
      criteria.hasField('location'),
      'Should have location field'
    );
    System.assertEquals(
      true,
      criteria.hasField('LOCATION'),
      'Should be case-insensitive'
    );
  }

  @isTest
  public static void testHasFieldWorkTypes() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create(
        'Developer',
        'Toronto'
      )
      .withWorkTypes(new List<String>{ 'remote' });

    // Act & Assert
    System.assertEquals(
      true,
      criteria.hasField('worktypes'),
      'Should have worktypes field'
    );
    System.assertEquals(
      true,
      criteria.hasField('WORKTYPES'),
      'Should be case-insensitive'
    );
  }

  @isTest
  public static void testHasFieldOptionalFields() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create(
      'Engineer',
      'Montreal'
    );
    criteria.salaryMin = '50000';
    criteria.salaryMax = '80000';
    criteria.experienceLevel = 'Senior';

    // Act & Assert
    System.assertEquals(
      true,
      criteria.hasField('salarymin'),
      'Should have salarymin field'
    );
    System.assertEquals(
      true,
      criteria.hasField('salarymax'),
      'Should have salarymax field'
    );
    System.assertEquals(
      true,
      criteria.hasField('experiencelevel'),
      'Should have experiencelevel field'
    );
  }

  @isTest
  public static void testHasFieldEmptyOptionalFields() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create(
      'Engineer',
      'Montreal'
    );

    // Act & Assert
    System.assertEquals(
      false,
      criteria.hasField('salarymin'),
      'Should not have empty salarymin field'
    );
    System.assertEquals(
      false,
      criteria.hasField('salarymax'),
      'Should not have empty salarymax field'
    );
    System.assertEquals(
      false,
      criteria.hasField('experiencelevel'),
      'Should not have empty experiencelevel field'
    );
  }

  @isTest
  public static void testHasFieldInvalidFieldName() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create(
      'Developer',
      'Calgary'
    );

    // Act & Assert
    System.assertEquals(
      false,
      criteria.hasField('invalidfield'),
      'Should return false for invalid field names'
    );
    System.assertEquals(
      false,
      criteria.hasField(''),
      'Should return false for empty field name'
    );
  }

  /**
   * @description Test suite for toString and debugging functionality
   */
  @isTest
  public static void testToStringMethod() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create(
        'Backend Developer',
        'Ottawa'
      )
      .withWorkTypes(new List<String>{ 'full-time' })
      .withJobBoards(new List<String>{ 'jooble', 'indeed' });

    // Act
    String stringRepresentation = criteria.toString();

    // Assert
    System.assertNotEquals(
      null,
      stringRepresentation,
      'toString should return a value'
    );
    System.assert(
      stringRepresentation.contains('Backend Developer'),
      'Should contain keywords'
    );
    System.assert(
      stringRepresentation.contains('Ottawa'),
      'Should contain location'
    );
    System.assert(
      stringRepresentation.contains('full-time'),
      'Should contain work types'
    );
    System.assert(
      stringRepresentation.contains('jooble'),
      'Should contain selected boards'
    );
    System.assert(
      stringRepresentation.contains('indeed'),
      'Should contain selected boards'
    );
  }

  @isTest
  public static void testToStringWithNullValues() {
    // Arrange
    JobSearchCriteria criteria = JobSearchCriteria.create(
      'Mobile Developer',
      null
    );

    // Act
    String stringRepresentation = criteria.toString();

    // Assert
    System.assertNotEquals(
      null,
      stringRepresentation,
      'toString should handle null values gracefully'
    );
    System.assert(
      stringRepresentation.contains('Mobile Developer'),
      'Should contain keywords'
    );
  }

  /**
   * @description Test suite for edge cases and boundary conditions
   */
  @isTest
  public static void testSpecialCharactersInKeywords() {
    // Arrange & Act
    JobSearchCriteria criteria = JobSearchCriteria.create(
      'C++ / C# Developer (Senior)',
      'Toronto'
    );

    // Assert
    System.assertEquals(
      true,
      criteria.isValid(),
      'Special characters in keywords should be handled'
    );
    System.assertEquals(
      'C++ / C# Developer (Senior)',
      criteria.keywords,
      'Special characters should be preserved'
    );
  }

  @isTest
  public static void testUnicodeCharactersInLocation() {
    // Arrange & Act
    JobSearchCriteria criteria = JobSearchCriteria.create(
      'Software Engineer',
      'Montréal, Québec'
    );

    // Assert
    System.assertEquals(
      true,
      criteria.isValid(),
      'Unicode characters in location should be handled'
    );
    System.assertEquals(
      'Montréal, Québec',
      criteria.location,
      'Unicode characters should be preserved'
    );
  }

  @isTest
  public static void testLongStringValues() {
    // Arrange
    String longKeywords = 'Senior Full Stack Software Engineer with expertise in Java Spring Boot React Node.js'
      .repeat(5);
    String longLocation = 'Downtown Toronto Financial District Ontario Canada'
      .repeat(3);

    // Act
    JobSearchCriteria criteria = JobSearchCriteria.create(
      longKeywords,
      longLocation
    );

    // Assert
    System.assertEquals(
      true,
      criteria.isValid(),
      'Should handle long string values'
    );
    System.assertEquals(
      longKeywords,
      criteria.keywords,
      'Long keywords should be preserved'
    );
    System.assertEquals(
      longLocation,
      criteria.location,
      'Long location should be preserved'
    );
  }

  @isTest
  public static void testFactoryMethodIntegration() {
    // Arrange & Act - Test various factory methods from TestDataFactory
    JobSearchCriteria validCriteria = TestDataFactory.createValidCriteria();
    JobSearchCriteria allBoardsCriteria = TestDataFactory.createCriteriaForAllBoards();
    JobSearchCriteria invalidCriteria = TestDataFactory.createInvalidCriteria();

    // Assert
    System.assertEquals(
      true,
      validCriteria.isValid(),
      'Factory valid criteria should be valid'
    );
    System.assertEquals(
      true,
      allBoardsCriteria.isValid(),
      'Factory all boards criteria should be valid'
    );
    System.assertEquals(
      false,
      invalidCriteria.isValid(),
      'Factory invalid criteria should be invalid'
    );
  }
}
