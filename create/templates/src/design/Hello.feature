Feature: Hello

  For whoever reads this scaffold first.

  The app's rules live in `Hello`, a carve over `Notes.t`. `Notes.t` is the
  seam: the mount fills it in over a lapa client, and this file fills it in
  over an array. So every rule below is proven with no server, no client and
  no browser — which is the reason the seam is there. Write the next feature
  the same way, and delete this one with `Hello.res`.

  Background:
    Given the notes "Alpine lake, Camp fire, Blue lake"

  # ── Reading ────────────────────────────────────────────────────────────

  Scenario: The app shows the notes it is given
    Then the app shows "Alpine lake, Camp fire, Blue lake"
    And the app counts 3 notes

  Scenario: The filter narrows what is shown
    When the filter is "la"
    Then the app shows "Alpine lake, Blue lake"

  Scenario: The filter does not narrow the count
    When the filter is "la"
    Then the app counts 3 notes

  Scenario: The filter ignores case and surrounding space
    When the filter is "  CAMP  "
    Then the app shows "Camp fire"

  Scenario: An app whose notes have not answered is not ready
    Given the notes have not answered
    Then the app is not ready

  # ── Opening ────────────────────────────────────────────────────────────

  Scenario: Opening a note carries its title into the draft
    When "Camp fire" is opened
    Then the note open is "Camp fire"
    And the draft says "Camp fire"

  Scenario: Opening the note that is open shuts it
    Given "Camp fire" is opened
    When "Camp fire" is opened
    Then no note is open

  Scenario: Opening another note carries the other title in
    Given "Camp fire" is opened
    When "Blue lake" is opened
    Then the draft says "Blue lake"

  # ── Renaming ───────────────────────────────────────────────────────────

  Scenario: A rename saves the draft
    Given "Camp fire" is opened
    And the draft is "Camp lake"
    When the rename is saved
    Then "Camp lake" was saved

  Scenario: A rename shows at once
    Given "Camp fire" is opened
    And the draft is "Camp lake"
    When the rename is saved
    Then the app shows "Alpine lake, Camp lake, Blue lake"

  Scenario: A draft that changes nothing saves nothing
    Given "Camp fire" is opened
    And the draft is "  Camp fire  "
    When the rename is saved
    Then nothing was saved

  Scenario: An empty draft saves nothing
    Given "Camp fire" is opened
    And the draft is "   "
    When the rename is saved
    Then nothing was saved

  Scenario: A rename with no note open saves nothing
    Given the draft is "Camp lake"
    When the rename is saved
    Then nothing was saved

  # ── Adding ─────────────────────────────────────────────────────────────

  Scenario: Adding a note hands the title over
    Given the add box holds "Via ferrata"
    When the note is added
    Then "Via ferrata" was added

  Scenario: Adding a note clears the box
    Given the add box holds "Via ferrata"
    When the note is added
    Then the add box is empty

  Scenario: An add box holding only space adds nothing
    Given the add box holds "   "
    When the note is added
    Then nothing was added

  # ── Waiting ────────────────────────────────────────────────────────────

  Scenario: The app is saving while a write is on its way
    When 2 writes are on their way
    Then the app is saving

  Scenario: The app is not saving once they have landed
    Given 2 writes are on their way
    When 0 writes are on their way
    Then the app is not saving
