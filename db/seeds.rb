# db/seeds.rb
require 'faker'

puts "🌱 Seeding data..."

# Clear existing data
Task.destroy_all
TaskGroup.destroy_all
Member.destroy_all
ChoreGroup.destroy_all
User.destroy_all
puts "Cleared old data."

# 1. Create users
puts "Creating users..."
first_names = []
100.times do
  name = Faker::Name.unique.first_name
  first_names << name
end

users = first_names.map do |name|
  User.create!(
    email_address: "#{name.downcase}@example.com",
    password: "90!PassWord!90",
    password_confirmation: "90!PassWord!90"
  )
end
puts "Created #{users.count} users."

# 2. Create chore groups
puts "Creating chore groups..."
chore_groups = 100.times.map do
  admin_user = users.sample
  ChoreGroup.create!(
    name: Faker::Company.unique.name,
    admin: admin_user,
    admin_name: admin_user.email_address.split('@')[0].capitalize
  )
end
puts "Created #{chore_groups.count} chore groups."

# 3. Create members for each group
puts "Creating members for each group..."
chore_groups.each do |group|
  users_to_add = users.reject { |u| u.id == group.admin_id }

  # Admin member record
  Member.create!(user: group.admin, chore_group: group, role: 'admin', name: group.admin_name)

  # 10 random members per group
  users_to_add.sample(10).each do |user|
    Member.create!(user: user, chore_group: group, role: 'member', name: Faker::Name.unique.first_name)
  end
end
puts "Memberships created."

# 4. Add Task Groups to each Chore Group
puts "Creating task groups..."
task_group_names = 100.times.map { Faker::Educator.subject }

chore_groups.each do |group|
  task_group_names.sample(1).each do |name|
    TaskGroup.create!(chore_group: group)
  end
end
puts "Task groups created."

# 5. Add Tasks to each Task Group
puts "Creating tasks..."
task_titles = 100.times.map { Faker::Lorem.sentence(word_count: rand(3..6)) }

TaskGroup.all.each do |task_group|
  members_in_group = task_group.chore_group.members

  20.times do
    # Randomly pick task state: mostly pending
    state = rand < 0.8 ? "open" : "completed"
    completed_at = state == "completed" ? Faker::Time.backward(days: 30) : nil

    Task.create!(
      title: task_titles.sample,
      task_group: task_group,
      member: members_in_group.sample,
      state: state,
      completed_at: completed_at,
      due_date: Faker::Date.forward(days: rand(1..30)) # optional due date in the future
    )
  end
end
puts "Tasks created."

puts "✅ Done seeding."
