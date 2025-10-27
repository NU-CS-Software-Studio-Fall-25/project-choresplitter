class TasksController < ApplicationController
  before_action :set_chore_group
  before_action :set_task_group
  before_action :set_task, only: [:update, :destroy]

  def create
    attrs = params.fetch(:task, {}).permit(:title, :description)
    attrs[:title] = "New Task" if attrs[:title].blank?
    @task = @task_group.tasks.create(attrs)

    notice = @task.persisted? ? "Task created." : @task.errors.full_messages.to_sentence
    redirect_back fallback_location: chore_group_task_group_path(@chore_group, @task_group),
                  notice: notice, status: :see_other
  end

  def update
    # You can also permit :title/:description if you want edits here too
    if @task.update(params.require(:task).permit(:member_id))
      redirect_back fallback_location: chore_group_task_group_path(@chore_group, @task_group),
                    notice: "Assignee updated.", status: :see_other
    else
      redirect_back fallback_location: chore_group_task_group_path(@chore_group, @task_group),
                    alert: @task.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def destroy
    @task.destroy
    redirect_back fallback_location: chore_group_task_group_path(@chore_group, @task_group),
                  notice: "Task deleted.", status: :see_other
  end

  private
  def set_chore_group
    @chore_group = ChoreGroup.find(params[:chore_group_id])
  end

  def set_task_group
    @task_group = @chore_group.task_groups.find(params[:task_group_id])
  end

  def set_task
    @task = @task_group.tasks.find(params[:id])
  end
end
