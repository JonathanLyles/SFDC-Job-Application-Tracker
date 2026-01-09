(Work in progress)

# Salesforce Job Application Tracker

This repository contains a **Salesforce-native Job Application Tracker**, designed to help users search and track job postings across multiple job boards (e.g. Jooble, Google Jobs, etc). The application is built using modern Salesforce best practices, including **Queueable Apex, Strategy Patterns, Domain-Driven Design, Platform Events, and robust trigger handling**.

## Key Features

- **Multi-Board Job Search:** Query multiple external APIs in parallel using a composite strategy with fan-out/fan-in orchestration.
- **Async Execution:** Queueable Apex ensures scalable, governor-limit-safe callouts while providing incremental updates to the UI.
- **Normalized Domain Model:** External API responses are normalized into consistent domain objects (`JobApplicationDomain`) for downstream processing and persistence.
- **Robust Logging:** Integrated **Nebula Logger** provides consistent, correlated logs across controllers, services, queueables, strategies, and triggers.
- **Trigger-Driven Task Creation:** Uses the Kevin O’Hara trigger framework to create follow-up Tasks based on the status of persisted `Job_Application__c` records.
- **Extensible Architecture:** Adding new job boards is straightforward — implement a strategy, register it, and the system handles orchestration, logging, and event notifications automatically.

## Purpose

This project demonstrates a **scalable and maintainable architecture** for integrating Salesforce with multiple external APIs, handling asynchronous processing, and providing real-time UI updates. It follows **Hexagonal / Clean Architecture principles**, separating concerns across the UI, application services, strategies, queueables, and triggers, while ensuring observability, robustness, and ease of testing.

## Setup Instructions

### Prerequisites

Before deploying the application, ensure you have:

1. A Salesforce org (sandbox, scratch, or production) with **API version 58.0+**.
2. Admin access to install unmanaged packages and deploy Apex/metadata.
3. Installed dependencies (see below).

### Step 1 — Install Dependencies

#### 1.1 Nebula Logger

**Option A: Install via Salesforce CLI (Recommended)**

```bash
# Install Nebula Logger unlocked package
sf package install --package 04t5Y0000023NSRQA2 --target-org your-org-alias --wait 10

# Verify installation
sf org open --target-org your-org-alias
```

**Option B: Install via Browser**

1. Open this link in your browser while logged into your org:
   [Install Nebula Logger](https://github.com/jongpie/NebulaLogger/releases/latest)
2. Follow the prompts to install the unlocked package.
3. Grant access to all users.

**Option C: AppExchange**

1. Search "Nebula Logger" on Salesforce AppExchange
2. Install by Jon Pie
3. Grant access to all users

#### 1.2 Kevin O’Hara Trigger Framework

**Option A: Install via Salesforce CLI (Recommended)**

```bash
# Install Trigger Handler unlocked package
sf package install --package 04t6g000007h8DKAAY --target-org your-org-alias --wait 10

# Verify installation
sf org open --target-org your-org-alias
```

**Option B: Install via Browser**

1. Open this link in your browser while logged into your org:
   [Install Trigger Framework](https://github.com/kevinohara80/sfdc-trigger-framework)
2. Follow the installation instructions for the unlocked package.
3. Grant access to all users.

**Option C: GitHub**

1. Visit [Kevin O'Hara's Trigger Framework](https://github.com/kevinohara80/sfdc-trigger-framework)
2. Use the provided package installation link
3. Grant access to all users

> ⚠️ **Important:** Install **Nebula Logger first**, then the Trigger Framework, before deploying the Job Application Tracker code.

#### 1.3 Configure Project Dependencies

After installing Nebula Logger, update your `sfdx-project.json` to declare the dependency:

```json
{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true,
      "dependencies": [
        {
          "package": "NebulaLogger",
          "versionNumber": "4.14.15.LATEST"
        },
        {
          "package": "TriggerHandler",
          "versionNumber": "2.0.0.LATEST"
        }
      ]
    }
  ],
  "name": "Job Application Tracker Application",
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com",
  "sourceApiVersion": "65.0"
}
```

### Step 2 — Deploy Job Application Tracker

#### Option A — Deploy via Salesforce CLI

```bash
# Clone the repo
git clone https://github.com/<username>/job-application-tracker.git
cd job-application-tracker

# Authorize your target org
sfdx auth:web:login -a MyOrgAlias

# Deploy all metadata
sfdx force:source:deploy -p force-app/ -u MyOrgAlias
```

#### Option B — Deploy via Change Set or Metadata API

1. Use **VS Code + Salesforce Extension Pack** to deploy the `force-app/` folder.
2. Deploy **all Apex classes, triggers, platform events, and LWC components**.
3. Verify that `Job_Application__c` and `JobSearchCompleted__e` are deployed.

### Step 3 — Verify Setup

1. Check that all **Apex classes** and **triggers** are active.
2. Confirm that **Nebula Logger** custom objects exist in Setup.
3. Confirm that **JobApplicationTrigger** is active.
4. Verify Logger configuration by checking Setup → Custom Settings → Logger Settings.
5. Optionally, open the LWC in App Builder and verify it renders correctly.

#### Verify Nebula Logger Integration

After deployment, verify that Nebula Logger is working:

```bash
# Open Developer Console and run this Apex script:
Logger.info('Job Application Tracker - Setup Verification')
    .setField('Component', 'Setup')
    .setField('Status', 'SUCCESS');
Logger.saveLog();

# Check logs in Setup → Custom Objects → Log → View All
```

### Step 4 — Run a Test Search

1. Navigate to the **Job Search LWC** in the App.
2. Enter search criteria: keywords, location, and select job boards.
3. Click **Search**.
4. Observe results appear incrementally via Platform Events.
5. Check debug logs in **Nebula Logger** to confirm logging and progress events.

## Architectural Decisions

### Dependency Management: Package Dependencies vs Source Code Inclusion

This project follows **package dependency best practices** for managing third-party dependencies like Nebula Logger and Kevin O'Hara's Trigger Framework, rather than including external source code directly in the repository.

#### ✅ **Chosen Approach: Package Dependencies**

**What this means:**

- **Third-party source code is NOT included** in this repository
- Dependencies are declared in `sfdx-project.json` and installed separately
- Clear separation between application code and external packages

**Configuration:**

```json
{
  "packageDirectories": [
    {
      "path": "force-app",
      "default": true,
      "dependencies": [
        {
          "package": "NebulaLogger",
          "versionNumber": "4.14.15.LATEST"
        }
      ]
    }
  ]
}
```

**Benefits of this approach:**

1. **🔄 Clean Separation:** Your application code remains distinct from third-party dependencies
2. **🔄 Automatic Updates:** Easily upgrade to newer versions of Nebula Logger without merge conflicts
3. **📦 Smaller Repository:** Keeps repo focused on business logic, not external dependencies
4. **👥 Clear Dependencies:** Other developers immediately understand what external packages are required
5. **🔧 Standard Practice:** Follows established patterns in Salesforce development community
6. **⚡ Easier Maintenance:** No need to track upstream changes or maintain forks

**Deployment workflow:**

```bash
# 1. Install dependencies first
sf package install --package 04t5Y0000023NSRQA2 --target-org your-org  # Nebula Logger
sf package install --package 04t6g000007h8DKAAY --target-org your-org  # Trigger Framework

# 2. Then deploy your application
sf project deploy start --source-dir force-app --target-org your-org
```

#### ❌ **Alternative Approach: Source Code Inclusion (Not Recommended)**

Including third-party source code (Nebula Logger, Trigger Framework, etc.) directly would create:

- **🚫 Maintenance Overhead:** Manual tracking of upstream updates
- **🚫 Code Mixing:** Third-party code mixed with business logic
- **🚫 Update Complexity:** Difficult to upgrade without conflicts
- **🚫 Unclear Ownership:** Confusion about what code belongs to your project
- **🚫 Repository Bloat:** Unnecessary increase in repository size

#### **Summary**

This architectural decision ensures the **Job Application Tracker** remains focused on its core business logic while leveraging enterprise-grade logging capabilities through a well-maintained, external package. This approach promotes **maintainability, clarity, and follows Salesforce development best practices**.

## Requirements

This application was built according to the following requirements:

### Multiple External APIs

- Support integration with different job boards (e.g., Jooble, Indeed)
- Abstract API-specific request/response formats via **API wrappers**
- Normalize results into a common **domain wrapper** (`JobApplicationDomain`) for consistent downstream processing

### Async Execution & Scalability

- Use **Queueable Apex** for callouts and orchestration
- Support **fan-out/fan-in** patterns for composite searches across multiple boards
- Ensure **bulk-safe persistence** to `Job_Application__c` and reactive triggers for task creation

### Single and Composite Strategies

- Dynamically choose strategy based on user-selected boards
- Use **strategy registry** to resolve board-specific logic
- Composite searches allow parallel processing of multiple boards with progress tracking

### Comprehensive Logging

- Integrate **Nebula Logger** throughout layers: controllers, services, queueables, strategies, triggers
- Track workflow, retries, progress, errors, and events with **searchId correlation**
- Ensure all log entries across layers include **searchId** (and queueable ID if applicable) for consistent correlation and traceability
- Enable observability for troubleshooting, audit, and monitoring

### Robust Trigger Handling

- Use **Kevin O’Hara trigger framework** for `Job_Application__c`
- Handle post-persistence logic (e.g., task creation) in a **bulk-safe, idempotent manner** (Idempotent - checks if task already exists)
- Ensure triggers **react to changes**, not orchestrate external calls

### Data Normalization Pattern

**The Problem:** Each job board API returns data in completely different formats, but our application needs to work with consistent data internally.

**The Solution:** Separate "defining the standard format" from "transforming into that format."

**Two-Layer Approach:**

🏗️ **Domain Layer** - **DEFINES** the standard data structures

- Contains class definitions that specify what our normalized data looks like
- Examples: `JobSearchCriteria.cls`, `JobApplicationDomain.cls`
- Think of this as creating the "blueprint" or "template" for how data should be structured
- No transformation logic - just defines properties, validation rules, and data structure

⚙️ **Strategy Layer** - **TRANSFORMS** external data into those standard structures

- Contains the actual conversion logic from messy external APIs → clean domain objects
- Examples: `JoobleStrategy.cls` takes Jooble JSON → creates `JobApplicationDomain` objects
- Think of this as the "assembly line" that takes raw materials and shapes them to match the blueprint

**Data Flow Example:**

```text
User enters "Software Developer" + "New York"
    ↓
JobSearchCriteria (Domain Layer defines this structure)
    ↓
JoobleStrategy (Strategy Layer transforms this into Jooble API format)
    ↓
Jooble API returns messy JSON response
    ↓
JoobleStrategy (Strategy Layer transforms JSON into domain format)
    ↓
JobApplicationDomain (Domain Layer defines this structure)
    ↓
Rest of application works with consistent, clean data
```

**Why this separation works:** Domain Layer stays simple and stable (just data definitions), while Strategy Layer handles all the messy API-specific transformation logic.

### Future Growth & Extensibility

- New job boards can be added by implementing a strategy and registering it in the registry
- Architecture supports **scalable orchestration**, additional logging, retries, and new event types
- Modular design allows for **separation of concerns**, maintainability, and easier testing

## Requirements Mapping

| Requirement                     | Architectural Layer                                                                                            | Design Pattern(s)                                                                                                                                                                   | Component(s)                                   | Class(es)                                                                                 | Notes                                                                                                    |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- | ----------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Multiple External APIs          | Integration                                                                                                    | Strategy, Factory                                                                                                                                                                   | Strategy Registry, Individual Strategies       | JobBoardStrategyRegistry, JoobleStrategy, IndeedStrategy                                  | Registry acts as factory; each strategy normalizes different API formats into domain objects             |
| Async Execution & Scalability   | Orchestration                                                                                                  | Queueable, Fan-out/Fan-in                                                                                                                                                           | Orchestrator, Board-Specific Processors        | JobSearchOrchestratorQueueable, SingleBoardSearchQueueable, CompositeBoardSearchQueueable | Each queueable handles one board to respect governor limits; supports parallel execution                 |
| Single and Composite Strategies | Integration                                                                                                    | Strategy, Composite                                                                                                                                                                 | Strategy Implementation, Strategy Orchestrator | AbstractJobBoardStrategy, CompositeJobBoardStrategy                                       | Composite pattern coordinates multiple strategies; registry resolves appropriate strategy(s)             |
| Comprehensive Logging           | Cross-cutting                                                                                                  | Observer, Correlation                                                                                                                                                               | Log Context Builder, Event Publisher           | LoggerContextUtil (planned), Platform Event Publishers                                    | Nebula Logger with searchId correlation across all layers; enables tracing and debugging                 |
| Robust Trigger Handling         | **Trigger & TriggerHandler** (JobApplicationTrigger + JobApplicationTriggerHandler + JobApplicationTaskHelper) | Uses **Kevin O’Hara Trigger Framework** for bulk-safe, idempotent task creation; triggers react to persisted Job_Application\_\_c records, do not orchestrate external integrations |
| Data Normalization Pattern      | Domain                                                                                                         | Domain Model, Data Transfer Object                                                                                                                                                  | Domain Objects, Criteria Wrappers              | JobApplicationDomain, JobSearchCriteria                                                   | Domain objects encapsulate business rules and provide consistent internal data representation            |
| Future Growth & Extensibility   | Architecture-wide                                                                                              | Strategy, Registry                                                                                                                                                                  | Pluggable Strategy System                      | All strategy implementations + registry                                                   | New job boards added by implementing strategy interface and registering; modular design supports scaling |

## High-Level Flow

```text
jobSearch (LWC UI)
    - Collect criteria
    - Trigger search
    - Subscribe to platform events
     ↓
JobSearchController (UI Facade)
    - Validate input
    - Logger.info(valid input submitted)
    - Logger.error(validation error)
    - Translate to JobSearchCriteria
    - Create searchId
    - Start JobSearchService
    - Logger.info(search initiated)

     ↓
JobSearchService (Sync boundary)
    - Decide: SINGLE or COMPOSITE
    - Logger.info(routing decision)
    - Enqueue JobSearchOrchestratorQueueable
     ↓
JobSearchOrchestratorQueueable
    - Logger.info(orchestration start)
    - If SINGLE:
        - Enqueue SingleBoardSearchQueueable
    - If COMPOSITE:
        - Enqueue CompositeBoardSearchQueueable
```

### Single Board Scenario

```text
SingleBoardSearchQueueable
    - Resolve strategy via registry
    - Logger.info(strategy resolved)
    - Build & execute HTTP callout
    - Logger.info(callout metadata)
    - Parse response
    - Logger.info/error(parse success/failure)
    - Persist Job_Application__c records
    - Logger.info/error(success / partial failure)
         ↓
     JobApplicationTrigger (after insert / after update)
         ↓
     JobApplicationTriggerHandler (Kevin O’Hara framework)
         - Route by trigger context
         - Enforce one-trigger-per-object rule
         ↓
     JobApplicationTaskHelper
         - Create Task records based on status
         - Bulk-safe, idempotent
    - Publish progress event (optional)
    - Retry if needed
        - Logger.info(retry attempt)
    - Publish completion event (required)
         ↓
     Platform Event
         - Logger.info(event published)
         - Correlation: searchId
         ↓
     LWC subscriber
         - UI updates
```

### Composite (Multi-Board) Scenario

```text
CompositeBoardSearchQueueable
    - Determine selected boards
    - Logger.info(fan-out start)
    - Fan-out: enqueue SingleBoardSearchQueueable (per board)

SingleBoardSearchQueueable (per board)
    - Queueable ID: sbJobId_i
    - Resolve strategy
    - Execute HTTP callout
    - Parse response
    - Persist Job_Application__c records
         ↓
     JobApplicationTrigger (after insert / after update)
         ↓
     JobApplicationTriggerHandler
         ↓
     JobApplicationTaskHelper
         - Create Tasks per status
    - Logger.info(per-board completion)
    - Publish progress event
    - Retry if needed
    - Notify JobSearchTrackingService

JobSearchTrackingService (Fan-in)
    - Track completed boards
    - Logger.info(fan-in progress)
    - When all boards complete:
         ↓
    - Aggregate final state
    - Logger.info(composite complete)
    - Publish completion event
         ↓
    Platform Event
         ↓
    LWC subscriber
         - UI updates

```

## Event Behavior by Scenario

| Scenario                           | Events Emitted                                                    | Notes                                                                                                           |
| ---------------------------------- | ----------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Single-board search**            | **Progress event only** (incremental)                             | **Progress event** (required) + **Completion event** (optional but recommended)                                 | For a single board, the progress event is sufficient to indicate completion, but emitting a completion event provides consistency with the composite scenario and simplifies LWC handling. |
| **Composite (multi-board) search** | **Progress events** per board + **Completion event** after fan-in | Fan-out creates multiple child queueables, so completion event is necessary to signal that all boards are done. |

## Separation of Concerns

| Layer / Folder      | Responsibility            | What It **Does**                                                                                                                                                                                                                                                                                           | What It **Must Not Do**                                          |
| ------------------- | ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| **LWC**             | User Interface            | Collect search criteria, trigger searches, subscribe to platform events, render progress & results                                                                                                                                                                                                         | No business logic, no callouts, no orchestration, no persistence |
| **controller/**     | UI Facade                 | Validate inputs, translate UI data → domain objects, create `searchId`, invoke services, handle sync exceptions                                                                                                                                                                                            | No callouts, no async logic, no persistence                      |
| **service/**        | Application Workflow      | Decide single vs composite search, define sync → async boundary, initiate orchestration                                                                                                                                                                                                                    | No HTTP callouts, no parsing, no DML                             |
| **queueable/**      | Orchestration & Execution | Execute async workflows, manage retries, perform callouts, persist results, publish events                                                                                                                                                                                                                 | No UI logic, no strategy resolution logic                        |
| **strategy/**       | Integration Logic         | Build API requests, parse responses, normalize external data into domain objects                                                                                                                                                                                                                           | No DML, no async orchestration, no UI concerns                   |
| **registry/**       | Strategy Resolution       | Map job board identifiers → strategy implementations, validate supported boards                                                                                                                                                                                                                            | No execution, no callouts, no persistence                        |
| **domain/**         | Business Model            | Encapsulates core business concepts, such as JobSearchCriteria and JobApplicationDomain, acting as wrappers that normalize external or input data, enforce rules and invariants, and provide a consistent, domain-focused representation for use by services, queueables, strategies, triggers, and the UI | No SOQL, no DML, no callouts, no logging                         |
| **repository**      | Persistence               | Save/query Job_Application\_\_c records                                                                                                                                                                                                                                                                    | No callouts                                                      |
| **trigger/**        | Data Change Reaction      | React to Job_Application\_\_c create/update events                                                                                                                                                                                                                                                         | No callouts, no async orchestration                              |
| **triggerHandler/** | Trigger Logic             | Determine which tasks to create based on status                                                                                                                                                                                                                                                            | No DML outside its scope                                         |
| **util/**           | Cross-cutting Helpers     | Stateless helpers (e.g., formatting, context building for logs)                                                                                                                                                                                                                                            | No business rules, no persistence                                |
| **events/**         | Async Communication       | Define platform event schemas for progress & completion                                                                                                                                                                                                                                                    | No orchestration, no logic                                       |
| **test/**           | Verification              | Validate behavior, async flows, edge cases, failures                                                                                                                                                                                                                                                       | No production logic                                              |

## Folder / File Structure

```text
lwc/
└── jobSearch/
    ├── jobSearch.html
    ├── jobSearch.js
    └── jobSearch.js-meta.xml

apex/
├── controller/
│   └── JobSearchController.cls
│
├── domain/
│   ├── JobSearchCriteria.cls
│   └── JobApplicationDomain.cls
│
├── service/
│   ├── JobSearchService.cls
│   └── JobSearchTrackingService.cls
│
├── registry/
│   └── JobBoardStrategyRegistry.cls
│
├── strategy/
│   ├── JobBoardSearchStrategy.cls
│   ├── base/
│   │   └── AbstractJobBoardStrategy.cls
│   ├── single/
│   │   ├── JoobleStrategy.cls
│   │   └── IndeedStrategy.cls
│   └── composite/
│       └── CompositeJobBoardStrategy.cls
│
├── queueable/
│   ├── JobSearchOrchestratorQueueable.cls
│   ├── SingleBoardSearchQueueable.cls
│   └── CompositeBoardSearchQueueable.cls
│
├── trigger/
│   └── JobApplicationTrigger.trigger
│
├── triggerHandler/
│   ├── JobApplicationTriggerHandler.cls
│   └── JobApplicationTaskHelper.cls
├── util/
│   ├── JobPostingUtils.cls
│   └── LoggerContextUtil.cls
│
├── events/
│   └── JobSearchCompleted__e
│
└── test/

```

### Application Controller (a.k.a. Facade)

The Application Controller (JobSearchController) acts as a **facade** between the LWC UI and the backend application logic. Its responsibilities include:

- **Validate inputs** from the UI
- **Translate UI DTOs → domain objects** (`JobSearchCriteria`)
- **Create a searchId** for tracking async workflows
- **Invoke services** to start the search
- **Handle synchronous exceptions** and return immediate feedback to the UI

#### Why this pattern is used

- **Shields the UI from complexity:** The LWC does not need to know about queueables, strategies, callouts, or persistence.
- **Provides a stable API:** The controller exposes a small, well-defined set of `@AuraEnabled` methods that the UI can reliably use.
- **Allows internals to evolve freely:** Services, queueables, and strategies can change, scale, or be refactored without affecting the UI layer.

> This is **not traditional MVC** — the controller does not handle view rendering or business logic. Instead, it aligns more closely with **Hexagonal/Clean Architecture**, acting as an adapter between the external world (UI) and the core application logic, ensuring separation of concerns and testability.

## Orchestration Patterns

JobSearchController orchestrates UI → backend

JobSearchService orchestrates sync → async

JobSearchOrchestratorQueueable orchestrates execution flow

Each one orchestrates at a different level.

## LWC Communication Pattern

Platorm Events

- Queueable publishes JobSearchCompledted\_\_e
- LWC subscribes via empAPI

## Fan-Out Pattern

In plain English, Fan-Out means taking one request and splitting it into multiple independent units of work that can run seperately.

```text
One request
     ↓
  Split into many
```

In our application, Fan-Out happens when the user selects more than one job-board. For example:

```text
Keywords: Salesforce Developer
Location: Montreal
Job Boards: [Jooble, Indeed, LinkedIn]
```

What Fan-Out looks like at runtime:

```text
CompositeBoardSearchQueueable
 ├─ SingleBoardSearchQueueable (Jooble)
 ├─ SingleBoardSearchQueueable (Indeed)
 └─ SingleBoardSearchQueueable (LinkedIn)
```

Each child Queueable:
Runs independently
Makes exactly one external callout
Uses its own strategy
Can succeed or fail without affecting the others
That splitting action is the fan-out.

Where Fan-Out lives in the application's flow

```text
LWC
 ↓
JobSearchController (facade)
 ↓
JobSearchService (sync)
 ↓
JobSearchOrchestratorQueueable
 ↓
CompositeBoardSearchQueueable   ← fan-out happens here
  ├─ SingleBoardSearchQueueable (Board A)
  ├─ SingleBoardSearchQueueable (Board B)
  └─ SingleBoardSearchQueueable (Board C)
 ↓
Strategy (build + parse only)
 ↓
HTTP Callout
 ↓
Persist results + publish Platform Event
```

## Why We Use Fan-Out for Job Board Searches

The **fan-out pattern** is a core part of how this application executes searches across multiple job boards. Here’s why it’s the right approach:

### 1️⃣ Salesforce Governor Limits

Salesforce imposes strict limits per transaction, such as:

- Maximum number of HTTP callouts
- Maximum CPU time

Fan-out ensures that each job board search runs in its **own Queueable**, so:

- **One board = one callout = one Queueable**
- No single transaction exceeds governor limits

### 2️⃣ Failure Isolation

Without fan-out, a failure on one board could cause the entire search to fail.  
With fan-out:

- Each board executes independently
- Failures are isolated (e.g., Jooble ❌, Indeed ✅, LinkedIn ✅)
- Results arrive separately via **Platform Events**

### 3️⃣ Better User Experience

Fan-out allows the UI to:

- Show results incrementally
- Indicate which boards succeeded or failed
- Avoid waiting for the slowest provider

This is particularly important when integrating with multiple external APIs.

### Fan-Out vs Composite Strategy

These are related but distinct concepts:

| Concept            | Purpose                                    |
| ------------------ | ------------------------------------------ |
| Composite Strategy | Treat multiple strategies as a single unit |
| Fan-Out Execution  | Run work in parallel units                 |

In this application:

- **Composite Strategy** exists at the **execution logic** level
- **Fan-Out** exists at the **async orchestration** level
- This separation keeps strategies **simple and single-purpose** while safely scaling execution

### Common Mistakes Avoided

Many implementations try to:

- ❌ Loop over boards in a single Queueable
- ❌ Make multiple callouts in one transaction
- ❌ Manually handle partial failures

Fan-out avoids these issues cleanly and consistently.

### One-Sentence Definition

> Fan-out is the pattern of splitting one logical request into multiple independent async executions, each responsible for a single unit of work.

### Salesforce Context

- **Queueable Apex** = the mechanism
- **Fan-out** = how we use that mechanism

In short, **fan-out is a sub-pattern of async orchestration** implemented via Queueables, providing scalability, reliability, and better observability.

## Domain Layer Wrappers

Represent internal, normalized business concepts.

Examples:

JobSearchCriteria → user input

JobApplicationDomain → normalized job posting, used throughout the system

Purpose: Provide a stable internal representation for queueables, triggers, services, and the UI.

Do not care about raw API fields or JSON formats.

## API Wrappers

Represent external API request and response structures.

Examples:

JoobleRequestWrapper, JoobleResponseWrapper

IndeedRequestWrapper, IndeedResponseWrapper

Purpose: Encapsulate and validate API-specific formats, headers, JSON parsing, and optional metadata.

Do not contain business logic (except mapping to domain objects).

## How Strategies Use Wrappers

Strategies are the bridge between API wrappers and domain wrappers:

1. Strategy receives a JobSearchCriteria (domain object) from the queueable/service.

2. Strategy builds an API request wrapper, e.g.:

```apex
JoobleRequestWrapper request = new JoobleRequestWrapper(criteria);
```

3. Strategy executes the HTTP callout.

4. Strategy receives the response and parses it into an API response wrapper:

```apex
JoobleResponseWrapper response = JoobleResponseWrapper.fromJSON(jsonResponse);
```

5. Strategy maps the API wrapper to a domain wrapper:

```apex
JobApplicationDomain jp = response.toDomainJobApplicationDomain();
```

6. Queueable receives List<JobApplicationDomain> (domain wrappers), persists, triggers tasks, etc.

## Where API Wrappers fit in the flow

```text
Queueable
 ↓
Strategy
    - Build API request wrapper (specific to job board)
    - Execute HTTP callout
    - Parse response into API response wrapper
    - Map API wrapper → domain wrapper (JobApplicationDomain)
 ↓
Persist Job_Application__c using domain wrapper
 ↓
Triggers / Task creation
 ↓
Events & UI update
```

Key point: API wrappers are inside the strategy layer, never leak to services, queueables, or triggers.

Domain wrappers remain the common language for all layers outside the strategy.
API wrappers are internal to strategies and are never exposed to services, queueables, triggers, or the UI.
Strategies are responsible for mapping API wrappers → domain wrappers before passing data downstream.

## Testing Strategy & Architecture

### Overview

Our Job Application Tracker employs a comprehensive testing strategy designed to ensure 85%+ code coverage while maintaining fast, reliable test execution. The testing architecture follows enterprise patterns that support the application's multi-layered design and complex async processing workflows.

### Testing Philosophy

**Pyramid Approach**: We prioritize unit tests for business logic, integration tests for cross-layer interactions, and end-to-end tests for critical user workflows. This approach ensures fast feedback cycles while maintaining confidence in system behavior.

**Layer-Specific Coverage Targets**:

- **Domain Layer**: 95% (critical business rules and data validation)
- **Controller Layer**: 90% (user input validation and orchestration)
- **Service Layer**: 90% (business logic coordination)
- **Strategy Layer**: 90% (external API integration logic)
- **Async Layer**: 85% (queueable processing workflows)
- **Trigger Layer**: 95% (data consistency and automation)

### Architectural Patterns

#### 1. Test Data Factory Pattern

```apex
@isTest
public class TestDataFactory {
  public static JobSearchCriteria createValidCriteria() {
    return JobSearchCriteria.create('Software Developer', 'Toronto')
      .withWorkTypes(new List<String>{ 'remote' })
      .withJobBoards(new List<String>{ 'jooble' });
  }

  public static JobApplicationDomain createSampleJob() {
    // Standardized test data creation
  }
}
```

**Rationale**: Centralizes test data creation, ensures consistency across tests, and makes tests more maintainable when data structures evolve.

#### 2. HTTP Callout Mock Framework

```apex
@isTest
public class JobBoardAPICalloutMock implements HttpCalloutMock {
  private Map<String, HttpCalloutMock> endpointMocks;

  public void setMock(String endpoint, HttpCalloutMock mock) {
    // Route different endpoints to different mocks
  }
}
```

**Pattern**: Strategy Pattern for mocking different job board APIs
**Tradeoff**: More complex setup but enables isolated testing of each integration

#### 3. Async Testing Utilities

```apex
@isTest
public class AsyncTestUtils {
  public static void executeQueueableWithMocks(
    Queueable job,
    HttpCalloutMock mock
  ) {
    Test.setMock(HttpCalloutMock.class, mock);
    Test.startTest();
    System.enqueueJob(job);
    Test.stopTest();
    // Verification helpers
  }
}
```

**Rationale**: Encapsulates the complex `Test.startTest()`/`Test.stopTest()` pattern required for testing queueables with callouts, reducing boilerplate in individual tests.

### Test Organization Structure

```
force-app/test/default/classes/
├── testUtilities/
│   ├── TestDataFactory.cls
│   ├── JobBoardAPICalloutMock.cls
│   └── AsyncTestUtils.cls
├── domain/
│   ├── JobApplicationDomainTest.cls
│   └── JobSearchCriteriaTest.cls
├── service/
│   ├── JobSearchServiceTest.cls
│   └── JobSearchTrackingServiceTest.cls
├── strategies/
│   ├── JoobleStrategyTest.cls
│   ├── IndeedStrategyTest.cls
│   └── JobBoardStrategyRegistryTest.cls
├── queueables/
│   ├── JobSearchOrchestratorQueueableTest.cls
│   ├── CompositeBoardSearchQueueableTest.cls
│   └── SingleBoardSearchQueueableTest.cls
├── controller/
│   └── JobSearchControllerTest.cls
└── triggerHandler/
    ├── JobApplicationTriggerHandlerTest.cls
    └── JobApplicationTaskHelperTest.cls
```

### Key Architectural Decisions

#### 1. Mock-First External Integration Testing

**Decision**: All external API calls are mocked using `HttpCalloutMock`
**Rationale**: Ensures tests are fast, reliable, and don't depend on external service availability
**Tradeoff**: Requires maintaining mock responses that match real API behavior

#### 2. Platform Event Testing Strategy

**Decision**: Use `Test.getEventBus().deliver()` for synchronous event testing
**Pattern**: Event-Driven Testing Pattern

```apex
@isTest
public static void testJobSearchCompletionEvent() {
    // Trigger event
    EventBus.publish(new JobSearchCompleted__e(/*...*/));
    Test.getEventBus().deliver(); // Force immediate delivery
    // Verify handlers processed event
}
```

**Rationale**: Enables testing event-driven workflows without complex async handling

#### 3. Custom Metadata Testing Approach

**Decision**: Use test-specific custom metadata records rather than dependency injection
**Implementation**: Leverage `@TestSetup` methods to create test metadata
**Tradeoff**: Tests depend on metadata structure but remain simpler than full dependency injection

#### 4. Queueable Chain Testing Strategy

**Pattern**: Builder Pattern for complex async scenarios

```apex
@isTest
public class QueueableTestBuilder {
  public QueueableTestBuilder withJobBoards(List<String> boards) {
    /*...*/
  }
  public QueueableTestBuilder expectingResults(Integer count) {
    /*...*/
  }
  public void executeAndVerify() {
    /*...*/
  }
}
```

**Rationale**: Simplifies testing of complex queueable orchestration chains

### LWC Testing Enhancement

**Current State**: ~60% Jest coverage
**Target**: 90% coverage with comprehensive integration scenarios

**Testing Patterns**:

- **Component State Testing**: Verify reactive property updates
- **User Interaction Testing**: Mock user inputs and verify component responses
- **Apex Integration Testing**: Mock controller methods for isolated component testing
- **Error Handling Testing**: Verify graceful handling of API failures

### Performance Considerations

**Test Execution Time**: Target <2 minutes for full Apex test suite
**Optimization Strategies**:

- Bulk test data creation using `@TestSetup`
- Minimal DML operations in test methods
- Efficient use of `Test.startTest()`/`Test.stopTest()` boundaries
- Selective use of `@SeeAllData=false` (default)

### Continuous Integration Integration

**Pre-commit Hooks**:

- Jest tests for LWC components
- Apex syntax validation
- Code coverage verification

**CI/CD Pipeline**:

- Automated test execution on all pull requests
- Coverage reporting with failure on <85% coverage
- Performance monitoring for test execution time

### Maintenance Strategy

**Test Data Evolution**: TestDataFactory pattern ensures single point of change when domain models evolve

**Mock Maintenance**: Centralized HttpCalloutMock framework allows updating API responses across all tests from single location

**Coverage Monitoring**: Automated coverage reports identify areas requiring additional test scenarios

### Known Limitations & Tradeoffs

1. **Async Testing Complexity**: Queueable testing requires careful orchestration of Test.startTest()/stopTest() boundaries
2. **External API Simulation**: Mock responses must be manually updated when external APIs change
3. **Platform Event Testing**: Synchronous delivery in tests differs from async production behavior
4. **Custom Metadata Dependencies**: Tests may need updates when metadata structure changes

This testing architecture provides robust coverage while maintaining maintainability and supporting the application's enterprise-grade async processing requirements.

## Code Quality & PMD Compliance

This project adheres to enterprise code quality standards enforced by **PMD static analysis**. All PMD violations have been systematically resolved to ensure maintainable, secure, and performant code.

### PMD Compliance Challenges & Solutions

#### Challenge 1: Method Naming Conventions

**Problem:** PMD flagged test methods with underscore-separated names (`test_method_name`)

```apex
// ❌ PMD Violation: "Method name does not begin with a lower case character"
public static void test_search_jobs_valid_criteria_returns_search_id() { ... }
```

**Solution:** Converted all test method names to camelCase format

```apex
// ✅ PMD Compliant
public static void testSearchJobsValidCriteriaReturnsSearchId() { ... }
```

#### Challenge 2: Missing Assertion Messages

**Problem:** PMD required descriptive messages for all assertion statements

```apex
// ❌ PMD Violation: "should have 3 parameters"
System.assertEquals(expected, actual);
```

**Solution:** Added descriptive third parameters to all assertions

```apex
// ✅ PMD Compliant
System.assertEquals(expected, actual, 'Search ID should match expected format');
```

#### Challenge 3: Excessive Parameter Lists

**Problem:** PMD flagged test helper methods with too many parameters (≥5 parameters)

```apex
// ❌ PMD Violation: "Avoid long parameter lists"
private static void notifyCompletion(
  String searchId,
  String jobBoard,
  String status,
  Integer resultCount,
  String errorMessage
) { ... }

// Usage throughout 19 test methods
notifyCompletion(searchId, 'Indeed', 'SUCCESS', 25, null);
```

**Root Cause:** The convenience helper method violated PMD's parameter count threshold, creating technical debt despite having clean production APIs.

**Solution:** Complete elimination of 5-parameter method with comprehensive DTO migration

```apex
// ✅ PMD Compliant: Single method using DTO pattern
private static void notifyCompletion(
  String searchId,
  JobSearchTrackingService.BoardCompletionData completionData
) {
  JobSearchTrackingService.notifyBoardCompletion(searchId, completionData);
}

// ✅ Updated usage pattern across all test methods
JobSearchTrackingService.BoardCompletionData completionData =
  // Success completion
JobSearchTrackingService.createSuccessCompletion('Indeed', 25);

// Failure completion
JobSearchTrackingService.createFailureCompletion('Jooble', 'API error');
notifyCompletion(searchId, completionData);
```

**Implementation Details:**

- **Removed** 5-parameter overload method entirely (not just deprecated)
- **Updated** all 19 test method calls to use DTO construction
- **Maintained** 100% test coverage throughout refactoring
- **Enforced** consistent DTO pattern alignment with production code

**Why Complete Removal vs. Overloading:**

- PMD violations cannot be resolved with method overloading - both signatures are analyzed
- Complete removal eliminates technical debt rather than hiding it
- Forces consistent use of enterprise DTO patterns throughout test suite
- Prevents future developers from using the non-compliant convenience method

#### Challenge 4: Constructor Parameter Lists

**Problem:** Production code constructors also triggered PMD ExcessiveParameterList violations

```apex
// ❌ PMD Violation: Constructor with 4+ parameters
public SingleBoardSearchQueueable(
  String searchId,
  JobSearchCriteria criteria,
  String jobBoard,
  Boolean isCompositeChild
) { ... }

// Usage in composite search orchestration
new SingleBoardSearchQueueable(searchId, criteria, board, true);
```

**Root Cause:** Constructor parameter proliferation in queueable classes created coupling and maintainability issues.

**Solution:** Configuration object pattern for constructor parameters

```apex
// ✅ PMD Compliant: Builder pattern eliminates parameter count violations
public class SearchConfig {
  public String searchId;
  public JobSearchCriteria criteria;
  public String jobBoard;
  public Boolean isCompositeChild;

  private SearchConfig() {
    // Private constructor to force use of builder
  }

  public static SearchConfigBuilder newBuilder() {
    return new SearchConfigBuilder();
  }

  public class SearchConfigBuilder {
    private SearchConfig config;

    public SearchConfigBuilder() {
      this.config = new SearchConfig();
    }

    public SearchConfigBuilder withSearchId(String searchId) {
      this.config.searchId = searchId;
      return this;
    }

    public SearchConfigBuilder withCriteria(JobSearchCriteria criteria) {
      this.config.criteria = criteria;
      return this;
    }

    public SearchConfigBuilder withJobBoard(String jobBoard) {
      this.config.jobBoard = jobBoard;
      return this;
    }

    public SearchConfigBuilder withCompositeChild(Boolean isCompositeChild) {
      this.config.isCompositeChild = isCompositeChild;
      return this;
    }

    public SearchConfig build() {
      return this.config;
    }
  }
}

// ✅ Single-parameter constructor
public SingleBoardSearchQueueable(SearchConfig config) {
  this.searchId = config.searchId;
  this.criteria = config.criteria;
  this.jobBoard = config.jobBoard;
  this.isCompositeChild = config.isCompositeChild;
}

// ✅ Updated usage pattern with fluent builder API
SingleBoardSearchQueueable.SearchConfig config = SingleBoardSearchQueueable.SearchConfig.newBuilder()
  .withSearchId(searchId)
  .withCriteria(criteria)
  .withJobBoard(board)
  .withCompositeChild(true)
  .build();
```

**Benefits:**

- **Zero Parameter Count Violations**: Builder pattern completely eliminates constructor parameter limits
- **Fluent API**: Self-documenting method chaining improves code readability
- **Extensibility**: Easy to add new configuration properties without breaking existing code
- **Type Safety**: Compile-time validation of parameter types and required fields
- **PMD Compliance**: No methods exceed parameter count thresholds

### Design Benefits of PMD Compliance

1. **Consistency**: Uniform naming conventions improve code readability
2. **Debugging**: Descriptive assertion messages provide clear failure context
3. **Maintainability**: DTO pattern reduces parameter coupling and improves extensibility
4. **Enterprise Standards**: PMD compliance ensures code meets corporate quality gates

### Current PMD Status

- ✅ **37/37 tests passing** (100% success rate)
- ✅ **Zero PMD violations** across all classes (test and production)
- ✅ **Clean API design** using DTO pattern for complex parameter sets
- ✅ **Configuration objects** for constructor parameter encapsulation
- ✅ **Comprehensive assertion coverage** with descriptive failure messages

The codebase now meets enterprise-grade quality standards while maintaining full functionality and comprehensive test coverage.
