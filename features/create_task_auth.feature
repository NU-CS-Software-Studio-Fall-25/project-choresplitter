Feature: Task creation authentication
  In order to manage chores
  As a user
  I want task creation to require login

  Background:
    Given a chore group with a task group exists

  Scenario: Authenticated user can create a task
    Given I am signed in as a verified user
    And I am a member of that chore group
    When I submit a new task directly via POST
    Then a task should be created in that task group

  Scenario: Unauthenticated user cannot create a task
    Given I am not signed in
    When I submit a new task directly via POST
    Then I should be redirected to the login page
    And no new task should be created
