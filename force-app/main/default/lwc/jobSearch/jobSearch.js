import { LightningElement } from "lwc";
import searchJobs from "@salesforce/apex/JobSearchController.searchJobs";

const PAGE_SIZE = 10;

export default class JobSearch extends LightningElement {
  // Search inputs
  keywords = "";
  location = "";
  selectedWorkTypes = [];

  // Work type options
  workTypeOptions = [
    { label: "Remote", value: "remote" },
    { label: "Onsite", value: "onsite" },
    { label: "Hybrid", value: "hybrid" }
  ];

  // UI state
  isLoading = false;
  hasError = false;
  hasSearched = false;
  errorMessage;

  // Data
  jobs = [];
  currentPage = 1;

  // Sorting
  sortedBy = "title";
  sortedDirection = "asc";

  // Column filters
  titleFilter = "";
  salaryFilter = "";
  companyFilter = "";
  locationFilter = "";
  typeFilter = "";
  sourceFilter = "";

  // Original jobs data (before filtering)
  originalJobs = [];

  columns = [
    { label: "Title", fieldName: "title", sortable: true },
    { label: "Salary", fieldName: "salary", sortable: true },
    { label: "Company", fieldName: "company", sortable: true },
    { label: "Location", fieldName: "location", sortable: true },
    { label: "Type", fieldName: "workType", sortable: true },
    { label: "Source", fieldName: "source", sortable: true }
  ];

  /* ------------------
   * Derived properties
   * ------------------ */

  get hasResults() {
    return this.jobs.length > 0 && !this.isLoading;
  }

  get hasSearchResults() {
    return this.originalJobs.length > 0 && !this.isLoading;
  }

  get isEmpty() {
    return (
      !this.isLoading &&
      this.hasSearched &&
      this.originalJobs.length === 0 &&
      !this.hasError
    );
  }

  get noFilteredResults() {
    return this.hasSearchResults && this.jobs.length === 0;
  }

  get totalPages() {
    return Math.ceil(this.jobs.length / PAGE_SIZE);
  }

  get pagedJobs() {
    const start = (this.currentPage - 1) * PAGE_SIZE;
    const end = start + PAGE_SIZE;
    return this.jobs.slice(start, end);
  }

  get isFirstPage() {
    return this.currentPage === 1;
  }

  get isLastPage() {
    return this.currentPage === this.totalPages;
  }

  get showFirstButton() {
    // Show if more than 2 pages AND not on page 1 or 2
    return this.totalPages > 2 && this.currentPage > 2;
  }

  get showLastButton() {
    // Show if more than 2 pages AND not on last page or second-to-last page
    return this.totalPages > 2 && this.currentPage < this.totalPages - 1;
  }

  get typeFilterOptions() {
    return [
      { label: "All Types", value: "" },
      { label: "Remote", value: "remote" },
      { label: "Onsite", value: "onsite" },
      { label: "Hybrid", value: "hybrid" }
    ];
  }

  /* ------------------
   * Event handlers
   * ------------------ */

  handleKeywordsChange(event) {
    this.keywords = event.target.value;
  }

  handleLocationChange(event) {
    this.location = event.target.value;
  }

  handleWorkTypeChange(event) {
    this.selectedWorkTypes = event.detail.value;
  }

  async handleSearch() {
    this.resetState();
    this.isLoading = true;
    this.hasSearched = true;

    try {
      const result = await searchJobs({
        keywords: this.keywords,
        location: this.location,
        workTypes: this.selectedWorkTypes
      });

      this.originalJobs = result || [];
      this.jobs = [...this.originalJobs];
      this.currentPage = 1;

      // Clear column filters when new search is performed
      this.titleFilter = "";
      this.salaryFilter = "";
      this.companyFilter = "";
      this.locationFilter = "";
      this.typeFilter = "";
      this.sourceFilter = "";
    } catch (error) {
      this.hasError = true;
      this.errorMessage = error.body?.message || "An unexpected error occurred";
    } finally {
      this.isLoading = false;
    }
  }

  handlePrevious() {
    if (this.currentPage > 1) {
      this.currentPage--;
    }
  }

  handleNext() {
    if (this.currentPage < this.totalPages) {
      this.currentPage++;
    }
  }

  handleFirst() {
    this.currentPage = 1;
  }

  handleLast() {
    this.currentPage = this.totalPages;
  }

  handleTitleFilterChange(event) {
    this.titleFilter = event.target.value;
    this.applyFilters();
  }

  handleSalaryFilterChange(event) {
    this.salaryFilter = event.target.value;
    this.applyFilters();
  }

  handleCompanyFilterChange(event) {
    this.companyFilter = event.target.value;
    this.applyFilters();
  }

  handleLocationFilterChange(event) {
    this.locationFilter = event.target.value;
    this.applyFilters();
  }

  handleTypeFilterChange(event) {
    this.typeFilter = event.detail.value;
    this.applyFilters();
  }

  handleSourceFilterChange(event) {
    this.sourceFilter = event.target.value;
    this.applyFilters();
  }

  handleClearFilters() {
    this.titleFilter = "";
    this.salaryFilter = "";
    this.companyFilter = "";
    this.locationFilter = "";
    this.typeFilter = "";
    this.sourceFilter = "";
    this.applyFilters();
  }

  applyFilters() {
    let filteredJobs = [...this.originalJobs];

    if (this.titleFilter) {
      filteredJobs = filteredJobs.filter(
        (job) =>
          job.title &&
          job.title.toLowerCase().includes(this.titleFilter.toLowerCase())
      );
    }

    if (this.salaryFilter) {
      filteredJobs = filteredJobs.filter(
        (job) =>
          job.salary &&
          job.salary.toLowerCase().includes(this.salaryFilter.toLowerCase())
      );
    }

    if (this.companyFilter) {
      filteredJobs = filteredJobs.filter(
        (job) =>
          job.company &&
          job.company.toLowerCase().includes(this.companyFilter.toLowerCase())
      );
    }

    if (this.locationFilter) {
      filteredJobs = filteredJobs.filter(
        (job) =>
          job.location &&
          job.location.toLowerCase().includes(this.locationFilter.toLowerCase())
      );
    }

    if (this.typeFilter) {
      filteredJobs = filteredJobs.filter(
        (job) => job.workType === this.typeFilter
      );
    }

    if (this.sourceFilter) {
      filteredJobs = filteredJobs.filter(
        (job) =>
          job.source &&
          job.source.toLowerCase().includes(this.sourceFilter.toLowerCase())
      );
    }

    this.jobs = filteredJobs;
    this.currentPage = 1; // Reset to first page after filtering
  }

  handleSort(event) {
    const { fieldName: sortedBy, sortDirection } = event.detail;
    const cloneData = [...this.jobs];

    cloneData.sort((a, b) => {
      let aVal = a[sortedBy] || "";
      let bVal = b[sortedBy] || "";

      // Convert to strings for consistent sorting
      aVal = String(aVal).toLowerCase();
      bVal = String(bVal).toLowerCase();

      if (aVal < bVal) {
        return sortDirection === "asc" ? -1 : 1;
      }
      if (aVal > bVal) {
        return sortDirection === "asc" ? 1 : -1;
      }
      return 0;
    });

    this.jobs = cloneData;
    this.sortedBy = sortedBy;
    this.sortedDirection = sortDirection;
    this.currentPage = 1; // Reset to first page after sorting
  }

  resetState() {
    this.jobs = [];
    this.originalJobs = [];
    this.currentPage = 1;
    this.hasError = false;
    this.errorMessage = null;
    // Note: hasSearched is NOT reset here - we want to preserve search state
  }
}
