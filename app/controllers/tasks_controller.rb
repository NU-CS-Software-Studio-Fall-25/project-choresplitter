class TasksController < ApplicationController
  before_action :set_task, only: [:show, :edit, :update, :destroy]

  def index
    @tasks = Task
      .includes(:member, task_group: :chore_group) # eager-load to avoid N+1
      .order(created_at: :desc)

    if params[:task_group_id].present?
      @tasks = @tasks.where(task_group_id: params[:task_group_id])
    end

    if params[:member_id].present?
      @tasks = @tasks.where(member_id: params[:member_id])
    end
  end

  def show; end

  def new
    @task = Task.new
  end

  def create
    @task = Task.new(task_params)
    if @task.save
      redirect_to @task, notice: "Task created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @task.update(task_params)
      redirect_to @task, notice: "Task updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy
    redirect_to tasks_path, notice: "Task deleted."
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  # Strong params updated to match schema
  def task_params
    params.require(:task).permit(:title, :description, :member_id, :task_group_id)
  end
end

