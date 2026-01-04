/**
 * @description Helper class for creating and managing tasks related to Job Applications.
 *              Provides bulk-safe task creation logic based on application status
 *              and business rules. Separates task creation concerns from trigger handler.
 * @author Jonathan Lyles
 * @date 2026-01-03
 */
public class JobApplicationTaskHelper {
  // Constants for task creation
  private static final String FOLLOW_UP_SUBJECT = 'Follow up on job application';
  private static final String INTERVIEW_PREP_SUBJECT = 'Prepare for interview';
  private static final String APPLICATION_REVIEW_SUBJECT = 'Review application materials';
  private static final String THANK_YOU_SUBJECT = 'Send thank you note';

  /**
   * @description Creates initial follow-up tasks for new job applications
   * @param newApplications List of newly created Job_Application__c records
   */
  public static void createFollowUpTasks(
    List<Job_Application__c> newApplications
  ) {
    List<Task> tasksToInsert = new List<Task>();

    for (Job_Application__c app : newApplications) {
      // Create follow-up task for all new applications
      Task followUpTask = createTask(
        FOLLOW_UP_SUBJECT,
        'Follow up on application status in 1-2 weeks',
        app.Id,
        Date.today().addDays(10), // Follow up in 10 days
        'Not Started',
        'Normal'
      );
      tasksToInsert.add(followUpTask);

      // Create review task for applications that need preparation
      if (isApplicationNeedingReview(app)) {
        Task reviewTask = createTask(
          APPLICATION_REVIEW_SUBJECT,
          'Review and improve application materials for this position',
          app.Id,
          Date.today().addDays(3), // Review in 3 days
          'Not Started',
          'Normal'
        );
        tasksToInsert.add(reviewTask);
      }
    }

    if (!tasksToInsert.isEmpty()) {
      insert tasksToInsert;
      System.debug(
        'JobApplicationTaskHelper.createFollowUpTasks() - created ' +
          tasksToInsert.size() +
          ' tasks'
      );
    }
  }

  /**
   * @description Handles task creation when application status changes
   * @param updatedApplications List of updated Job_Application__c records
   * @param oldApplicationMap Map of old values before update
   */
  public static void handleStatusChanges(
    List<Job_Application__c> updatedApplications,
    Map<Id, Job_Application__c> oldApplicationMap
  ) {
    List<Task> tasksToInsert = new List<Task>();

    for (Job_Application__c app : updatedApplications) {
      Job_Application__c oldApp = oldApplicationMap.get(app.Id);

      // Check if status changed
      if (app.Status__c != oldApp.Status__c) {
        // Handle interview scheduled
        if (
          app.Status__c == 'Interview Scheduled' &&
          oldApp.Status__c != 'Interview Scheduled'
        ) {
          Task prepTask = createTask(
            INTERVIEW_PREP_SUBJECT,
            'Research company, prepare answers, plan questions to ask',
            app.Id,
            Date.today().addDays(3), // Prepare 3 days before
            'Not Started',
            'High'
          );
          tasksToInsert.add(prepTask);
        }

        // Handle post-interview
        if (
          app.Status__c == 'Interview Completed' &&
          oldApp.Status__c != 'Interview Completed'
        ) {
          Task thankYouTask = createTask(
            THANK_YOU_SUBJECT,
            'Send thank you email to interviewer(s)',
            app.Id,
            Date.today().addDays(1), // Send within 24 hours
            'Not Started',
            'High'
          );
          tasksToInsert.add(thankYouTask);
        }
      }
    }

    if (!tasksToInsert.isEmpty()) {
      insert tasksToInsert;
      System.debug(
        'JobApplicationTaskHelper.handleStatusChanges() - created ' +
          tasksToInsert.size() +
          ' status-based tasks'
      );
    }
  }

  /**
   * @description Handles interview-specific task creation and updates
   * @param updatedApplications List of updated Job_Application__c records
   * @param oldApplicationMap Map of old values before update
   */
  public static void handleInterviewScheduling(
    List<Job_Application__c> updatedApplications,
    Map<Id, Job_Application__c> oldApplicationMap
  ) {
    List<Task> tasksToInsert = new List<Task>();

    for (Job_Application__c app : updatedApplications) {
      Job_Application__c oldApp = oldApplicationMap.get(app.Id);

      // Check if status changed to indicate interview scheduling
      if (
        app.Status__c == 'Interview Scheduled' &&
        oldApp.Status__c != 'Interview Scheduled'
      ) {
        // Create interview preparation task
        Task interviewPrepTask = createTask(
          'Interview Preparation - ' +
          (app.Company_Name__c != null ? app.Company_Name__c : 'Company'),
          'Prepare for upcoming interview. Research company, review job description, prepare questions.',
          app.Id,
          Date.today().addDays(2), // Prepare 2 days from now
          'Not Started',
          'High'
        );
        tasksToInsert.add(interviewPrepTask);
      }
    }

    if (!tasksToInsert.isEmpty()) {
      insert tasksToInsert;
      System.debug(
        'JobApplicationTaskHelper.handleInterviewScheduling() - created ' +
          tasksToInsert.size() +
          ' interview tasks'
      );
    }
  }

  /**
   * @description Creates a Task record with specified parameters
   * @param subject Task subject line
   * @param description Task description
   * @param whatId Related record ID (Job_Application__c)
   * @param dueDate Due date for the task
   * @param status Initial status
   * @param priority Task priority
   * @return Task The created task (not yet inserted)
   */
  private static Task createTask(
    String subject,
    String description,
    Id whatId,
    Date dueDate,
    String status,
    String priority
  ) {
    return new Task(
      Subject = subject,
      Description = description,
      WhatId = whatId,
      ActivityDate = dueDate,
      Status = status,
      Priority = priority,
      IsReminderSet = true,
      ReminderDateTime = DateTime.newInstance(
        dueDate,
        Time.newInstance(9, 0, 0, 0)
      ) // 9 AM reminder
    );
  }

  /**
   * @description Determines if an application needs a review task
   * @param app Job_Application__c record to evaluate
   * @return Boolean True if review task should be created
   */
  private static Boolean isApplicationNeedingReview(Job_Application__c app) {
    // Create review tasks for applications with detailed notes or high ratings
    return (app.Rating__c != null &&
      (app.Rating__c == '4' ||
      app.Rating__c == '5')) ||
      (app.Notes__c != null && app.Notes__c.containsIgnoreCase('customize')) ||
      (app.Description__c != null &&
      app.Description__c.length() > 500);
  }
}
