class User < ApplicationRecord
    has_one :expert_profile
    has_many :initiated_conversations, class_name: 'Conversation', foreign_key: :initiator_id
    has_many :expert_conversations, class_name: 'Conversation', foreign_key :assigned_expert_id
    has_many :messages, foreign_key: :sender_id
end
