Task.destroy_all
TaskGroup.destroy_all
Member.destroy_all
ChoreGroup.destroy_all
User.destroy_all

puts "Seeding data..."

# # === Users ===
# users = []
# 5.times do |i|
#   users << User.create!(
#     name: "User#{i + 1}",
#     password: "password#{i + 1}"
#   )
# end
# puts "✅ Created #{users.size} users"

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
      role: %w[member manager].sample,
      points: rand(0..50)
    )
  end
end
puts "✅ Added #{members.count} members to groups"

# === TaskGroups ===
task_groups = []
chore_groups.each do |group|
  2.times do
    task_groups << TaskGroup.create!(chore_group: group)
  end
end
puts "✅ Created #{task_groups.count} task groups"

# Pre-group members by chore_group_id for fast lookups
members_by_group = members.group_by(&:chore_group_id)

# === Tasks ===
tasks = []
task_groups.each do |tg|
  eligible = members_by_group[tg.chore_group_id] || []

  # Fallback: if no member exists yet for this group (shouldn't happen), create one
  if eligible.empty?
    fallback_user = users.sample
    eligible << Member.create!(
      user: fallback_user,
      chore_group_id: tg.chore_group_id,
      role: "member",
      points: 0
    )
  end

  3.times do |i|
    assignee_member = eligible.sample
    tasks << Task.create!(
      title: "Task #{i + 1} for #{ChoreGroup.find(tg.chore_group_id).name}",
      description: "This is an auto-generated task.",
      member: assignee_member,   # ← assign via association to guarantee presence
      task_group: tg
    )
  end
end
puts "✅ Created #{tasks.count} tasks."

puts "🎉 Seeding complete!"
