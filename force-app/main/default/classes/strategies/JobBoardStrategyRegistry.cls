/**
 * Strategy Registry: Job Board Integration Management
 * ==================================================
 *
 * This registry implements the Strategy pattern to provide centralized management
 * and discovery of available job board integrations, enabling dynamic strategy
 * selection and extensible architecture for adding new job boards.
 *
 * ROLE IN DATA FLOW ARCHITECTURE:
 * ===============================
 *
 * The registry serves as the central coordination point for strategy instantiation:
 *
 * ┌─ SERVICE LAYER ─────┐    ┌─ REGISTRY ──────────┐    ┌─ STRATEGY LAYER ────┐
 * │ JobSearchService    │───>│ JobBoardStrategy    │───>│ IJobBoardSearch     │
 * │                     │    │ Registry            │    │ Strategy            │
 * │ ∙ Board selection   │    │                     │    │                     │
 * │ ∙ Strategy request  │    │ ∙ Strategy factory  │    │ ∙ API integration   │
 * │ ∙ Validation logic  │    │ ∙ Board discovery   │    │ ∙ Data transformation│
 * └─────────────────────┘    │ ∙ Validation support│    │ ∙ Error handling    │
 *                            └─────────────────────┘    └─────────────────────┘
 *                                      │                           │
 *                                      ▼                           ▼
 *                              Board Management                API Execution
 *                              ∙ Registration                 ∙ HTTP requests
 *                              ∙ Discovery                    ∙ Response parsing
 *                              ∙ Validation                   ∙ Domain mapping
 *
 * STRATEGY PATTERN IMPLEMENTATION:
 * ===============================
 *
 * Registry Design Principles:
 * ∙ Centralized strategy registration and discovery
 * ∙ Type-safe strategy instantiation using Apex reflection
 * ∙ Runtime validation of strategy availability
 * ∙ Extensible architecture for adding new job boards
 *
 * SEPARATION OF CONCERNS:
 * ======================
 *
 * ┌─ REGISTRY RESPONSIBILITIES ────────────────────────────────────────────────┐
 * │ ✓ Strategy type registration and mapping                                   │
 * │ ✓ Dynamic strategy instantiation using reflection                          │
 * │ ✓ Board availability discovery and validation                              │
 * │ ✓ Error handling for missing or invalid strategies                         │
 * │ ✓ Extensibility support for new job board integrations                     │
 * └─────────────────────────────────────────────────────────────────────────────┘
 *
 * ┌─ NOT REGISTRY RESPONSIBILITIES ────────────────────────────────────────────┐
 * │ ✗ Business logic for board selection (Service layer responsibility)       │
 * │ ✗ External API communication (Strategy implementation responsibility)      │
 * │ ✗ Data transformation and normalization (Domain layer responsibility)     │
 * │ ✗ User interface interactions (Facade layer responsibility)               │
 * └─────────────────────────────────────────────────────────────────────────────┘
 *
 * EXTENSIBILITY DESIGN:
 * ====================
 *
 * Adding new job boards requires minimal code changes:
 *
 * 1. Implement IJobBoardSearchStrategy interface
 * 2. Add strategy class to STRATEGY_REGISTRY map
 * 3. Registry automatically discovers and manages new strategy
 * 4. No changes required in service or facade layers
 *
 * Example extension:
 * ```apex
 * private static final Map<String, Type> STRATEGY_REGISTRY = new Map<String, Type>{
 *     'Jooble' => JoobleStrategy.class,
 *     'Indeed' => IndeedStrategy.class,
 *     'LinkedIn' => LinkedInStrategy.class,  // <- New addition
 *     'Monster' => MonsterStrategy.class     // <- Another new board
 * };
 * ```
 */
public with sharing class JobBoardStrategyRegistry {
  private static final Map<String, Type> STRATEGY_REGISTRY = new Map<String, Type>{
    'Jooble' => JoobleStrategy.class,
    'Indeed' => IndeedStrategy.class
  };

  private static final Set<String> AVAILABLE_BOARDS = STRATEGY_REGISTRY.keySet();

  /**
   * Returns all available job board names.
   */
  public static Set<String> getAvailableBoards() {
    return AVAILABLE_BOARDS.clone();
  }

  /**
   * Checks if a job board is supported.
   */
  public static Boolean isSupported(String boardName) {
    return STRATEGY_REGISTRY.containsKey(boardName);
  }

  /**
   * Creates an instance of the strategy for the specified job board.
   */
  public static IJobBoardSearchStrategy createStrategy(String boardName) {
    if (!isSupported(boardName)) {
      throw new UnsupportedJobBoardException(
        'Job board not supported: ' + boardName
      );
    }

    try {
      Type strategyType = STRATEGY_REGISTRY.get(boardName);
      return (IJobBoardSearchStrategy) strategyType.newInstance();
    } catch (Exception e) {
      throw new StrategyCreationException(
        'Failed to create strategy for ' + boardName + ': ' + e.getMessage(),
        e
      );
    }
  }

  /**
   * Creates strategies for multiple job boards.
   */
  public static List<IJobBoardSearchStrategy> createStrategies(
    List<String> boardNames
  ) {
    List<IJobBoardSearchStrategy> strategies = new List<IJobBoardSearchStrategy>();

    for (String boardName : boardNames) {
      try {
        strategies.add(createStrategy(boardName));
      } catch (Exception e) {
        // Log error but continue with other boards
        System.debug(
          LoggingLevel.WARN,
          'Failed to create strategy for ' + boardName + ': ' + e.getMessage()
        );
      }
    }

    return strategies;
  }

  /**
   * Creates strategies for all supported job boards.
   */
  public static List<IJobBoardSearchStrategy> createAllStrategies() {
    return createStrategies(new List<String>(AVAILABLE_BOARDS));
  }

  /**
   * Validates that all requested job boards are supported.
   */
  public static List<String> validateBoardNames(List<String> boardNames) {
    List<String> unsupportedBoards = new List<String>();

    for (String boardName : boardNames) {
      if (!isSupported(boardName)) {
        unsupportedBoards.add(boardName);
      }
    }

    return unsupportedBoards;
  }

  /**
   * Custom exception for unsupported job boards.
   */
  public class UnsupportedJobBoardException extends Exception {
  }

  /**
   * Custom exception for strategy creation failures.
   */
  public class StrategyCreationException extends Exception {
  }
}
