Feature: Initialize an epure project

  For Theo, starting an app beside an agent.

  `epure init <name>` creates and installs a project with the method files
  and the reference stack. The new project builds immediately.

  Background:
    Given an empty working directory

  # ── Scaffold ───────────────────────────────────────────────────────────

  Scenario: Init creates the project files
    When Theo initializes a project named "adventure"
    Then "adventure" exists
    And "adventure" contains the method files
      | file            |
      | CONTRIBUTING.md |
      | AGENTS.md       |
      | CONVENTIONS.md  |
      | SESSION.md      |
      | DECISIONS.md    |
    And "adventure/package.json" contains the stack dependencies
      | dependency    | type           |
      | lapa          | dependency     |
      | tilia         | dependency     |
      | @tilia/query  | dependency     |
      | @tilia/react  | dependency     |
      | @epure/vitest | dev dependency |
      | @epure/create | dev dependency |
      | rescript      | dev dependency |
      | vite          | dev dependency |
    And "adventure/.mcp.json" contains "http://localhost:8080/_lapa/mcp"
    And "adventure/.gitignore" contains ".data"
    And "adventure/src/view/Page.res" exists
    And "adventure/src/service/Live.res" exists
    And "adventure/src" contains the diagonal layout
      | directory          |
      | design             |
      | domain/api/entity  |
      | domain/api/feature |
      | domain/api/service |
      | domain/feature     |
      | service            |
      | view               |

  Scenario: The project builds after initialization
    When Theo initializes a project named "adventure"
    Then the project dependencies are installed
    And the project builds successfully

  Scenario: The project tests pass after initialization
    When Theo initializes a project named "adventure"
    Then the project tests pass

  Scenario: The built page runs
    When Theo initializes a project named "adventure"
    Then the built page says "adventure is running"

  # ── Refusals ───────────────────────────────────────────────────────────

  Scenario: Init refuses to replace an existing directory
    Given the "adventure" directory contains a file
    When Theo initializes a project named "adventure"
    Then init fails and reports "adventure"
    And "adventure/kept.txt" exists
