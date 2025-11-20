class InvitationsController < ApplicationController
  before_action :set_chore_group, only: [:create]
  before_action :ensure_group_admin!, only: [:create]

  # GET /invitations
  # "Inbox" – invitations for the current user
  def index
    @invitations = current_user
      .received_invitations
      .includes(:chore_group, :sender)
      .order(created_at: :desc)
  end

  # POST /chore_groups/:chore_group_id/invitations
  def create
    email = params.dig(:invitation, :email).to_s.strip.downcase

    recipient = User.find_by(email_address: email)
    unless recipient
      redirect_to chore_group_path(@chore_group, tab: "admin"),
                  alert: "No user found with email #{email}." and return
    end

    if @chore_group.members.exists?(user_id: recipient.id)
      redirect_to chore_group_path(@chore_group, tab: "admin"),
                  alert: "That user is already a member of this group." and return
    end

    invite = @chore_group.invitations.find_or_initialize_by(
      sender: current_user,
      recipient: recipient,
      status: "pending"
    )

    if invite.persisted?
      redirect_to chore_group_path(@chore_group, tab: "admin"),
                  notice: "An invitation is already pending for that user." and return
    end

    if invite.save
      redirect_to chore_group_path(@chore_group, tab: "admin"),
                  notice: "Invitation sent to #{email}."
    else
      redirect_to chore_group_path(@chore_group, tab: "admin"),
                  alert: invite.errors.full_messages.to_sentence
    end
  end

  # PATCH /invitations/:id
  # params[:decision] in ["accept", "decline"]
  def update
    invitation = current_user.received_invitations.find(params[:id])

    case params[:decision]
    when "accept"
      invitation.update!(status: "accepted")

      # Send them to the join page instead
      redirect_to search_chore_groups_path(
                    search_code: invitation.chore_group.code
                  ),
                  notice: "You accepted the invite to '#{invitation.chore_group.name}'. Review the group and join from there."

    when "decline"
      invitation.update!(status: "declined")
      redirect_to invitations_path, notice: "Invitation declined."

    else
      redirect_to invitations_path, alert: "Unknown action."
    end
  end

  private

  def set_chore_group
    identifier = params[:chore_group_id].presence || params[:code].presence
    @chore_group = ChoreGroup.find_by!(code: identifier)
  rescue ActiveRecord::RecordNotFound
    redirect_to chore_groups_path, alert: "That chore group no longer exists."
  end

  def ensure_group_admin!
    unless @chore_group.admin_id == current_user.id
      redirect_to chore_group_path(@chore_group),
                  alert: "Only the group admin can send invitations." and return
    end
  end
end
