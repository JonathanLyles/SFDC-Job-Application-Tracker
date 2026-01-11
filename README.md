[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

# SFDC Job Application Tracker

## Overview

**SFDC Job Application Tracker** is a comprehensive Salesforce-native application that empowers users to efficiently manage their entire job search journey. From initial job discovery across multiple platforms to final offer acceptance, this solution provides end-to-end lifecycle management within the familiar Salesforce platform.

The application integrates with multiple job board APIs to surface job opportunities from various platforms in a single, centralized view. Users can selectively save relevant job postings into Salesforce, where they can organize and manage all related activities across the full application lifecycle—from initial saving through to job acceptance. Automated workflows create and assign tasks whenever a job application’s status is updated, ensuring consistent tracking and follow-up at every stage of the process.

## Key Features

- Multi-Board Job Search: Quickly search for job postings across multiple boards from a single interface, with results appearing in Salesforce for easy management.
- Async Execution: The system efficiently updates job application data in the background, ensuring responsive performance and up-to-date information.
- Normalized Domain Model: Job postings are presented consistently, making it simple to view, track, and manage applications regardless of source.
- Robust Logging: Activity and updates are logged clearly, providing visibility and traceability for all job search operations.
- Trigger-Driven Task Creation: Follow-up tasks are automatically created based on application status, helping ensure no opportunity is missed.
- Extensible Architecture: Easily add new job boards and integrations without affecting existing workflows.

## Initial Requirements (High-Level)

- Search and discover job opportunities from multiple job boards in one place
- Save and organize job postings that are relevant to the user
- Automatically track and update application tasks based on status changes
- Keep a clear record of all activities and interactions related to each application
- Easily follow up on applications without manual task management
- Ensure the system can grow with new features and integrations without disrupting user experience

## Architecture Overview

SFDC Job Application Tracker is designed to be scalable, maintainable, and highly extensible while following Salesforce best practices and advanced architectural patterns. Key architectural decisions include:

- **Facade / Application Controller:** JobSearchController acts as a stable interface between the LWC UI and backend services, shielding the UI from queueables, strategies, callouts, and persistence details. This enables flexibility and testability while preserving separation of concerns.

- **Async Orchestration & Fan-Out / Fan-In:** Queueable Apex is used to asynchronously execute job board searches. Fan-Out allows each board search to run independently, isolating failures, respecting governor limits, and providing incremental UI updates. Fan-In aggregates results to notify the LWC upon completion.

- **Strategy & Composite Patterns:** The Strategy pattern abstracts individual job board integrations. Composite strategies allow multiple boards to be treated as a single unit while maintaining single-responsibility strategies, enabling easy addition of new job boards.

- **Domain & API Wrappers (Domain-Driven Design):** External API responses are normalized into domain objects (JobPosting, JobSearchCriteria), providing a stable internal representation for queueables, triggers, services, and the UI. API wrappers remain isolated within strategies, encapsulating external formats.

- **Trigger Framework & Event-Driven Automation:** SFDC Trigger Framework ensures bulk-safe, idempotent task creation based on Job_Application\_\_c changes. Platform Events propagate progress and completion updates to the UI.

- **Centralized Logging & Observability:** Nebula Logger provides correlated logs across controllers, services, queueables, strategies, and triggers, enabling full visibility, traceability, and easier troubleshooting.

**Why these decisions matter:** This architecture balances performance, reliability, and maintainability while showcasing advanced Salesforce concepts such as asynchronous orchestration, pattern-based integration, and robust event-driven workflows.

## Getting Started

### Prerequisites

- A Salesforce org (sandbox, scratch, or production) with API version 58.0+
- Admin access to install unmanaged packages and deploy Apex/metadata

### Installing Key Dependencies

Before deploying SFDC Job Application Tracker, install the following dependencies:

1. **Nebula Logger**
   - Provides centralized, correlated logging across all layers (controllers, services, queueables, strategies, triggers).
   - [Install Nebula Logger](#) while logged into your org and grant access to all users.

2. **SFDC Trigger Framework**
   - Ensures bulk-safe, idempotent task automation for Job_Application\_\_c triggers.
   - [Install SFDC Trigger Framework](#) after Nebula Logger and grant access to all users.

> **Note:** Installing these dependencies first ensures the core application operates reliably and logging/triggers work correctly.

### Deploy Job Application Tracker

Option A — Deploy via Salesforce CLI

```bash
# Clone the repo
git clone https://github.com/<username>/job-application-tracker.git
cd job-application-tracker

# Authorize your target org
sfdx auth:web:login -a MyOrgAlias

# Deploy all metadata
sfdx force:source:deploy -p force-app/ -u MyOrgAlias
```

Option B — Deploy via Change Set or Metadata API

- Use VS Code + Salesforce Extension Pack to deploy the force-app/ folder.
- Deploy all Apex classes, triggers, platform events, and LWC components.
- Verify that Job_Application**c and JobSearchCompleted**e are deployed.

### Verify Setup

- Check that all Apex classes and triggers are active.
- Confirm that Nebula Logger custom objects exist in Setup.
- Confirm that JobApplicationTrigger is active.
- Optionally, open the LWC in App Builder and verify it renders correctly.

### Run a Test Search

- Navigate to the Job Search LWC in the App.
- Enter search criteria: keywords, location, and select job boards.
- Click Search.
- Observe results appear incrementally via Platform Events.
- Check debug logs in Nebula Logger to confirm logging and progress events.

## Configuration

_Configuration options will be documented here in the future, including environment settings, feature toggles, and any optional parameters needed for advanced usage._

## Limitations & Assumptions

_This section will describe known limitations, assumptions about user behavior, and constraints of the current implementation. It will help set expectations and guide contributors._

## Roadmap

_A high-level roadmap for upcoming features, improvements, and planned integrations will be outlined here. This will provide transparency on project direction and priorities._

## Contributing

We welcome contributions from anyone interested in improving SFDC Job Application Tracker! To contribute, please follow these steps:

1. **Familiarize Yourself**
   - Take some time to explore the repository, understand the architecture, and review the existing code, patterns, and flows.
   - Review the README, architecture overview, and any documentation provided.

2. **Find an Issue**
   - Look for issues tagged with `good first issue`. These are beginner-friendly and a great way to get started.
   - If you’re interested in a larger or more advanced feature, check the open issues list and discuss it first.

3. **Fork, Branch, and Code**
   - Fork the repository to your GitHub account.
   - Create a new branch for your work (e.g., `feature/add-logging` or `bugfix/fix-api-parsing`).
   - Make your changes with clear, well-documented commits.

4. **Submit a Pull Request (PR)**
   - Ensure your PR is clear, references the issue it addresses, and includes any relevant context.
   - Make sure all tests pass and follow existing code conventions.

5. **Engage with the Review**
   - Be open to feedback and iterate on your PR if necessary.
   - Celebrate your contribution once it’s merged! 🎉

> By contributing, you agree to abide by the MIT License and maintain the project’s standards for quality and maintainability.

## License

This project is licensed under the MIT License.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
