# Salesforce Job Application Tracker

This repository contains a **Salesforce-native Job Application Tracker**, designed to help users search and track job postings across multiple job boards (e.g., Jooble, Indeed, LinkedIn). The application is built using modern Salesforce best practices, including **Queueable Apex, Strategy Patterns, Domain-Driven Design, Platform Events, and robust trigger handling**.

## Key Features

* **Multi-Board Job Search:** Query multiple external APIs in parallel using a composite strategy with fan-out/fan-in orchestration.
* **Async Execution:** Queueable Apex ensures scalable, governor-limit-safe callouts while providing incremental updates to the UI.
* **Normalized Domain Model:** External API responses are normalized into consistent domain objects (`JobPosting`) for downstream processing and persistence.
* **Robust Logging:** Integrated **Nebula Logger** provides consistent, correlated logs across controllers, services, queueables, strategies, and triggers.
* **Trigger-Driven Task Creation:** Uses the Kevin O’Hara trigger framework to create follow-up Tasks based on the status of persisted `Job_Application__c` records.
* **Extensible Architecture:** Adding new job boards is straightforward — implement a strategy, register it, and the system handles orchestration, logging, and event notifications automatically.

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

1. Open this link in your browser while logged into your org:
   [Install Nebula Logger](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tXXXXXXXXXXXX)
2. Follow the prompts to install the unmanaged package.
3. Grant access to all users.

#### 1.2 Kevin O’Hara Trigger Framework

1. Open the framework install link in your browser:
   [Install Trigger Framework](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tYYYYYYYYYYYY)
2. Follow the prompts to install the unmanaged package.
3. Grant access to all users.

> ⚠️ **Important:** Install **Nebula Logger first**, then the Trigger Framework, before deploying the Job Application Tracker code.

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
4. Optionally, open the LWC in App Builder and verify it renders correctly.

### Step 4 — Run a Test Search

1. Navigate to the **Job Search LWC** in the App.
2. Enter search criteria: keywords, location, and select job boards.
3. Click **Search**.
4. Observe results appear incrementally via Platform Events.
5. Check debug logs in **Nebula Logger** to confirm logging and progress events.

## Requirements

This application was built according to the following requirements:

### Multiple External APIs

* Support integration with different job boards (e.g., Jooble, Indeed)
* Abstract API-specific request/response formats via **API wrappers**
* Normalize results into a common **domain wrapper** (`JobPosting`) for consistent downstream processing

### Async Execution & Scalability

* Use **Queueable Apex** for callouts and orchestration
* Support **fan-out/fan-in** patterns for composite searches across multiple boards
* Ensure **bulk-safe persistence** to `Job_Application__c` and reactive triggers for task creation

### Single and Composite Strategies

* Dynamically choose strategy based on user-selected boards
* Use **strategy registry** to resolve board-specific logic
* Composite searches allow parallel processing of multiple boards with progress tracking

### Comprehensive Logging

* Integrate **Nebula Logger** throughout layers: controllers, services, queueables, strategies, triggers
* Track workflow, retries, progress, errors, and events with **searchId correlation**
* Ensure all log entries across layers include **searchId** (and queueable ID if applicable) for consistent correlation and traceability
* Enable observability for troubleshooting, audit, and monitoring

### Robust Trigger Handling

* Use **Kevin O’Hara trigger framework** for `Job_Application__c`
* Handle post-persistence logic (e.g., task creation) in a **bulk-safe, idempotent manner**
* Ensure triggers **react to changes**, not orchestrate external calls

### Domain-Driven Design

* Use **domain wrappers** (`JobPosting`, `JobSearchCriteria`) to normalize external data
* Decouple downstream logic (queueables, triggers, UI) from API-specific formats
* Encapsulate business rules and invariants in domain objects

### Future Growth & Extensibility

* New job boards can be added by implementing a strategy and registering it in the registry
* Architecture supports **scalable orchestration**, additional logging, retries, and new event types
* Modular design allows for **separation of concerns**, maintainability, and easier testing

## Requirements Mapping

| Requirement | Responsible Layer / Component | Notes |
|-------------|-------------------------------|-------|
| Multiple External APIs | **Strategy layer** (single/composite strategies) | Strategies use **API wrappers** to normalize responses; domain wrappers provide consistent internal format |
| Async Execution & Scalability | **Queueables** (JobSearchOrchestratorQueueable, SingleBoardSearchQueueable, CompositeBoardSearchQueueable) | Supports **fan-out/fan-in**, bulk-safe persistence, and retry mechanisms |
| Single and Composite Strategies | **Strategy layer & JobBoardStrategyRegistry** | Registry dynamically resolves appropriate strategy(s); composite strategy handles multiple boards in parallel |
| Comprehensive Logging | **All layers** (Controller, Service, Queueables, Strategies, Triggers) | Uses **Nebula Logger** with searchId correlation; logs workflow, retries, progress, errors, and events |
| Robust Trigger Handling | **Trigger & TriggerHandler** (JobApplicationTrigger + JobApplicationTriggerHandler + JobApplicationTaskHelper) | Uses **Kevin O’Hara Trigger Framework** for bulk-safe, idempotent task creation; triggers react to persisted Job_Application__c records, do not orchestrate external integrations |
| Domain-Driven Design | **Domain layer** (JobPosting, JobSearchCriteria) | Encapsulates business rules, enforces invariants, normalizes external API/input data; acts as a **wrapper** for internal consumption |
| Future Growth & Extensibility | **Architecture-wide** | Adding new boards requires implementing a strategy + registering it; modular layers enable maintainability, testing, and scaling |


## High-Level Flow
```text
LWC UI
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
| Scenario                           | Events Emitted                                                    | Notes                                                                                                                                                                                                          |
| ---------------------------------- | ----------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Single-board search**            | **Progress event only** (incremental)                             | **Progress event** (required) + **Completion event** (optional but recommended) | For a single board, the progress event is sufficient to indicate completion, but emitting a completion event provides consistency with the composite scenario and simplifies LWC handling. |
| **Composite (multi-board) search** | **Progress events** per board + **Completion event** after fan-in | Fan-out creates multiple child queueables, so completion event is necessary to signal that all boards are done.                                                                                                |

## Separation of Concerns
| Layer / Folder  | Responsibility            | What It **Does**                                                                                                | What It **Must Not Do**                          |
| --------------- | ------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| **LWC**         | User Interface            | Collect search criteria, trigger searches, subscribe to platform events, render progress & results              | No business logic, no callouts, no orchestration, no persistence |
| **controller/** | UI Facade                 | Validate inputs, translate UI data → domain objects, create `searchId`, invoke services, handle sync exceptions | No callouts, no async logic, no persistence      |
| **service/**    | Application Workflow      | Decide single vs composite search, define sync → async boundary, initiate orchestration                         | No HTTP callouts, no parsing, no DML             |
| **queueable/**  | Orchestration & Execution | Execute async workflows, manage retries, perform callouts, persist results, publish events                      | No UI logic, no strategy resolution logic        |
| **strategy/**   | Integration Logic         | Build API requests, parse responses, normalize external data into domain objects                                | No DML, no async orchestration, no UI concerns   |
| **registry/**   | Strategy Resolution       | Map job board identifiers → strategy implementations, validate supported boards                                 | No execution, no callouts, no persistence        |
| **domain/**     | Business Model            | Encapsulates core business concepts, such as JobSearchCriteria and JobPosting, acting as wrappers that normalize external or input data, enforce rules and invariants, and provide a consistent, domain-focused representation for use by services, queueables, strategies, triggers, and the UI | No SOQL, no DML, no callouts, no logging         |
| **repository**  | Persistence               | Save/query Job_Application__c records                                                                           | No callouts                                      |
| **trigger/**    | Data Change Reaction      | React to Job_Application__c create/update events                                                                | No callouts, no async orchestration              |
| **triggerHandler/** | Trigger Logic         | Determine which tasks to create based on status                                                                 | No DML outside its scope                         |
| **util/**       | Cross-cutting Helpers     | Stateless helpers (e.g., formatting, context building for logs)                                                 | No business rules, no persistence                |
| **events/**     | Async Communication       | Define platform event schemas for progress & completion                                                         | No orchestration, no logic                       |
| **test/**       | Verification              | Validate behavior, async flows, edge cases, failures                                                            | No production logic                              |


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
│   └── JobPosting.cls
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
- Queueable publishes JobSearchCompledted__e
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

| Concept            | Purpose                                  |
|-------------------|------------------------------------------|
| Composite Strategy | Treat multiple strategies as a single unit |
| Fan-Out Execution  | Run work in parallel units               |

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

JobPosting → normalized job posting, used throughout the system

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
JobPosting jp = response.toDomainJobPosting();
```
6. Queueable receives List<JobPosting> (domain wrappers), persists, triggers tasks, etc.

## Where API Wrappers fit in the flow
```text
Queueable
 ↓
Strategy
    - Build API request wrapper (specific to job board)
    - Execute HTTP callout
    - Parse response into API response wrapper
    - Map API wrapper → domain wrapper (JobPosting)
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
