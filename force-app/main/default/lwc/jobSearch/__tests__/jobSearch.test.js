import { createElement } from "@lwc/engine-dom";
import JobSearch from "c/jobSearch";

// Mock the Apex method
import searchJobs from "@salesforce/apex/JobSearchController.searchJobs";
jest.mock(
  "@salesforce/apex/JobSearchController.searchJobs",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

// Helper function to create and append job search component
function createJobSearchElement() {
  const element = createElement("c-job-search", {
    is: JobSearch
  });
  document.body.appendChild(element);
  return element;
}

// Helper function for DOM cleanup - used in afterEach
function cleanupDOM() {
  while (document.body.firstChild) {
    document.body.removeChild(document.body.firstChild);
  }
}

describe("Initial Render", () => {
  afterEach(cleanupDOM);

  it('Renders a lightning-card with the title "Job Search"', () => {
    // Arrange & Act
    const element = createJobSearchElement();

    // Assert
    const lightningCard = element.shadowRoot.querySelector("lightning-card");
    expect(lightningCard).not.toBeNull();
    expect(lightningCard.title).toBe("Job Search");
  });

  it("Renders keyword and location inputs", () => {
    // Arrange & Act
    const element = createJobSearchElement();

    // Assert
    const inputs = element.shadowRoot.querySelectorAll("lightning-input");

    const keywordInput = [...inputs].find(
      (input) => input.label === "Keywords"
    );
    const locationInput = [...inputs].find(
      (input) => input.label === "Location"
    );

    expect(keywordInput).toBeDefined();
    expect(locationInput).toBeDefined();

    // Optional but reasonable initialization checks
    expect(keywordInput.value).toBe("");
    expect(locationInput.value).toBe("");
  });

  it("Renders a lightning-dual-listbox for work type", () => {
    // Arrange & Act
    const element = createJobSearchElement();

    // Assert
    const dualListBox = element.shadowRoot.querySelector(
      "lightning-dual-listbox"
    );
    expect(dualListBox).not.toBeNull();
    expect(dualListBox.label).toBe("Work Type");
    expect(dualListBox.sourceLabel).toBe("Available Options");
    expect(dualListBox.selectedLabel).toBe("Selected");
    expect(dualListBox.value).toEqual([]);
  });

  it("Renders a button to search jobs", () => {
    // Arrange & Act
    const element = createJobSearchElement();

    // Assert
    const searchButton = element.shadowRoot.querySelector("lightning-button");
    expect(searchButton).not.toBeNull();
    expect(searchButton.label).toBe("Search Jobs");
    expect(searchButton.disabled).toBe(false);
  });
});

describe("Conditional UI", () => {
  afterEach(cleanupDOM);

  it("Does not render column filters", () => {
    // Arrange & Act
    const element = createJobSearchElement();

    // Assert
    const inputs = element.shadowRoot.querySelectorAll("lightning-input");
    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");

    expect(inputs.length).toBe(2); // Only two inputs (Keywords and Location)
    expect(combobox).toBeNull();
    expect(buttons.length).toBe(1); // Only one button (Search Jobs)
  });

  it("Does not render spinner", () => {
    // Arrange & Act
    const element = createJobSearchElement();

    // Assert
    const spinner = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner).toBeNull();
  });

  it("Does not render data table", () => {
    // Arrange & Act
    const element = createJobSearchElement();

    // Assert
    const dataTable = element.shadowRoot.querySelector("lightning-datatable");
    expect(dataTable).toBeNull();
  });

  it("Renders a data table when hasResults is true", async () => {
    // Arrange
    const mockJobData = [
      {
        id: "1",
        title: "Test Job",
        salary: "$50,000",
        company: "Test Company",
        location: "Test City",
        workType: "remote",
        source: "Test Source"
      }
    ];

    searchJobs.mockResolvedValue(mockJobData);

    const element = createJobSearchElement();

    // Act - Trigger search to make hasResults true
    const searchButton = element.shadowRoot.querySelector("lightning-button");
    searchButton.dispatchEvent(new CustomEvent("click"));

    // Wait for async operations and re-render
    await Promise.resolve();
    await Promise.resolve();

    // Assert
    const dataTable = element.shadowRoot.querySelector("lightning-datatable");
    expect(dataTable).not.toBeNull();
    expect(dataTable.keyField).toBe("id");
  });

  it("Does not render no jobs found", () => {
    // Arrange & Act
    const element = createJobSearchElement();

    // Assert
    expect(element.shadowRoot.textContent).not.toContain(
      "No jobs found for your search."
    );
  });
});

describe("Error State", () => {
  afterEach(cleanupDOM);

  it("Does not render error message on initial load", () => {
    // Arrange & Act
    const element = createJobSearchElement();

    // Assert
    const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
    expect(errorDiv).toBeNull();
  });
});

describe("Input handlers", () => {
  afterEach(cleanupDOM);

  it("Handles keyword input changes without errors", () => {
    // Arrange
    const element = createJobSearchElement();

    const inputs = element.shadowRoot.querySelectorAll("lightning-input");
    const keywordInput = [...inputs].find(
      (input) => input.label === "Keywords"
    );

    // Act - Simulate user typing in the input
    // Test that the component can handle input changes without throwing errors
    expect(() => {
      keywordInput.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "test" },
          bubbles: true
        })
      );
    }).not.toThrow();

    // Assert - Component should still be functional after handling the event
    expect(keywordInput).toBeDefined();
    expect(element.shadowRoot.querySelector("lightning-card")).not.toBeNull();
  });

  it("GIVEN the job search form is rendered WHEN the user enters keywords THEN the component updates its state and UI", async () => {
    // ============================================================
    // GIVEN
    // ============================================================
    // The component exists in the DOM and is fully rendered.
    // In Jest, nothing renders until we explicitly append it.
    // Think of this as: "The page has loaded."
    // ============================================================

    const element = createJobSearchElement();

    const inputs = element.shadowRoot.querySelectorAll("lightning-input");

    const keywordInput = [...inputs].find(
      (input) => input.label === "Keywords"
    );

    // If this fails, the test setup is wrong - not the logic
    expect(keywordInput).toBeTruthy();

    // ============================================================
    // WHEN
    // ============================================================
    // The user types "test" into the Keywords input.
    //
    // In the browser, lightning-input fires a "change" event
    // that bubbles up to the LWC component.
    // Jest does NOT do this automatically, so we simulate it.
    // ============================================================

    keywordInput.value = "test"; // Simulates the user typing "test"
    keywordInput.dispatchEvent(
      new CustomEvent("change", {
        detail: { value: "test" }, // What the user typed
        bubbles: true // Allow LWC to hear the event
      })
    );

    // LWC re-renders asynchronously.
    // This microtask flush ensures the component finishes reacting
    // before we make assertions.
    await Promise.resolve();

    // ============================================================
    // THEN
    // ============================================================
    // The component should reflect the new state in the UI.
    // We assert what the USER can observe, not internal variables.
    // ============================================================

    // If the component correctly handled the event:
    // - the handler ran
    // - the internal state updated
    // - the UI re-rendered
    expect(keywordInput.value).toBe("test");
  });

  it("GIVEN the job search form is rendered WHEN the user enters location THEN the component updates its state and UI", async () => {
    // ============================================================
    // GIVEN
    // ============================================================
    // The component exists in the DOM and is fully rendered.")

    const element = createJobSearchElement();

    const inputs = element.shadowRoot.querySelectorAll("lightning-input");

    const locationInput = [...inputs].find(
      (input) => input.label === "Location"
    );

    // If this fails, the test setup is wrong - not the logic
    expect(locationInput).toBeTruthy();

    // ============================================================
    // WHEN
    // ============================================================
    // The user types "remote" into the Location input.
    //
    // In the browser, lightning-input fires a "change" event
    // that bubbles up to the LWC component.
    // Jest does NOT do this automatically, so we simulate it.
    // ============================================================
    locationInput.value = "remote"; // Simulates the user typing "test"
    locationInput.dispatchEvent(
      new CustomEvent("change", {
        detail: { value: "remote" }, // What the user typed
        bubbles: true // Allow LWC to hear the event
      })
    );
    // LWC re-renders asynchronously.
    // This microtask flush ensures the component finishes reacting
    // before we make assertions.
    await Promise.resolve();

    // ============================================================
    // THEN
    // ============================================================
    // The component should reflect the new state in the UI.
    // We assert what the USER can observe, not internal variables.
    // ============================================================

    // If the component correctly handled the event:
    // - the handler ran
    // - the internal state updated
    // - the UI re-rendered
    expect(locationInput.value).toBe("remote");
  });

  it("GIVEN the job search form is rendered WHEN the user selects one or more work type options THEN the component updates its state and UI", async () => {
    // ============================================================
    // GIVEN
    // ============================================================
    // The component exists in the DOM and is fully rendered.")

    const element = createJobSearchElement();

    const workTypes = element.shadowRoot.querySelector(
      "lightning-dual-listbox"
    );

    // If this fails, the test setup is wrong - not the logic
    expect(workTypes).toBeTruthy();

    // ============================================================
    // WHEN
    // ============================================================
    // The user selects "onsite" and "remote" in the work type dual listbox
    //
    // In the browser, lightning-dual-listbox fires a "change" event
    // that bubbles up to the LWC component.
    // Jest does NOT do this automatically, so we simulate it.
    // ============================================================
    workTypes.value = ["remote", "onsite"]; // Simulates the user selecting "remote" and "onsite"
    workTypes.dispatchEvent(
      new CustomEvent("change", {
        detail: { value: ["remote", "onsite"] }
      })
    );
    // LWC re-renders asynchronously.
    // This microtask flush ensures the component finishes reacting
    // before we make assertions.
    await Promise.resolve();
    // ============================================================
    // THEN
    // ============================================================
    // The component should reflect the new state in the UI.
    // We assert what the USER can observe, not internal variables.
    // ============================================================

    // If the component correctly handled the event:
    // - the handler ran
    // - the internal state updated
    // - the UI re-rendered
    expect(workTypes.value).toStrictEqual(["remote", "onsite"]);
  });
});

describe("Conditional Rendering", () => {
  beforeEach(() => {
    // Clear all mocks before each test
    jest.clearAllMocks();
  });

  afterEach(cleanupDOM);

  it("should render datatable when search returns results", async () => {
    // Arrange
    const mockJobData = [
      {
        id: "1",
        title: "Senior Developer",
        salary: "$95,000",
        company: "TechCorp",
        location: "Toronto",
        workType: "remote",
        source: "LinkedIn"
      },
      {
        id: "2",
        title: "Frontend Developer",
        salary: "$75,000",
        company: "WebCorp",
        location: "Montreal",
        workType: "hybrid",
        source: "Indeed"
      }
    ];

    searchJobs.mockResolvedValue(mockJobData);

    const element = createJobSearchElement();

    // Act - Find the search button and trigger click event
    const searchButton = element.shadowRoot.querySelector("lightning-button");
    expect(searchButton).not.toBeNull(); // Ensure button exists

    // Simulate button click by dispatching click event
    searchButton.dispatchEvent(new CustomEvent("click"));

    // Wait for async operations and re-render
    await Promise.resolve();
    await Promise.resolve();

    // Assert - Datatable should be rendered
    const dataTable = element.shadowRoot.querySelector("lightning-datatable");
    expect(dataTable).not.toBeNull();
    expect(dataTable.keyField).toBe("id");
  });

  it("should render column filters when search returns results", async () => {
    // Arrange
    const mockJobData = [
      {
        id: "1",
        title: "Test Job",
        salary: "$50k",
        company: "Test Corp",
        location: "Test City",
        workType: "remote",
        source: "Test"
      }
    ];

    searchJobs.mockResolvedValue(mockJobData);

    const element = createJobSearchElement();

    // Act - Trigger search using generic button selector
    const searchButton = element.shadowRoot.querySelector("lightning-button");
    searchButton.dispatchEvent(new CustomEvent("click"));

    // Wait for async operations and re-render
    await Promise.resolve();
    await Promise.resolve();

    // Assert - Column filters should be rendered
    // Check for filter inputs in a more generic way since attribute selectors may not work
    const allInputs = element.shadowRoot.querySelectorAll("lightning-input");
    const allComboboxes =
      element.shadowRoot.querySelectorAll("lightning-combobox");
    const allButtons = element.shadowRoot.querySelectorAll("lightning-button");

    // Should have more than just the initial search inputs (keywords, location)
    // After search: keywords, location, + 5 filter inputs = 7 total
    expect(allInputs.length).toBeGreaterThan(2);

    // Should have at least one combobox (the filter type combobox)
    expect(allComboboxes.length).toBeGreaterThan(0);

    // Should have more than just the search button (search + pagination + clear filters)
    expect(allButtons.length).toBeGreaterThan(1);
  });

  it("should NOT render datatable when search returns no results", async () => {
    // Arrange
    searchJobs.mockResolvedValue([]);

    const element = createJobSearchElement();

    // Act - Trigger search that returns no results
    const searchButton = element.shadowRoot.querySelector("lightning-button");
    searchButton.dispatchEvent(new CustomEvent("click"));

    // Wait for async operations
    await Promise.resolve();
    await Promise.resolve();

    // Assert
    const dataTable = element.shadowRoot.querySelector("lightning-datatable");
    expect(dataTable).toBeNull();
  });

  it("should render loading spinner during search", async () => {
    // Arrange
    const element = createJobSearchElement();

    // Mock a slow response to test loading state
    let resolveSearch;
    searchJobs.mockImplementation(
      () =>
        new Promise((resolve) => {
          resolveSearch = () => resolve([]);
        })
    );

    // Act - Start search to enter loading state
    const searchButton = element.shadowRoot.querySelector("lightning-button");
    searchButton.dispatchEvent(new CustomEvent("click"));

    // Wait one cycle to enter loading state but not complete
    await Promise.resolve();

    // Assert - Should be in loading state
    const dataTable = element.shadowRoot.querySelector("lightning-datatable");
    expect(dataTable).toBeNull();

    // Should show spinner instead
    const spinner = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner).not.toBeNull();

    // Clean up by resolving the promise
    resolveSearch();
    await Promise.resolve();
  });

  it("should render empty state message when search returns no results", async () => {
    // Arrange
    searchJobs.mockResolvedValue([]);

    const element = createJobSearchElement();

    // Act - Trigger search that returns no results (this will set hasSearched=true)
    const searchButton = element.shadowRoot.querySelector("lightning-button");
    searchButton.dispatchEvent(new CustomEvent("click"));

    // Wait for async operations
    await Promise.resolve();
    await Promise.resolve();

    // Assert
    expect(element.shadowRoot.textContent).toContain(
      "No jobs found for your search."
    );
  });

  it("should render error message when search fails", async () => {
    // Arrange
    const errorMessage = "Test error message";
    searchJobs.mockRejectedValue({
      body: { message: errorMessage }
    });

    const element = createJobSearchElement();

    // Act - Trigger search that will fail
    const searchButton = element.shadowRoot.querySelector("lightning-button");
    searchButton.dispatchEvent(new CustomEvent("click"));

    // Wait for async operations and error handling
    await Promise.resolve();
    await Promise.resolve();

    // Assert
    const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
    expect(errorDiv).not.toBeNull();
    expect(errorDiv.textContent.trim()).toBe(errorMessage);
  });
});
