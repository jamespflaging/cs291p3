class MessagesController < ApplicationController

    before_action :authorize_jwt

    def create
        conversation = Conversation.find_by(id: params[:conversationId])
        unless conversation
            render json: { error: "Conversation not found" }, status: :not_found
            return
        end

        # Reload to ensure we have the latest data (in case it was just claimed)
        conversation.reload

        # Verify user is authorized to send messages to this conversation
        unless conversation.initiator_id == @current_user.id || conversation.assigned_expert_id == @current_user.id
            render json: { error: "Unauthorized" }, status: :forbidden
            return
        end

        message = conversation.messages.new(
        content: params[:content],
        sender: @current_user,
        sender_role: @current_user.id == conversation.initiator_id ? "initiator" : "expert"
        )

        if message.save
            render json: {
                id: message.id.to_s,
                conversationId: message.conversation_id.to_s,
                senderId: message.sender_id.to_s,
                senderUsername: message.sender.username,
                senderRole: message.sender_role,
                content: message.content,
                timestamp: message.created_at&.iso8601,
                isRead: message.is_read
            }, status: :created
        else
            render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
        end
    end


    # PUT /messages/:id/read
    def mark_read
        message = Message.find_by(id: params[:id])
        unless message
            render json: { error: "Message not found" }, status: :not_found #shouldn't trigger
            return
        end

        if message.sender_id == @current_user.id
            render json: { error: "Cannot mark your own messages as read" }, status: :forbidden
        else
            message.update(is_read: true)
            render json: { success: true }, status: :ok
        end
    end
end
