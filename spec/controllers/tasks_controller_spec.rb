# spec/controllers/tasks_controller_spec.rb
require "rails_helper"

RSpec.describe TasksController, type: :controller do
  let!(:user) { create(:user) }
  let!(:chore_group) { create(:chore_group, code: "ABCDE", admin: user) }
  let!(:task_group) { create(:task_group, chore_group: chore_group) }
  let!(:member) { create(:member, chore_group: chore_group, user: user) }
  let!(:task) { create(:task, task_group: task_group, member: member, title: "Sample Task") }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:require_login).and_return(true)
    allow(controller).to receive(:require_authentication).and_return(true)
    request.env["HTTP_REFERER"] = "/back"
  end

  describe "POST #create" do
    it "creates a new task with given attributes" do
      expect {
        post :create, params: {
          chore_group_id: chore_group.code,
          task_group_id: task_group.id,
          task: { title: "Test Task" }
        }
      }.to change { task_group.tasks.count }.by(1)
    end

    it "defaults title to 'New Task' if blank" do
      expect {
        post :create, params: {
          chore_group_id: chore_group.code,
          task_group_id: task_group.id,
          task: { title: "" }
        }
      }.to change { task_group.tasks.count }.by(1)
      expect(Task.last.title).to eq("New Task")
    end
  end

  describe "PATCH #update" do
  let(:user) { create(:user) }
  let(:chore_group) { create(:chore_group, admin: user) }
  let(:task_group) { create(:task_group, chore_group: chore_group) }
  let(:member) { create(:member, chore_group: chore_group, user: user) }
  let(:new_member) { create(:member, chore_group: chore_group) }
  let(:task) { create(:task, task_group: task_group, member: member) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    request.env["HTTP_REFERER"] = nil # Ensure fallback_location is used
  end

  it "updates the assignee successfully" do
    patch :update, params: { chore_group_id: chore_group.code,
                             task_group_id: task_group.id,
                             id: task.id,
                             task: { member_id: new_member.id } }

    expect(task.reload.member_id).to eq(new_member.id)
    expect(flash[:notice]).to eq("Assignee updated.")
    expect(response).to redirect_to(chore_group_task_group_path(chore_group, task_group))
  end

  it "redirects with errors if update fails" do
    # Force update to fail by stubbing `update`
    allow_any_instance_of(Task).to receive(:update).and_return(false)
    allow_any_instance_of(Task).to receive_message_chain(:errors, :full_messages).and_return([ "Failed to update" ])

    patch :update, params: { chore_group_id: chore_group.code,
                            task_group_id: task_group.id,
                            id: task.id,
                            task: { member_id: new_member.id } } # valid member_id

    expect(flash[:alert]).to eq("Failed to update")
    expect(response).to redirect_to(chore_group_task_group_path(chore_group, task_group))
  end
end

  describe "DELETE #destroy" do
    it "deletes the task" do
      expect {
        delete :destroy, params: {
          chore_group_id: chore_group.code,
          task_group_id: task_group.id,
          id: task.id
        }
      }.to change { task_group.tasks.count }.by(-1)
      expect(flash[:notice]).to eq("Task deleted.")
    end
  end

  describe "GET #index" do
    it "lists open tasks for current user's members" do
      get :index, params: { chore_group_id: chore_group.code }
      expect(response).to have_http_status(:ok)
      expect(assigns(:tasks)).to include(task)
    end
  end

  describe "GET #completed" do
    let!(:completed_task) { create(:task, task_group: task_group, member: member, state: "completed") }

    it "lists completed tasks for current user's members" do
      get :completed
      expect(response).to have_http_status(:ok)
      expect(assigns(:tasks)).to include(completed_task)
    end
  end
end
