class UpdatesController < ApplicationController
  before_action :authorize_jwt

  def conversations
    since = params[:since].presence && Time.parse(params[:since]) rescue nil

    conversations = Conversation
      .where("initiator_id = ? OR assigned_expert_id = ?", @current_user.id, @current_user.id)
    
    if since
      conversations = conversations.left_joins(:messages)
        .where("conversations.updated_at > ? OR messages.created_at > ?", since, since)
        .distinct
    end
    
    conversations = conversations.includes(:initiator, :assigned_expert, :messages)

    render json: conversations.map { |c|
      {
        id: c.id.to_s,
        title: c.title,
        status: c.status,
        questionerId: c.initiator_id.to_s,
        questionerUsername: c.initiator&.username,
        assignedExpertId: c.assigned_expert_id&.to_s,
        assignedExpertUsername: c.assigned_expert&.username,
        createdAt: c.created_at&.iso8601,
        updatedAt: c.updated_at&.iso8601,
        lastMessageAt: c.messages.last&.created_at&.iso8601
      }
    }
  end

  def messages
    since = params[:since].presence && Time.parse(params[:since]) rescue nil

    msgs = Message.joins(:conversation)
      .where("conversations.initiator_id = ? OR conversations.assigned_expert_id = ?", @current_user.id, @current_user.id)
    msgs = msgs.where("messages.created_at > ?", since) if since
    msgs = msgs.includes(:sender)

    render json: msgs.map { |m|
      {
        id: m.id.to_s,
        conversationId: m.conversation_id.to_s,
        senderId: m.sender_id.to_s,
        senderUsername: m.sender.username,
        senderRole: m.sender_role,
        content: m.content,
        timestamp: m.created_at&.iso8601,
        isRead: m.is_read
      }
    }
  end

  def expert_queue
    return render json: { error: "Forbidden" }, status: 403 unless @current_user.expert_profile

    since = params[:since].presence && Time.parse(params[:since]) rescue nil

    waiting  = Conversation.where(status: "waiting").where.not(initiator_id: @current_user.id).includes(:initiator, :assigned_expert, :messages)
    assigned = Conversation.where(assigned_expert_id: @current_user.id).includes(:initiator, :assigned_expert, :messages)

    if since
      waiting = waiting.left_joins(:messages)
        .where("conversations.created_at > ? OR conversations.updated_at > ? OR messages.created_at > ?", since, since, since)
        .distinct
      
      assigned = assigned.left_joins(:messages)
        .where("conversations.created_at > ? OR conversations.updated_at > ? OR messages.created_at > ?", since, since, since)
        .distinct
    end

    render json: [{
      waitingConversations: waiting.map { |c|
        {
          id: c.id.to_s,
          title: c.title,
          status: c.status,
          questionerId: c.initiator_id.to_s,
          questionerUsername: c.initiator&.username,
          assignedExpertId: c.assigned_expert_id&.to_s,
          assignedExpertUsername: c.assigned_expert&.username,
          createdAt: c.created_at&.iso8601,
          updatedAt: c.updated_at&.iso8601,
          lastMessageAt: c.messages.last&.created_at&.iso8601
        }
      },
      assignedConversations: assigned.map { |c|
        {
          id: c.id.to_s,
          title: c.title,
          status: c.status,
          questionerId: c.initiator_id.to_s,
          questionerUsername: c.initiator&.username,
          assignedExpertId: c.assigned_expert_id&.to_s,
          assignedExpertUsername: c.assigned_expert&.username,
          createdAt: c.created_at&.iso8601,
          updatedAt: c.updated_at&.iso8601,
          lastMessageAt: c.messages.last&.created_at&.iso8601
        }
      }
    }]
  end
end
