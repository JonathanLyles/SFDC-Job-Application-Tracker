/**
 * @description Service for tracking composite job search progress and coordinating
 *              fan-in completion when multiple job boards finish processing.
 *              Manages state aggregation and final platform event publication.
 * @author Jonathan Lyles
 * @date 2026-01-03
 */
public class JobSearchTrackingService {
    
    // Custom metadata for tracking search state (alternative to custom objects)
    private static Map<String, CompositeSearchState> searchStateMap = new Map<String, CompositeSearchState>();
    
    /**
     * @description Initialize tracking for a composite search with multiple boards
     * @param searchId Unique identifier for the search operation
     * @param jobBoards List of job board names being searched
     */
    public static void initializeCompositeSearch(String searchId, List<String> jobBoards) {
        Logger.info('JobSearchTrackingService.initializeCompositeSearch() starting')
            .setField('SearchId__c', searchId)
            .setField('JobBoards', jobBoards);
        
        CompositeSearchState state = new CompositeSearchState();
        state.searchId = searchId;
        state.totalBoards = jobBoards.size();
        state.completedBoards = new Set<String>();
        state.boardResults = new Map<String, BoardResult>();
        state.startTime = DateTime.now();
        
        // Initialize each board as pending
        for (String board : jobBoards) {
            BoardResult result = new BoardResult();
            result.boardName = board;
            result.status = 'PENDING';
            result.completedTime = null;
            result.resultCount = 0;
            result.errorMessage = null;
            
            state.boardResults.put(board, result);
        }
        
        searchStateMap.put(searchId, state);
        Logger.info('Composite search tracking initialized')
            .setField('SearchId__c', searchId)
            .setField('TotalBoards', jobBoards.size());
        Logger.saveLog();
    }
    
    /**
     * @description Notify service that a job board has completed processing
     * @param searchId Unique identifier for the search operation
     * @param jobBoard Name of the completed job board
     * @param status SUCCESS, PARTIAL_SUCCESS, or FAILURE
     * @param resultCount Number of results found by this board
     * @param errorMessage Error details if applicable
     */
    public static void notifyBoardCompletion(String searchId, String jobBoard, String status, Integer resultCount, String errorMessage) {
        Logger.info('JobSearchTrackingService.notifyBoardCompletion() called')
            .setField('SearchId__c', searchId)
            .setField('JobBoard', jobBoard)
            .setField('Status', status);
        
        CompositeSearchState state = searchStateMap.get(searchId);
        if (state == null) {
            Logger.error('JobSearchTrackingService.notifyBoardCompletion() - No state found')
                .setField('SearchId__c', searchId)
                .setField('JobBoard', jobBoard);
            Logger.saveLog();
            return;
        }
        
        // Update board result
        BoardResult boardResult = state.boardResults.get(jobBoard);
        if (boardResult != null) {
            boardResult.status = status;
            boardResult.resultCount = resultCount != null ? resultCount : 0;
            boardResult.errorMessage = errorMessage;
            boardResult.completedTime = DateTime.now();
            
            state.completedBoards.add(jobBoard);
        }
        
        // Check if all boards have completed (fan-in complete)
        if (state.completedBoards.size() >= state.totalBoards) {
            Logger.info('Fan-in complete - all job boards finished')
                .setField('SearchId__c', searchId)
                .setField('CompletedBoards', state.completedBoards.size())
                .setField('TotalBoards', state.totalBoards);
            finalizeCompositeSearch(state);
        } else {
            System.debug('JobSearchTrackingService.notifyBoardCompletion() - ' + state.completedBoards.size() + '/' + state.totalBoards + ' boards completed');
        }
    }
    
    /**
     * @description Finalize composite search and publish completion event
     * @param state Complete search state with all board results
     */
    private static void finalizeCompositeSearch(CompositeSearchState state) {
        Logger.info('JobSearchTrackingService.finalizeCompositeSearch() starting')
            .setField('SearchId__c', state.searchId);
        
        // Aggregate results
        String overallStatus = determineOverallStatus(state.boardResults.values());
        Integer totalResults = 0;
        List<String> processedBoards = new List<String>();
        List<String> errorMessages = new List<String>();
        
        for (BoardResult result : state.boardResults.values()) {
            processedBoards.add(result.boardName);
            totalResults += result.resultCount;
            
            if (String.isNotBlank(result.errorMessage)) {
                errorMessages.add(result.boardName + ': ' + result.errorMessage);
            }
        }
        
        // Publish final completion event
        JobSearchCompleted__e completionEvent = new JobSearchCompleted__e(
            SearchId__c = state.searchId,
            Status__c = overallStatus,
            JobBoardsProcessed__c = String.join(processedBoards, ','),
            TotalResults__c = totalResults,
            ErrorMessage__c = errorMessages.isEmpty() ? null : String.join(errorMessages, '; ')
        );
        
        EventBus.publish(completionEvent);
        
        // Clean up state
        searchStateMap.remove(state.searchId);
        
        Logger.info('Composite search finalized and completion event published')
            .setField('SearchId__c', state.searchId)
            .setField('OverallStatus', overallStatus)
            .setField('TotalResults', totalResults);
        Logger.saveLog();
    }
    
    /**
     * @description Determine overall status based on individual board results
     * @param boardResults Collection of individual board completion results
     * @return String Overall status (SUCCESS, PARTIAL_SUCCESS, or FAILURE)
     */
    private static String determineOverallStatus(List<BoardResult> boardResults) {
        Integer successCount = 0;
        Integer failureCount = 0;
        
        for (BoardResult result : boardResults) {
            if (result.status == 'SUCCESS') {
                successCount++;
            } else if (result.status == 'FAILURE') {
                failureCount++;
            } else if (result.status == 'PARTIAL_SUCCESS') {
                successCount++; // Treat partial success as success for overall calculation
            }
        }
        
        if (successCount == boardResults.size()) {
            return 'SUCCESS';
        } else if (successCount > 0) {
            return 'PARTIAL_SUCCESS';
        } else {
            return 'FAILURE';
        }
    }
    
    /**
     * @description Get current tracking state for a search (useful for monitoring/debugging)
     * @param searchId Unique identifier for the search operation
     * @return CompositeSearchState Current state or null if not found
     */
    @TestVisible
    public static CompositeSearchState getSearchState(String searchId) {
        return searchStateMap.get(searchId);
    }
    
    /**
     * @description Clear all tracking state (useful for testing)
     */
    @TestVisible
    public static void clearAllState() {
        searchStateMap.clear();
    }
    
    /**
     * @description Inner class to hold composite search state
     */
    public class CompositeSearchState {
        public String searchId;
        public Integer totalBoards;
        public Set<String> completedBoards;
        public Map<String, BoardResult> boardResults;
        public DateTime startTime;
    }
    
    /**
     * @description Inner class to hold individual board result
     */
    public class BoardResult {
        public String boardName;
        public String status; // PENDING, SUCCESS, PARTIAL_SUCCESS, FAILURE
        public Integer resultCount;
        public String errorMessage;
        public DateTime completedTime;
    }
}