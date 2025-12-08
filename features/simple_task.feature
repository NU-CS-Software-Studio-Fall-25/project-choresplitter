Feature: Simple task creation
  In order to have tasks in a group
  As a user
  I want to be able to create a task

  Background:
    Given a chore group with a task group exists
    And I am signed in as a verified user
    And I am a member of that chore group

  Scenario: Create a new task
    When I create a simple task titled "Test Task"
    Then the task should exist in the task group
