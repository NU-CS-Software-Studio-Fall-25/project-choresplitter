Task.destroy_all
Member.destroy_all
ChoreGroup.destroy_all
User.destroy_all
TaskGroup.destroy_all

puts "Seeding data..."

# === Users ===
users = []
5.times do |i|
  users << User.create!(
    name: "User#{i + 1}",
    password: "password#{i + 1}"
  )
end
puts "✅ Created #{users.size} users"

# === ChoreGroups ===
chore_groups = []
5.times do |i|
  chore_groups << ChoreGroup.create!(
    name: "Chore Group #{i + 1}",
    admin_id: users.sample.id
  )
end
puts "✅ Created #{chore_groups.size} chore groups"

# === Members ===
members = []
chore_groups.each do |group|
  users.sample(3).each do |user|
    members << Member.create!(
      user: user,
      chore_group: group,
      role: ["member", "manager"].sample,
      points: rand(0..50)
    )
  end
end
puts "✅ Added #{members.count} members to groups"

# === TaskGroups ===
task_groups = []
chore_groups.each do |group|
  2.times do |i|
    task_groups << TaskGroup.create!(
      chore_group: group
    )
  end
end
puts "✅ Created #{task_groups.count} task groups"

# === Tasks ===
tasks = []
task_groups.each do |tg|
  3.times do |i|
    tasks << Task.create!(
      title: "Task #{i + 1} for #{tg.chore_group}",
      description: "This is an auto-generated task.",
      assignee: users.sample,
      task_group: tg
    )
  end
end
puts "✅ Created #{tasks.count} tasks."

puts "🎉 Seeding complete!"
