Feature: Login
  As a user
  I want to login to access the app
  So I can check my tasks and groups

  Background:
    Given I am a registered user
    And I am logged out

  Scenario: Logging in
    When I go to the login page
    And I type in my username and password
    And I click the login button
    Then I should see my dashboard with my task groups showing
