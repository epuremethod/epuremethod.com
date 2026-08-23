Feature: Sync the template's versions

  For the person publishing the template.

  `pnpm sync` asks the registry in front of it what each of the template's
  dependencies is published as, and writes what it finds into
  `templates/package.json`: a caret over the version for a released line, and
  the tag itself for a line still in beta, so a scaffold installs the newest
  beta the registry holds.

  Background:
    Given a registry answering for the template's dependencies

  # ── What sync writes ───────────────────────────────────────────────────

  Scenario: Sync writes a caret over the published version
    Given "react" is published at "19.2.3"
    When the template is synced
    Then the template names "react" at "^19.2.3"

  Scenario: Sync writes the tag when the published version is a beta
    Given "@lapa/db" is published at "0.1.0-beta.3"
    When the template is synced
    Then the template names "@lapa/db" at "beta"

  Scenario: Sync rewrites a beta range to the tag
    Given the template already names "@lapa/db" at "^0.1.0-beta"
    And "@lapa/db" is published at "0.1.0-beta.6"
    When the template is synced
    Then the template names "@lapa/db" at "beta"

  Scenario: The tag stays as the line moves
    Given the template already names "@lapa/db" at "beta"
    And "@lapa/db" is published at "0.2.0-beta.1"
    When the template is synced
    Then the template names "@lapa/db" at "beta"

  Scenario: Leaving a beta line is a hand edit, and sync keeps it
    Given the template already names "@lapa/db" at "^0.1.0"
    And "@lapa/db" is published at "0.1.4" as "latest"
    When the template is synced
    Then the template names "@lapa/db" at "^0.1.4"

  Scenario: Sync reads every dependency, whichever section it is in
    When the template is synced
    Then the template names each dependency at a published version
      | dependency       | type           |
      | @lapa/db         | dependency     |
      | tilia            | dependency     |
      | @tilia/query     | dependency     |
      | @tilia/react     | dependency     |
      | react            | dependency     |
      | @lapa/server     | dev dependency |
      | @epure/dev       | dev dependency |
      | @epure/vitest    | dev dependency |
      | rescript         | dev dependency |
      | vite             | dev dependency |

  Scenario: Sync changes nothing but the versions
    When the template is synced
    Then the template still names the project "{{name}}"
    And the template still holds its scripts

  # ── Which version sync takes ───────────────────────────────────────────

  Scenario: Sync follows the line the template is on
    Given the template already names "tilia" at "beta"
    And "tilia" is published at "5.2.0" as "latest"
    And "tilia" is published at "6.0.0-beta.9" as "beta"
    When the template is synced
    Then the template names "tilia" at "beta"

  Scenario: A template on a release line takes the release
    Given the template already names "react" at "^19.2.0"
    And "react" is published at "19.2.3" as "latest"
    And "react" is published at "20.0.0-beta.1" as "beta"
    When the template is synced
    Then the template names "react" at "^19.2.3"

  Scenario: Sync takes what there is when the line it wants is empty
    Given the template already names "@lapa/db" at "^0.0.0"
    And "@lapa/db" is published at "0.1.0-beta.3" as "beta" only
    When the template is synced
    Then the template names "@lapa/db" at "beta"

  # ── Refusals ───────────────────────────────────────────────────────────

  Scenario: Sync refuses whole when a dependency is not published
    Given "@lapa/db" is published at "0.1.0-beta.3"
    And "@tilia/query" is not published
    When the template is synced
    Then sync fails and reports "@tilia/query"
    And the template is unchanged

  Scenario: Sync refuses whole when the registry does not answer
    Given the registry does not answer
    When the template is synced
    Then sync fails and reports the registry
    And the template is unchanged
