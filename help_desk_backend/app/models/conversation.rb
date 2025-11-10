class Conversation < ApplicationRecord
    belongs_to :initiator, class_name: 'User'
    belongs_to :assigned_expert, class_name: 'User', optional: true

    has_many :messages
    has_many :expert_assignments
end
