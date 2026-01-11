/**
 * Domain Model: Unified Job Posting Representation
 * ================================================
 *
 * This class implements the Domain-Driven Design pattern to provide a unified,
 * normalized representation of job postings from multiple external sources.
 *
 * ARCHITECTURAL ROLE IN DATA FLOW:
 * -------------------------------
 *
 * ┌─ EXTERNAL APIs ──────┐     ┌─ DOMAIN LAYER ──────┐     ┌─ SALESFORCE ─────┐
 * │ Indeed API Response  │────>│                     │────>│ Job_Application  │
 * │ Jooble API Response  │────>│ JobApplicationDomain│────>│ Custom Object    │
 * │ Future APIs...       │────>│                     │────>│ Standard Fields  │
 * └──────────────────────┘     └─────────────────────┘     └──────────────────┘
 *          │                              │                           │
 *          ▼                              ▼                           ▼
 *    Different Formats            Unified Format              Salesforce Format
 *    ∙ Varying field names        ∙ Consistent properties     ∙ Custom field APIs
 *    ∙ Different data types       ∙ Validated business rules  ∙ Standard data types
 *    ∙ API-specific structures    ∙ Clean object model        ∙ Platform constraints
 *
 * DATA NORMALIZATION STRATEGY:
 * ---------------------------
 *
 * Problem: Each job board API returns data in different formats:
 *
 * Indeed API:                  Jooble API:                  Target Domain:
 * {                            {                            {
 *   "jobkey": "abc123",          "id": "job_456",             "externalId": "abc123",
 *   "jobtitle": "Developer",     "title": "Developer",        "title": "Developer",
 *   "company": "TechCorp",       "company": "TechCorp",       "company": "TechCorp",
 *   "formattedLocation": "NYC",  "location": "New York",      "location": "NYC",
 *   "snippet": "Job desc...",    "snippet": "Job desc...",    "description": "Job desc...",
 *   "salary": "$80,000",         "salary": "80000",           "salary": "$80,000",
 *   "url": "indeed.com/...",     "link": "jooble.com/...",    "sourceUrl": "indeed.com/...",
 *   ...                          ...                          "source": "Indeed"
 * }                            }                            }
 *
 * Solution: JobApplicationDomain provides consistent property names and data types
 */
public with sharing class JobApplicationDomain {
  // CORE JOB INFORMATION
  // ====================
  // Primary identification and basic job posting details

  /** External system identifier - enables correlation with source job board */
  public String externalId { get; set; }

  /** Job position title - primary display name for users */
  public String title { get; set; }

  /** Employer organization name - company identification */
  public String company { get; set; }

  /** Geographic location - can be city, state, country, or "Remote" */
  public String location { get; set; }

  /** Full job description - detailed requirements and responsibilities */
  public String description { get; set; }

  /** Compensation information - formatted salary range or amount */
  public String salary { get; set; }

  /** Work arrangement - remote, hybrid, onsite, flexible, etc. */
  public String workType { get; set; }

  /** Source job board attribution - 'Indeed', 'Jooble', etc. */
  public String source { get; set; }

  /** Original posting URL - link back to source for full details */
  public String sourceUrl { get; set; }

  // ADDITIONAL METADATA
  // ==================
  // Extended information for enhanced job matching and filtering

  /** When job was originally posted - temporal relevance indicator */
  public DateTime datePosted { get; set; }

  /** Employment classification - full-time, part-time, contract, intern */
  public String jobType { get; set; }

  /** Seniority level - entry, mid, senior, executive, etc. */
  public String experienceLevel { get; set; }

  /** Required/preferred skill tags - searchable competency list */
  public List<String> skills { get; set; }

  /**
   * Default constructor for flexible object creation
   */
  public JobApplicationDomain() {
    this.skills = new List<String>();
  }

  /**
   * Constructor with essential fields to reduce parameter count
   */
  public JobApplicationDomain(
    String externalId,
    String title,
    String company,
    String source
  ) {
    this();
    this.externalId = externalId;
    this.title = title;
    this.company = company;
    this.source = source;
  }

  /**
   * TRANSFORMATION: Domain Object → Lightning Web Component Format
   * Converts internal domain representation to UI-consumable format
   */
  public Map<String, Object> toLWCMap() {
    Map<String, Object> result = new Map<String, Object>();
    result.put('id', externalId);
    result.put('title', title);
    result.put('company', company);
    result.put('location', location);
    result.put('salary', salary);
    result.put('workType', workType);
    result.put('source', source);
    result.put('description', description);
    result.put('sourceUrl', sourceUrl);
    result.put('datePosted', datePosted);
    result.put('jobType', jobType);
    result.put('experienceLevel', experienceLevel);
    return result;
  }

  /**
   * VALIDATION: Business Rule Enforcement
   * Ensures domain objects meet business requirements before propagation
   */
  public Boolean isValid() {
    return String.isNotBlank(externalId) &&
      String.isNotBlank(title) &&
      String.isNotBlank(company) &&
      String.isNotBlank(source);
  }

  /**
   * TRANSFORMATION: Domain Object → Salesforce Persistence Layer
   * Converts domain representation to Salesforce custom object format
   */
  public Job_Application__c toJobApplicationRecord() {
    Job_Application__c jobApp = new Job_Application__c();
    jobApp.Position_Title__c = title;
    jobApp.Company_Name__c = company;
    jobApp.Location__c = location;
    jobApp.Description__c = description;

    // Handle salary conversion from string to number
    if (String.isNotBlank(salary)) {
      jobApp.Salary__c = parseSalaryToNumber(salary);
    }

    jobApp.URL__c = sourceUrl;
    jobApp.Status__c = 'Interested'; // Default status
    return jobApp;
  }

  /**
   * HELPER METHOD: Parse salary string to number
   * Extracts the first number found in salary strings like "$95,000 - $120,000"
   */
  private Decimal parseSalaryToNumber(String salaryString) {
    if (String.isBlank(salaryString)) {
      return null;
    }

    // Remove common currency symbols and spaces
    String cleanSalary = salaryString.replaceAll('[€$£¥\\s]', '');

    // Handle European format (periods as thousands separator)
    // Convert "75.000" to "75000" and "75.000,50" to "75000.50"
    if (cleanSalary.contains('.') && cleanSalary.contains(',')) {
      // Format like "75.000,50" - period is thousands, comma is decimal
      cleanSalary = cleanSalary.replace('.', '').replace(',', '.');
    } else if (
      cleanSalary.contains('.') &&
      cleanSalary.indexOf('.') < cleanSalary.length() - 3
    ) {
      // Format like "75.000" - period is thousands separator
      cleanSalary = cleanSalary.replace('.', '');
    }

    // Extract the first number (minimum salary from range or single value)
    // Look for patterns like "80,000", "80000", "90,000 annually"
    Pattern numberPattern = Pattern.compile('([0-9,]{3,})(?:[^0-9]|$)');
    Matcher matcher = numberPattern.matcher(cleanSalary);

    if (matcher.find()) {
      String numberStr = matcher.group(1);
      // Remove commas (thousands separators in US format)
      numberStr = numberStr.replace(',', '');
      try {
        return Decimal.valueOf(numberStr);
      } catch (Exception e) {
        System.debug('Unable to parse salary: ' + salaryString);
        return null;
      }
    }

    return null;
  }

  /**
   * DEBUG REPRESENTATION: Logging and Troubleshooting Support
   * Provides human-readable representation for system monitoring
   */
  public override String toString() {
    return String.format(
      'JobApplicationDomain[id={0}, title={1}, company={2}, source={3}]',
      new List<Object>{ externalId, title, company, source }
    );
  }
}
