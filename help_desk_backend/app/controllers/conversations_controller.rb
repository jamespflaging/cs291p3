class ConversationsController < ApplicationController
    before_action :authorize_jwt

    def get_all
        conversations = Conversation.where("initiator_id = ? OR assigned_expert_id = ?", @current_user.id, @current_user.id)
                      .includes(:initiator, :assigned_expert, :messages)
                      .order(updated_at: :desc)

        render json: conversations.map { |c| conversation_json(c) }, status: :ok
    end

    def create
        conversation = Conversation.new(
        title: params[:title],
        initiator_id: @current_user.id,
        status: "waiting"
        )

        if conversation.save
            render json: conversation_json(conversation), status: :created
        else
            render json: { errors: conversation.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def get_by_id
        conversation = Conversation.find_by(id: params[:id])
        
        if conversation #&& (conversation.initiator_id == @current_user.id || conversation.assigned_expert_id == @current_user.id)
            render json: conversation_json(conversation), status: :ok
        else
            render json: { error: "Conversation not found" }, status: 404
        end
    end


    def get_all_by_id
        conversation = Conversation.find_by(id: params[:conversation_id])

        if conversation #&& (conversation.initiator_id == @current_user.id || conversation.assigned_expert_id == @current_user.id)
            messages = conversation.messages.order(created_at: :asc)
            render json: messages.map { |m| 
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
            }, status: :ok
        else
            render json: { error: "Conversation not found" }, status: :not_found
        end
    end

    private

    def conversation_json(conversation)
        {
        id: conversation.id.to_s,
        title: conversation.title,
        status: conversation.status,
        questionerId: conversation.initiator_id.to_s,
        questionerUsername: conversation.initiator&.username,
        assignedExpertId: conversation.assigned_expert_id&.to_s,
        assignedExpertUsername: conversation.assigned_expert&.username,
        createdAt: conversation.created_at&.iso8601,
        updatedAt: conversation.updated_at&.iso8601,
        lastMessageAt: conversation.messages.last&.created_at&.iso8601,
        unreadCount: conversation.messages.where(is_read: false).where.not(sender_id: @current_user.id).count
        }
    end
end
