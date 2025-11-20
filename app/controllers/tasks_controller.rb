class TasksController < ApplicationController
  before_action :set_chore_group, if: -> { params[:chore_group_id].present? }
  before_action :set_task_group,  if: -> { params[:task_group_id].present? }
  before_action :set_task, only: [ :update, :destroy, :complete, :reopen ]

  def complete
    @task.complete!
    redirect_back fallback_location: tasks_path, notice: "Task marked as completed."
  end

  def reopen
    @task.reopen!
    redirect_back fallback_location: tasks_path, notice: "Task reopened."
  end

  def completed
    my_member_ids = current_user.members.select(:id)

    @tasks = Task
      .where(member_id: my_member_ids, state: "completed")
      .includes(task_group: :chore_group)
      .order(completed_at: :desc)

    @pagy, @tasks = pagy(@tasks, items: 10)
  end

  def index
    my_member_ids = current_user.members.select(:id)

    if params[:chore_group_id].present?
      @chore_group = ChoreGroup.find_by!(code: params[:chore_group_id])

      current_member = @chore_group.members.find_by(user_id: current_user.id)

      # Only tasks in this group assigned to ME
      @tasks = @chore_group.tasks
                          .where(state: "open", member_id: current_member&.id)
    else
      # All open tasks assigned to me across ALL groups
      @tasks = Task
        .where(state: "open", member_id: my_member_ids)
        .joins(task_group: :chore_group)
    end

    @tasks = @tasks.includes(task_group: :chore_group).order(due_date: :asc)
    @pagy, @tasks = pagy(@tasks, items: 10)
  end

  def create
    attrs = params.fetch(:task, {}).permit(:title, :description, :due_date)
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
    @chore_group = ChoreGroup.find_by!(code: params[:chore_group_id])
  end

  def set_task_group
    @task_group = @chore_group.task_groups.find(params[:task_group_id])
  end

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :member_id, :due_date)
  end
end
