# spec/controllers/tasks_controller_gamification_spec.rb
require "rails_helper"

RSpec.describe TasksController, type: :controller do
  let(:user) { instance_double(User, id: 1) }

  before do
    # Pretend the user is logged in
    allow(controller).to receive(:current_user).and_return(user)

    # Bypass global auth filters (require_login / require_authentication)
    # even if they don't exist, `allow(...).to receive` will define stubs.
    allow(controller).to receive(:require_login).and_return(true)
    allow(controller).to receive(:require_authentication).and_return(true)

    # So redirect_back uses this instead of fallback_location
    request.env["HTTP_REFERER"] = "/back"
  end

  describe "PATCH #complete" do
    it "marks the task complete and increments member points when state is not completed" do
      member = instance_double("Member")
      task   = instance_double(
        "Task",
        id: 123,
        member: member,
        point_value: 10
      )

      # state BEFORE transition
      allow(task).to receive(:state).and_return("open")
      allow(Task).to receive(:find).with("123").and_return(task)
      allow(task).to receive(:complete!)
      allow(member).to receive(:increment!)

      patch :complete, params: { id: "123" }

      expect(task).to have_received(:complete!)
      expect(member).to have_received(:increment!).with(:points, 10)
      expect(response).to redirect_to("/back")
      expect(flash[:notice]).to eq("Task marked as completed.")
    end

    it "does NOT call complete! or increment points if task is already completed" do
      member = instance_double("Member")
      task   = instance_double(
        "Task",
        id: 124,
        member: member,
        point_value: 10
      )

      allow(task).to receive(:state).and_return("completed")
      allow(Task).to receive(:find).with("124").and_return(task)

      expect(task).not_to receive(:complete!)
      expect(member).not_to receive(:increment!)

      patch :complete, params: { id: "124" }

      expect(response).to redirect_to("/back")
      expect(flash[:notice]).to eq("Task marked as completed.")
    end

    it "does not change points if the task has no member" do
      task = instance_double(
        "Task",
        id: 125,
        member: nil,
        point_value: 10
      )

      allow(task).to receive(:state).and_return("open")
      allow(Task).to receive(:find).with("125").and_return(task)
      allow(task).to receive(:complete!)

      patch :complete, params: { id: "125" }

      expect(task).to have_received(:complete!)
      # no member => nothing to increment, just ensure no error
    end

    it "does not increment points if point_value is nil or non-positive" do
      member = instance_double("Member")
      task   = instance_double(
        "Task",
        id: 126,
        member: member,
        point_value: 0
      )

      allow(task).to receive(:state).and_return("open")
      allow(Task).to receive(:find).with("126").and_return(task)
      allow(task).to receive(:complete!)

      expect(member).not_to receive(:increment!)

      patch :complete, params: { id: "126" }

      expect(task).to have_received(:complete!)
    end
  end

  describe "PATCH #reopen" do
    it "decrements member points (by point_value) and reopens when state is completed" do
      member = instance_double("Member", points: 50)
      task   = instance_double(
        "Task",
        id: 200,
        member: member,
        point_value: 20
      )

      allow(task).to receive(:state).and_return("completed")
      allow(Task).to receive(:find).with("200").and_return(task)
      allow(task).to receive(:reopen!)
      allow(member).to receive(:decrement!)

      patch :reopen, params: { id: "200" }

      expect(member).to have_received(:decrement!).with(:points, 20)
      expect(task).to have_received(:reopen!)
      expect(response).to redirect_to("/back")
      expect(flash[:notice]).to eq("Task reopened.")
    end

    it "never makes points go below zero (uses min of point_value and member.points)" do
      member = instance_double("Member", points: 5)
      task   = instance_double(
        "Task",
        id: 201,
        member: member,
        point_value: 10
      )

      allow(task).to receive(:state).and_return("completed")
      allow(Task).to receive(:find).with("201").and_return(task)
      allow(task).to receive(:reopen!)
      allow(member).to receive(:decrement!)

      patch :reopen, params: { id: "201" }

      # points_to_remove = min(10, 5) => 5
      expect(member).to have_received(:decrement!).with(:points, 5)
      expect(task).to have_received(:reopen!)
    end

    it "does not decrement points if the task is not completed" do
      member = instance_double("Member", points: 100)
      task   = instance_double(
        "Task",
        id: 202,
        member: member,
        point_value: 10
      )

      allow(task).to receive(:state).and_return("open")
      allow(Task).to receive(:find).with("202").and_return(task)

      expect(member).not_to receive(:decrement!)
      expect(task).not_to receive(:reopen!)

      patch :reopen, params: { id: "202" }

      expect(response).to redirect_to("/back")
      expect(flash[:notice]).to eq("Task reopened.")
    end

    it "does nothing to points if there is no member" do
      task = instance_double(
        "Task",
        id: 203,
        member: nil,
        point_value: 10
      )

      allow(task).to receive(:state).and_return("completed")
      allow(Task).to receive(:find).with("203").and_return(task)
      allow(task).to receive(:reopen!)

      patch :reopen, params: { id: "203" }

      expect(task).to have_received(:reopen!)
      # no member => no decrement call to assert
    end

    it "does not decrement points if point_value is nil or non-positive" do
      member = instance_double("Member", points: 50)
      task   = instance_double(
        "Task",
        id: 204,
        member: member,
        point_value: 0
      )

      allow(task).to receive(:state).and_return("completed")
      allow(Task).to receive(:find).with("204").and_return(task)
      allow(task).to receive(:reopen!)
      expect(member).not_to receive(:decrement!)

      patch :reopen, params: { id: "204" }

      expect(task).to have_received(:reopen!)
    end
  end
end
