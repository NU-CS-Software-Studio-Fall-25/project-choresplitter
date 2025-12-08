# features/step_definitions/task_creation_steps.rb

require 'capybara'
require 'capybara/rails'

module TaskCreationPathHelpers
  def default_url_options
    {}
  end
end

World(TaskCreationPathHelpers)
World(Rails.application.routes.url_helpers)

Given('a chore group with a task group exists') do
  # Admin/owner of the group
  @chore_group_admin ||= User.create!(
    email_address: 'owner@example.com',
    password: 'Password!1',
    password_confirmation: 'Password!1',
    email_verified_at: Time.current
  )

  @chore_group ||= ChoreGroup.create!(
    name: 'Test Group',
    code: 'ABCDE',
    admin: @chore_group_admin,
    admin_name: 'Owner'
  )

  @task_group ||= @chore_group.task_groups.create!
end

Given('I am signed in as a verified user') do
  @user ||= User.create!(
    email_address: 'taskuser@example.com',
    password: 'Password!1',
    password_confirmation: 'Password!1',
    email_verified_at: Time.current
  )

  # Log in via SessionsController#create
  page.driver.post(
    session_path,
    {
      session: {
        email_address: @user.email_address,
        password: 'Password!1'
      }
    }
  )
end

Given('I am a member of that chore group') do
  raise 'No chore group defined' unless @chore_group
  raise 'No current user defined' unless @user

  @member ||= Member.create!(
    chore_group: @chore_group,
    user: @user,
    name: 'Task User',
    role: 'member',
    points: 0
  )
end

Given('I am not signed in') do
  # Usually a fresh scenario means a fresh session; this can remain a no-op
  visit root_path rescue nil
end

When('I submit a new task directly via POST') do
  @task_count_before = Task.count

  url = chore_group_task_group_tasks_path(@chore_group, @task_group)

  page.driver.post(
    url,
    {
      task: {
        title: 'Cucumber Task',
        description: 'Created via Cucumber',
        point_value: 10
      }
    }
  )

  @last_response = page.driver.response
end

Then('a task should be created in that task group') do
  expect(Task.count).to eq(@task_count_before + 1)

  created = Task.where(
    task_group: @task_group,
    title: 'Cucumber Task'
  ).first

  expect(created).not_to be_nil
end

Then('I should be redirected to the login page') do
  # We didn't auto-follow the redirect, so we inspect the raw Rack response
  status = @last_response.status
  expect(status).to be_between(300, 399).inclusive

  # Location might be full URL (http://test.host/session/new)
  location = @last_response.headers['Location'] || @last_response.location
  expect(location).to include(new_session_path)
end

Then('no new task should be created') do
  expect(Task.count).to eq(@task_count_before)
end
