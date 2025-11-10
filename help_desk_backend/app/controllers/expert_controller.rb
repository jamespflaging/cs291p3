class ExpertController < ApplicationController
    before_action :authorize_jwt

    def get_queue
        waiting = Conversation.where(status: "waiting").where.not(initiator_id: @current_user.id).includes(:initiator, :assigned_expert, :messages)
        assigned = Conversation.where(assigned_expert_id: @current_user.id).includes(:initiator, :assigned_expert, :messages)

        render json: {
            waitingConversations: waiting.map { |c| conversation_json(c) },
            assignedConversations: assigned.map { |c| conversation_json(c) } }, status: :ok
    end

    def claim
        conversation = Conversation.find_by(id: params[:conversation_id])
        unless conversation
            render json: { error: "Conversation not found" }, status: :not_found
            return
        end

        if conversation.assigned_expert_id.present?
            render json: { error: "Conversation is already assigned to an expert" }, status: :unprocessable_entity
        else
            conversation.update(assigned_expert_id: @current_user.id, status: "active")
            conversation.reload 
            render json: { success: true }, status: :ok
        end
    end

    def unclaim
        conversation = Conversation.find_by(id: params[:conversation_id])
        unless conversation
            render json: { error: "Conversation not found" }, status: :not_found
            return
        end

        if conversation.assigned_expert_id != @current_user.id
            render json: { error: "You are not assigned to this conversation" }, status: :forbidden
        else
            conversation.update(assigned_expert_id: nil, status: "waiting")
            render json: { success: true }, status: :ok
        end
    end

    def get_profile
        profile = @current_user.expert_profile
        unless profile
            render json: { error: "Expert profile not found" }, status: :not_found
            return
        end
        
        render json: { 
            id: profile.id.to_s,
            userId: @current_user.id.to_s,
            bio: profile.bio || "",
            knowledgeBaseLinks: profile.knowledge_base_links || [],
            createdAt: profile.created_at&.iso8601,
            updatedAt: profile.updated_at&.iso8601 
        }, status: :ok
    end

    def update_profile
        profile = @current_user.expert_profile
        unless profile
            render json: { error: "Expert profile not found" }, status: :not_found
            return
        end
        
        if profile.update(bio: params[:bio], knowledge_base_links: params[:knowledgeBaseLinks])
            links = profile.knowledge_base_links
            links = [] if links.nil?
            links = links.to_a if links.is_a?(Hash)
            
            render json: {
                id: profile.id.to_s,
                userId: @current_user.id.to_s,
                bio: profile.bio || "",
                knowledgeBaseLinks: links,
                createdAt: profile.created_at&.iso8601,
                updatedAt: profile.updated_at&.iso8601
            }, status: :ok
        else
            render json: { errors: profile.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def assignment_history
        profile = @current_user.expert_profile
        unless profile
            render json: { error: "Expert profile not found" }, status: :not_found
            return
        end
        
        assignments = ExpertAssignment.where(expert_id: profile.id)

        render json: assignments.map { |assignment|
            {
            id: assignment.id.to_s,
            conversationId: assignment.conversation&.id.to_s, 
            expertId: assignment.expert_id.to_s,
            status: assignment.status,
            assignedAt: assignment.assigned_at&.iso8601,
            resolvedAt: assignment.resolved_at&.iso8601,
            rating: assignment.rating
            }
        }, status: :ok
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
        lastMessageAt: conversation.messages.order(created_at: :desc).first&.created_at&.iso8601,
        unreadCount: conversation.messages.where(is_read: false).where.not(sender_id: @current_user.id).count
        }
    end
end
