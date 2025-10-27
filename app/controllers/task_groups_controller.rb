class TaskGroupsController < ApplicationController
  before_action :set_chore_group
  before_action :set_task_group

  def show; end

  private
  def set_chore_group
    @chore_group = ChoreGroup.find(params[:chore_group_id])
  end

  def set_task_group
    @task_group = @chore_group.task_groups.find(params[:id])
  end
end