Feature: epure-dev

  For Theo, running the app he just created, and the agent at the desk.

  `epure-dev` runs two processes as one: `lapa dev` on the data directory
  and vite on `src/`. Vite's port is the only one exposed, and the app
  answers on it. The proxy carries the wire, `/listen` and `/mcp` to
  `lapa dev` under `/_lapa/`, a prefix no app route can take, and passes
  `Authorization` through untouched: the browser's session on the wire,
  the founder's as bearer on `/_lapa/mcp`. Stopping dev stops both, and
  either process dying takes the other with it.

  Dev prints one link, and clicking it opens the app on the founder's
  session. `epure-dev` is the only process holding both halves, so it is the
  only one that can write that address.

  Background:
    Given a project created by init that nothing serves

  # ── One port ───────────────────────────────────────────────────────────

  Scenario: Dev serves the app
    When Theo runs dev
    Then the app page answers on the app port
    And dev prints the code

  Scenario: The wire answers under /_lapa/
    Given a running dev
    When a client pulls through "/_lapa/" with the founder's session
    Then the pull answers the boot's rows

  Scenario: The tools answer under /_lapa/mcp
    Given a running dev
    When the agent lists the tools at "/_lapa/mcp" with the founder's session
    Then the desk's tools answer

  Scenario: The proxy adds no session of its own
    Given a running dev
    When the agent lists the tools at "/_lapa/mcp" with no session
    Then the answer is a refusal

  # ── The link ───────────────────────────────────────────────────────────

  Scenario: Dev prints the app's address with the session in it
    When Theo runs dev
    Then dev prints one link
    And the link is the app page on the app port
    And the link carries the session as "lapa-session"

  Scenario: The link says http, so a terminal makes it clickable
    When Theo runs dev
    Then the link begins with "http://"

  Scenario: The link names the project
    When Theo runs dev
    Then the line holding the link names the project

  Scenario: The link answers the moment it is printed
    When Theo runs dev
    Then fetching the link answers the app page

  Scenario: The link carries the session lapa dev printed
    When Theo runs dev
    Then the link carries the session dev printed
    And a client pulling with that session answers the boot's rows

  # ── The loop ───────────────────────────────────────────────────────────

  Scenario: What the agent makes shows at once
    Given a running dev
    And a client listening through "/_lapa/"
    When the agent makes an entity at "/_lapa/mcp"
    Then the client hears a stamp
    And the client's pull answers the entity

  Scenario: An edit to the page compiles in dev
    Given a running dev
    When Theo changes the page's text to "Rebuilt by hand"
    Then the served page script says "Rebuilt by hand"

  # ── Stopping ───────────────────────────────────────────────────────────

  Scenario: Stopping dev stops both
    Given a running dev
    When Theo sends SIGTERM to dev
    Then dev exits with 0
    And the app port no longer answers
    And the data directory is free to serve again

  Scenario: A missing lapa binary is named, and nothing stays behind
    When Theo runs dev without a lapa binary
    Then dev exits and says lapa is missing
    And the compiler is not left running

  Scenario: A dead lapa takes dev down
    Given a running dev
    When lapa dev dies
    Then dev exits and says lapa stopped
    And the app port no longer answers
