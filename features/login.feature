Feature: Login
    As a user
    I want to login to access the app
    So I can check my tasks and groups

Background:
    Given I am a registered user
    I am logged out

Scenario: Logging in
    I go to the login page
    I type in my username and password
    I click the login button
    I should see the my dashboard with my task groups showing