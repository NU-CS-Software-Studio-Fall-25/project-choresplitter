# db/seeds.rb
require 'faker'
require 'rubygems'

puts "🌱 Seeding data..."
# Clear existing data to prevent duplicates on re-seed
Task.destroy_all
TaskGroup.destroy_all
Member.destroy_all
ChoreGroup.destroy_all
User.destroy_all
puts "Cleared old data."

# 1. Create all your users.
puts "Creating users..."
puts "Creating users..."

# 1. Define an array with the list of lowercase first names.
first_names = []
#   "kevin",
#   "elizabeth",
#   "david",
#   "maria",
#   "james",
#   "sally",
#   "michael",
#   "patricia"
# ]
# #using facker to generate data
100.times.map do
  name = Faker::Name.unique.first_name
  first_names << name
end
# puts first_names
# 2. Loop through the array to create a user for each name.
users = first_names.map do |name|
  User.create!(
    # The email is generated directly from the simple name
    email_address: "#{name}@example.com",
    password: "password",
    password_confirmation: "password"
  )
end

puts "Created #{users.count} users."

# 2. Create chore groups with random admins.
puts "Creating chore groups..."
chore_groups = 100.times.map do
  ChoreGroup.create!(
    name: Faker::Company.unique.name,
    admin: users.sample # Assigns the full user object
  )
end
puts "Created #{chore_groups.count} chore groups."

# 3. Create Members for each group. This is crucial for creating tasks later.
puts "Creating members for each group..."
chore_groups.each do |group|
  # Find users not already the admin for this group
  users_to_add = users.reject { |user| user.id == group.admin_id }

  # Create the admin's own member record
  Member.create!(user: group.admin, chore_group: group, role: 'admin')

  # Create member records for 3 other random users
  users_to_add.sample(10).each do |user|
    Member.create!(user: user, chore_group: group, role: 'member')
  end
end
puts "Memberships created."

# 4. Add Task Groups to each Chore Group.

puts "Creating task groups..."
task_group_names = []
100.times.map do
  name = Faker::Educator.subject
  task_group_names << name
end

chore_groups.each do |group|
  task_group_names.sample(10).each do |name| # Add 10 random task groups to each chore group
    TaskGroup.create!(chore_group: group)
  end
end
puts "Task groups created."

# 5. Add Tasks to each Task Group, assigned to a random member of that group.
puts "Creating tasks..."
task_titles = []
100.times.map do
  name = Faker::Lorem.sentence
  task_titles << name
end

TaskGroup.all.each do |task_group|
  # Get the members belonging to this task group's parent chore group
  members_in_group = task_group.chore_group.members

  # Create 20 random tasks and assign them to members of the group
  20.times do
    Task.create!(
      title: task_titles.sample,
      task_group: task_group,
      member: members_in_group.sample # Assign to a random member
    )
  end
end
puts "Tasks created."


puts "✅ Done seeding."
