/**
 * Service Layer: Job Search Orchestration and Business Logic
 * =========================================================
 *
 * This service implements the core business logic for coordinating job searches
 * across multiple external job boards, managing async processing, and handling
 * the complex orchestration required for reliable multi-source data integration.
 *
 * ARCHITECTURAL POSITION IN DATA FLOW:
 * ------------------------------------
 *
 * ┌─ FACADE LAYER ─────┐    ┌─ SERVICE LAYER ─────┐    ┌─ STRATEGY LAYER ───┐
 * │ JobSearchController │───>│ JobSearchService    │───>│ Job Board APIs      │
 * │                     │    │                     │    │ ∙ Indeed Strategy   │
 * │ ∙ Input validation  │    │ ∙ Business Logic    │    │ ∙ Jooble Strategy   │
 * │ ∙ User interaction  │    │ ∙ Async coordination│    │ ∙ Future integrations│
 * │ ∙ Error handling    │    │ ∙ Result aggregation│    │                     │
 * └─────────────────────┘    └─────────────────────┘    └─────────────────────┘
 *          │                           │                           │
 *          ▼                           ▼                           ▼
 *   UI Orchestration           Business Process              External Integration
 *   ∙ Request/Response         ∙ Board Selection             ∙ HTTP Communication
 *   ∙ Status Management        ∙ Async Processing            ∙ Data Transformation
 *   ∙ Data Transformation      ∙ Quality Control             ∙ Error Recovery
 *
 * SERVICE LAYER RESPONSIBILITIES:
 * ==============================
 *
 * ┌─ CORE BUSINESS LOGIC ─────────────────────────────────────────────────────┐
 * │ ✓ Job board selection strategy based on user preferences                  │
 * │ ✓ Search criteria validation and business rule enforcement               │
 * │ ✓ Async processing orchestration using Salesforce platform capabilities │
 * │ ✓ Result aggregation and deduplication across multiple sources          │
 * │ ✓ Quality control and filtering of search results                       │
 * │ ✓ Error handling and retry logic for resilient operations               │
 * └───────────────────────────────────────────────────────────────────────────┘
 *
 * ┌─ SEPARATION OF CONCERNS ──────────────────────────────────────────────────┐
 * │ ✗ User interface interactions (Facade layer responsibility)              │
 * │ ✗ External API communication details (Strategy layer responsibility)     │
 * │ ✗ Data format transformations (Domain layer responsibility)              │
 * │ ✗ Platform-specific persistence logic (Repository pattern if implemented)│
 * └───────────────────────────────────────────────────────────────────────────┘
 *
 * ASYNC PROCESSING ARCHITECTURE:
 * ==============================
 *
 * The service layer implements asynchronous processing to ensure:
 * ∙ Responsive user interface (no blocking operations)
 * ∙ Reliable execution even with external API failures
 * ∙ Scalable architecture supporting multiple concurrent searches
 * ∙ Platform governor limit compliance
 *
 * ASYNC FLOW DIAGRAM:
 * ─────────────────────
 *
 * [searchJobsAsync] ──generates──> [searchId] ──enqueues──> [JobSearchQueueable]
 *        │                             │                             │
 *        ├─> validates criteria        ├─> tracks operation         ├─> executes search
 *        ├─> determines boards         └─> returns to facade        ├─> calls strategies
 *        └─> creates queueable job                                   ├─> aggregates results
 *                                                                    └─> stores results
 *
 * BUSINESS LOGIC DECISION POINTS:
 * ==============================
 *
 * 1. BOARD SELECTION STRATEGY:
 *    ┌─ User Specified Boards ────────────────────────────────────────────────┐
 *    │ if (criteria.selectedBoards != null && !isEmpty()) {                   │
 *    │   → Validate board names against registry                              │
 *    │   → Filter out unsupported boards with warning                         │
 *    │   → Use remaining valid boards                                          │
 *    │ }                                                                       │
 *    └─────────────────────────────────────────────────────────────────────────┘
 *
 *    ┌─ Default Board Selection ──────────────────────────────────────────────┐
 *    │ else {                                                                  │
 *    │   → Use all available boards from registry                             │
 *    │   → Provides maximum coverage for user searches                        │
 *    │ }                                                                       │
 *    └─────────────────────────────────────────────────────────────────────────┘
 *
 * 2. REQUEST ID GENERATION STRATEGY:
 *    Format: "JSR-{timestamp}-{random}"
 *    ∙ JSR = Job Search Request prefix for easy identification
 *    ∙ Timestamp = yyyyMMddHHmmss for chronological sorting
 *    ∙ Random suffix = collision prevention for concurrent requests
 *
 *    Example: "JSR-20240102145230-847"
 *
 * 3. VALIDATION BUSINESS RULES:
 *    ∙ At least one of keywords OR location must be provided
 *    ∙ Prevents overly broad searches that could overwhelm APIs
 *    ∙ Ensures search intent is sufficiently specified
 *
 * ERROR HANDLING PHILOSOPHY:
 * ===========================
 *
 * The service layer implements graceful degradation:
 * ∙ Individual board failures don't prevent overall search success
 * ∙ Validation errors are caught early and reported clearly
 * ∙ Async failures are logged but don't block the user interface
 * ∙ Retry logic can be implemented at the queueable level
 *
 * PERFORMANCE CONSIDERATIONS:
 * ==========================
 *
 * ∙ MAX_RESULTS_PER_BOARD constant prevents runaway result sets
 * ∙ Async processing prevents timeout issues with slow APIs
 * ∙ Board validation happens early to avoid wasted API calls
 * ∙ Request ID generation is lightweight and collision-resistant
 *
 * EXTENSIBILITY DESIGN:
 * ====================
 *
 * The service layer is designed for future enhancements:
 * ∙ Easy to add result caching mechanisms
 * ∙ Simple to implement search result deduplication logic
 * ∙ Straightforward to add retry strategies and circuit breakers
 * ∙ Ready for search result ranking and filtering algorithms
 */
public with sharing class JobSearchService {
  private static final Integer MAX_RESULTS_PER_BOARD = 50;

  /**
   * PRIMARY ORCHESTRATOR: Async Job Search Coordination
   *
   * UPDATED ARCHITECTURE - Fan-Out Pattern Implementation:
   * ======================================================
   *
   * Phase 1: VALIDATION & PREPARATION
   *   Input: JobSearchCriteria (validated domain object)
   *     ├─> criteria.keywords: User search terms
   *     ├─> criteria.location: Geographic constraints
   *     ├─> criteria.workTypes: Employment preferences
   *     └─> criteria.selectedBoards: Job board selection
   *
   *   Validation: criteria.isValid() → ensures business rules compliance
   *     ├─> Rule: At least keywords OR location must be specified
   *     └─> Purpose: Prevents overly broad searches
   *
   * Phase 2: REQUEST TRACKING SETUP
   *   Generate searchId: generateSearchId() → "JSR-{timestamp}-{random}"
   *     ├─> Enables async operation correlation
   *     ├─> Provides user with tracking identifier
   *     └─> Supports concurrent request differentiation
   *
   * Phase 3: ORCHESTRATION INITIATION
   *   Create Orchestrator: JobSearchOrchestratorQueueable(searchId, criteria)
   *     ├─> Routes to SingleBoardSearchQueueable for 1 board
   *     ├─> Routes to CompositeBoardSearchQueueable for multiple boards
   *     └─> Implements fan-out pattern for parallel processing
   *
   * ORCHESTRATION FLOW:
   * ────────────────────
   *
   * JobSearchOrchestratorQueueable.execute():
   *   ├─> if (1 board): → SingleBoardSearchQueueable
   *   └─> if (multiple): → CompositeBoardSearchQueueable
   *                        └─> Fan-out to multiple SingleBoardSearchQueueable
   *
   * ASYNC EXECUTION BENEFITS:
   * ─────────────────────────
   * • Fan-out enables parallel processing across job boards
   * • Each board search runs in separate queueable (governor limit safety)
   * • Platform events enable real-time UI updates
   * • Failure isolation per board (one failure doesn't kill entire search)
   *
   * @param criteria Validated search parameters encapsulating user intent
   * @return String Unique search identifier for async operation tracking
   * @throws InvalidSearchCriteriaException When business validation rules fail
   */
  public static String searchJobsAsync(JobSearchCriteria criteria) {
    // Validate criteria before queuing
    if (criteria == null || !criteria.isValid()) {
      throw new InvalidSearchCriteriaException(
        'Search criteria must include keywords or location'
      );
    }

    // Generate unique search ID for tracking
    String searchId = generateSearchId();

    // Queue the orchestrator queueable
    JobSearchOrchestratorQueueable orchestrator = new JobSearchOrchestratorQueueable(
      searchId,
      criteria
    );
    ID jobId = System.enqueueJob(orchestrator);

    // TODO: Re-enable when Logger package installed
    // Logger.info('Queued orchestrator job search')
    //   .setField('SearchId__c', searchId)
    //   .setField('QueueableJobId', jobId)
    //   .setField('Criteria', criteria);
    // Logger.saveLog();

    return searchId;
  }

  /**
   * BUSINESS LOGIC: Job Board Selection Strategy
   *
   * DECISION FLOW:
   * --------------
   *
   * Input Analysis:
   *   criteria.selectedBoards evaluation:
   *     ├─> null: No user preference specified
   *     ├─> empty: User explicitly wants no boards (edge case)
   *     └─> populated: User has specific board preferences
   *
   * STRATEGY 1: USER-SPECIFIED BOARD SELECTION
   * ┌──────────────────────────────────────────────────────────────────────────┐
   * │ if (criteria.selectedBoards != null && !isEmpty()) {                    │
   * │                                                                        │
   * │   Step 1: VALIDATION PHASE                                           │
   * │   ├─> JobBoardStrategyRegistry.validateBoardNames()                │
   * │   ├─> Identifies unsupported board names                          │
   * │   └─> Logs warnings for user feedback                            │
   * │                                                                        │
   * │   Step 2: FILTERING PHASE                                            │
   * │   ├─> Iterate through user selections                            │
   * │   ├─> JobBoardStrategyRegistry.isSupported() for each board     │
   * │   └─> Build supportedBoards list with only valid entries         │
   * │                                                                        │
   * │   Result: List<String> of validated, supported board names           │
   * │   Example: ["Indeed", "Jooble"] ("UnsupportedBoard" filtered out)   │
   * │ }                                                                      │
   * └──────────────────────────────────────────────────────────────────────────┘
   *
   * STRATEGY 2: DEFAULT BOARD SELECTION
   * ┌──────────────────────────────────────────────────────────────────────────┐
   * │ else {                                                                 │
   * │   ├─> JobBoardStrategyRegistry.getAvailableBoards()              │
   * │   ├─> Returns Set<String> of all registered job boards           │
   * │   └─> Converted to List<String> for consistent return type        │
   * │                                                                        │
   * │   Business Rationale:                                                │
   * │   • Maximizes job opportunity coverage for users                    │
   * │   • Ensures no available sources are missed                        │
   * │   • Provides consistent experience regardless of UI complexity      │
   * │   • Simplifies onboarding for new users                            │
   * │ }                                                                      │
   * └──────────────────────────────────────────────────────────────────────────┘
   *
   * ERROR RESILIENCE:
   * ──────────────────
   * • Graceful handling of unsupported board names
   * • Warning logs provide visibility into configuration issues
   * • Partial board lists still allow search execution
   * • Empty result lists are handled downstream gracefully
   *
   * BUSINESS IMPACT:
   * ────────────────
   * • User Preference Respect: Honors explicit board selections
   * • Comprehensive Coverage: Defaults to all available sources
   * • Configuration Validation: Prevents runtime failures
   * • Extensible Design: Easy to add new boards without code changes
   *
   * @param criteria Search parameters including board preferences
   * @return List<String> Validated board names for strategy execution
   */
  private static List<String> determineBoardsToSearch(
    JobSearchCriteria criteria
  ) {
    if (criteria.selectedBoards != null && !criteria.selectedBoards.isEmpty()) {
      // Use user-specified boards
      List<String> unsupportedBoards = JobBoardStrategyRegistry.validateBoardNames(
        criteria.selectedBoards
      );
      if (!unsupportedBoards.isEmpty()) {
        System.debug(
          LoggingLevel.WARN,
          'Unsupported job boards requested: ' + unsupportedBoards
        );
      }

      List<String> supportedBoards = new List<String>();
      for (String board : criteria.selectedBoards) {
        if (JobBoardStrategyRegistry.isSupported(board)) {
          supportedBoards.add(board);
        }
      }
      return supportedBoards;
    } else {
      // Use all available boards
      return new List<String>(JobBoardStrategyRegistry.getAvailableBoards());
    }
  }

  /**
   * REQUEST TRACKING: Unique Identifier Generation for Async Operations
   *
   * ID GENERATION STRATEGY:
   * -----------------------
   *
   * Format Pattern: "JSR-{timestamp}-{random}"
   *   ├─> Prefix: "JSR" = Job Search Request (system identification)
   *   ├─> Timestamp: yyyyMMddHHmmss (chronological ordering)
   *   └─> Random Suffix: 000-999 (collision prevention)
   *
   * CONSTRUCTION ALGORITHM:
   * ┌─ STEP 1: TIMESTAMP GENERATION ─────────────────────────────────────────┐
   * │ DateTime.now().format('yyyyMMddHHmmss')                              │
   * │ Example: "20240102145230" = Jan 2, 2024 at 2:52:30 PM               │
   * │ Benefits:                                                            │
   * │   • Chronological sorting of request IDs                            │
   * │   • Visual timestamp for debugging and monitoring                    │
   * │   • Timezone consistency (uses system timezone)                      │
   * └───────────────────────────────────────────────────────────────────────────┘
   *
   * ┌─ STEP 2: COLLISION PREVENTION ─────────────────────────────────────────┐
   * │ Math.random() * 1000 → 0-999 range                                 │
   * │ Math.round() → integer value                                       │
   * │ String.valueOf() → string conversion                               │
   * │ .leftPad(3, '0') → zero-padded 3-digit format                     │
   * │ Example: random=347.8 → 348 → "348"                                │
   * │ Example: random=42.1 → 42 → "042"                                 │
   * └───────────────────────────────────────────────────────────────────────────┘
   *
   * EXAMPLE OUTPUTS:
   * ────────────────
   * ├─> "JSR-20240102145230-847" (Jan 2, 2024 at 2:52:30 PM, random=847)
   * ├─> "JSR-20240102145231-023" (one second later, random=023)
   * └─> "JSR-20240103090000-156" (next day, 9:00:00 AM, random=156)
   *
   * COLLISION ANALYSIS:
   * ───────────────────
   *
   * Same-Second Collision Probability:
   *   ├─> 1000 possible random values (000-999)
   *   ├─> Collision chance = 1/1000 = 0.1% per same-second request
   *   └─> Multiple concurrent users unlikely due to UI interaction timing
   *
   * Real-World Collision Scenarios:
   *   ├─> Automated testing with rapid requests
   *   ├─> High-volume production with many concurrent users
   *   └─> System clock resolution limitations
   *
   * BUSINESS VALUE:
   * ───────────────
   * • Operation Tracking: Each async job has unique identifier
   * • User Experience: Provides immediate feedback to UI
   * • Debugging Support: Enables correlation across log entries
   * • Monitoring Integration: Facilitates operations dashboards
   * • Audit Trail: Creates record of user search activities
   *
   * USAGE IN DATA FLOW:
   * ───────────────────
   * 1. Generated here in searchJobsAsync()
   * 2. Passed to JobSearchQueueable for execution tracking
   * 3. Returned to UI for status polling
   * 4. Used in getSearchStatus() for result correlation
   *
   * @return String Unique identifier following JSR-{timestamp}-{random} format
   */
  private static String generateSearchId() {
    return 'JSR-' +
      DateTime.now().format('yyyyMMddHHmmss') +
      '-' +
      String.valueOf(Math.round(Math.random() * 1000)).leftPad(3, '0');
  }

  /**
   * Custom exception for invalid search criteria.
   */
  public class InvalidSearchCriteriaException extends Exception {
  }
}