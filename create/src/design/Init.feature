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
      | @lapa/db      | dependency     |
      | @lapa/tilia   | dependency     |
      | tilia         | dependency     |
      | @tilia/query  | dependency     |
      | @tilia/react  | dependency     |
      | @lapa/board   | dependency     |
      | tailwindcss   | dev dependency |
      | @epure/vitest | dev dependency |
      | @epure/dev    | dev dependency |
      | rescript      | dev dependency |
      | vite          | dev dependency |
    And "adventure/.mcp.json" contains "http://localhost:8080/_lapa/mcp"
    And "adventure/.mcp.json" contains "Authorization"
    And "adventure/AGENTS.md" contains "pnpm dev"
    And "adventure/README.md" contains "# adventure"
    And "adventure/README.md" contains "pnpm dev"
    # pnpm stops on a build script it was not told about and tells the person
    # to run `pnpm approve-builds` — from a directory they are not in, after an
    # install that scrolled past. Asserted on the file rather than on the
    # install: once a build has run, it is in the store and no later install
    # asks again, so the output only shows it on a machine that has never
    # built it.
    And "adventure/pnpm-workspace.yaml" contains "msgpackr-extract: true"
    And "adventure/pnpm-workspace.yaml" contains "esbuild: true"
    And "adventure/.gitignore" contains ".data"
    And "adventure/.gitignore" contains ".mcp.json"
    And "adventure/CONTRIBUTING.md" contains "Three modes"
    And "adventure/src/croquis/.gitkeep" exists
    And "adventure/.gitignore" contains "src/croquis/*"
    And "adventure/rescript.json" contains "src/croquis"
    And "adventure/src/view/Page.res" exists
    And "adventure/src/app.css" exists
    And "adventure/src/Page.res" does not exist
    And "adventure/src" contains the diagonal layout
      | directory          |
      | croquis            |
      | design             |
      | domain/api/entity  |
      | domain/api/feature |
      | domain/api/service |
      | domain/feature     |
      | service            |
      | view               |

  # The agreement sends an assistant to `node_modules/<package>/llms.txt`.
  # Asserted on the install so the promise covers what a registry really
  # ships, not what a checkout holds.
  Scenario: Every method package the scaffold installs ships its reference
    When Theo initializes a project named "adventure"
    Then the installed packages carry a reference
      | package       |
      | tilia         |
      | @tilia/query  |
      | @tilia/react  |
      | lapa          |
      | @lapa/db      |
      | @lapa/tilia   |
      | @lapa/board   |
      | @lapa/server  |
      | @epure/dev    |
      | @epure/vitest |

  Scenario: The project builds after initialization
    When Theo initializes a project named "adventure"
    Then the project dependencies are installed
    And the project builds successfully

  Scenario: The project tests pass after initialization
    When Theo initializes a project named "adventure"
    Then the project tests pass

  Scenario: The built page runs
    When Theo initializes a project named "adventure"
    Then the built page says "this page opens on a session"

  Scenario: The board mounts in the app, and only in dev
    When Theo initializes a project named "adventure"
    Then "adventure/src/view/Page.res" contains "<LapaBoard client />"
    And "adventure/src/view/Page.res" contains "Env.dev"
    And the built page carries no board

  # `dev` moved to @epure/dev. A first word that is not a command is a project
  # name, so without this the old command would scaffold a project called
  # "dev" and say nothing.
  Scenario: The old dev command says where dev went
    When Theo runs epure with "dev"
    Then init fails and reports "@epure/dev"
    And "dev" does not exist

  Scenario: The create convention names the project directly
    When Theo creates a project named "adventure-parc" with no command
    Then "adventure-parc" exists
    And "adventure-parc/package.json" names the project "adventure-parc"


  Scenario: A project made with no registry carries no npmrc
    When Theo initializes a project named "adventure"
    Then "adventure/.npmrc" does not exist

  Scenario: A project made against a registry keeps it
    When Theo initializes a project named "adventure-npm" against "https://registry.npmjs.org/"
    Then "adventure-npm/.npmrc" contains "https://registry.npmjs.org/"

  # ── Refusals ───────────────────────────────────────────────────────────

  Scenario: Init refuses to replace an existing directory
    Given the "adventure" directory contains a file
    When Theo initializes a project named "adventure"
    Then init fails and reports "adventure"
    And "adventure/kept.txt" exists
