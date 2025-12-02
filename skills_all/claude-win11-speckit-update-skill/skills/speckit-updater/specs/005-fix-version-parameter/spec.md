# Feature Specification: Fix Version Parameter Handling in Update Orchestrator

**Feature Branch**: `005-fix-version-parameter`
**Created**: 2025-10-20
**Status**: Draft
**Input**: User description: "docs\bugs\003-missing-speckit-version-parameter.md"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Automatic Latest Version Update (Priority: P1)

As a SpecKit user, I want to run the update command without specifying a version number so that I can automatically receive the latest templates without needing to know what version is current.

**Why this priority**: This is the primary use case for updates - users expect "update" to mean "get the latest version" without requiring them to research version numbers. This is currently completely broken.

**Independent Test**: Can be fully tested by running the update command without parameters and verifying it fetches and applies the latest version from GitHub Releases.

**Acceptance Scenarios**:

1. **Given** I am in a SpecKit project directory, **When** I run the update command without specifying a version, **Then** the system fetches the latest version from GitHub Releases and displays what will be updated
2. **Given** I am in a SpecKit project directory, **When** I run the update command in check-only mode without a version, **Then** the system shows me what changes are available in the latest version
3. **Given** the GitHub API returns version information, **When** the system processes the response, **Then** it extracts the version number correctly and uses it for template downloads

---

### User Story 2 - Clear Error Messages for API Failures (Priority: P2)

As a SpecKit user, when the GitHub API is unavailable or fails, I want to receive a clear error message explaining the problem so that I can understand whether to retry, check my network, or wait for GitHub to recover.

**Why this priority**: This prevents users from encountering cryptic "missing parameter" errors that don't indicate the actual problem. Essential for good user experience but secondary to making the feature work at all.

**Independent Test**: Can be tested by simulating network failures or rate limiting and verifying error messages are helpful and actionable.

**Acceptance Scenarios**:

1. **Given** the GitHub API is unreachable, **When** I run the update command, **Then** I receive an error message stating "Failed to connect to GitHub Releases API" with troubleshooting guidance
2. **Given** the GitHub API returns invalid data, **When** the system processes the response, **Then** I receive an error message indicating the API response was unexpected
3. **Given** the GitHub API rate limit is exceeded, **When** I run the update command, **Then** I receive an error message explaining the rate limit and when to retry

---

### User Story 3 - Explicit Version Override (Priority: P3)

As a SpecKit user, I want to optionally specify an explicit version number when updating so that I can install a specific version (e.g., for testing, rollback, or controlled deployments).

**Why this priority**: This is a secondary use case that already works as a workaround. Ensuring it continues to work after fixing the primary issue.

**Independent Test**: Can be tested by specifying various version numbers and verifying they are used instead of auto-detecting latest.

**Acceptance Scenarios**:

1. **Given** I specify a version number (e.g., v0.0.72), **When** I run the update command, **Then** the system uses my specified version instead of fetching the latest
2. **Given** I specify an invalid version number, **When** I run the update command, **Then** I receive a clear error message stating the version does not exist
3. **Given** I specify a version that is older than my current installation, **When** I run the update command with confirmation, **Then** the system allows the downgrade

---

### Edge Cases

- What happens when the GitHub API returns valid JSON but is missing the expected `tag_name` field?
- How does the system handle scenarios where the network is slow but not completely unavailable (timeout handling)?
- What happens if the user's current version is already the latest version?
- How does the system behave if the manifest exists but is corrupted or has invalid version information?
- What happens when the GitHub repository structure changes and releases have different properties?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST fetch the latest SpecKit release version from GitHub Releases API when no explicit version is specified
- **FR-002**: System MUST validate that the GitHub API response contains valid release information before attempting to use it
- **FR-003**: System MUST display a clear error message when the GitHub API is unreachable or returns invalid data
- **FR-004**: System MUST extract the version identifier correctly from the GitHub API response
- **FR-005**: System MUST use consistent parameter naming between function definitions and function calls
- **FR-006**: System MUST handle GitHub API rate limiting gracefully with informative error messages
- **FR-007**: System MUST validate that required data fields exist in API responses before accessing them
- **FR-008**: System MUST support explicit version specification that overrides automatic latest version detection
- **FR-009**: System MUST provide diagnostic information (via verbose logging) about API calls and responses for troubleshooting
- **FR-010**: System MUST timeout GitHub API calls after 30 seconds and display a clear timeout error message when the API is slow to respond

### Key Entities

- **GitHub Release**: Represents a SpecKit version available for download, containing version identifier (tag_name), download URLs for templates, and release metadata
- **Version Identifier**: The specific SpecKit version to install, either auto-detected from latest release or explicitly specified by user
- **API Response**: Data returned from GitHub Releases API, which must be validated before use

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can successfully run the update command without specifying a version and receive the latest templates from GitHub
- **SC-002**: When GitHub API calls fail, users receive actionable error messages that identify the problem within 3 seconds
- **SC-003**: 100% of function calls use correct parameter names that match their function definitions
- **SC-004**: System validates all API responses before using them, preventing parameter binding errors
- **SC-005**: Explicit version specification continues to work for all valid version identifiers
- **SC-006**: Users can identify whether an update failure is due to network issues, API problems, or invalid versions based on error messages
- **SC-007**: Update command completes successfully in 95% of invocations when GitHub API is available

## Assumptions *(mandatory)*

- GitHub Releases API structure remains consistent with current format (has `tag_name` property)
- Users have network connectivity to reach api.github.com
- The GitHub repository structure (NotMyself/SpecKit or similar) is the source for releases
- PowerShell version supports the Invoke-RestMethod cmdlet for API calls
- Rate limiting follows GitHub's standard unauthenticated API limits (60 requests per hour per IP)

## Dependencies *(mandatory)*

- GitHub Releases API availability and stability
- Network connectivity to api.github.com
- Existing GitHubApiClient.psm1 module structure
- Existing update-orchestrator.ps1 workflow
- Manifest management system for storing current version

## Open Questions

None - all critical information for implementation is specified above.

## Out of Scope

- Implementing authentication for GitHub API (remains unauthenticated)
- Caching GitHub API responses locally
- Implementing automatic retry logic with exponential backoff
- Adding progress indicators for API calls
- Supporting alternative package sources besides GitHub Releases
- Implementing version comparison logic (e.g., semantic versioning awareness beyond exact matches)