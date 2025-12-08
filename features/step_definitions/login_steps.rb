# features/step_definitions/login_steps.rb

Given('I am a registered user') do
  @user = User.create!(
    email_address: 'testuser@example.com',
    password: 'Password!',
    password_confirmation: 'Password!',
    # Your SessionsController requires the user to be verified to log in
    email_verified_at: Time.current
  )
end

Given('I am logged out') do
  # Visiting the login page in a fresh Capybara session is effectively "logged out"
  visit new_session_path
end

When('I go to the login page') do
  visit new_session_path
end

When('I type in my username and password') do
  fill_in 'Email', with: @user.email_address
  fill_in 'Password', with: 'Password!'
end

When('I click the login button') do
  # Adjust the button text if your view uses something else, e.g. "Sign In" or "Log in"
  click_button 'Sign in'
end

Then('I should see my dashboard with my task groups showing') do
  # After SessionsController#create succeeds, you redirect_to users_path
  expect(current_path).to eq(users_path)

  # Your users#index view has this heading:
  #   <h2>My Chore Groups</h2>
  expect(page).to have_content('My Chore Groups')
end
