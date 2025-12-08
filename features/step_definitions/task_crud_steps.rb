Given("I create a simple task titled {string}") do |title|
  @task_count_before = Task.count

  @task = @task_group.tasks.create!(
    title: title,
    description: "Simple test task",
    point_value: 5,
    member: @member
  )
end

Then("the task should exist in the task group") do
  expect(Task.count).to eq(@task_count_before + 1)
  expect(@task_group.tasks).to include(@task)
end
