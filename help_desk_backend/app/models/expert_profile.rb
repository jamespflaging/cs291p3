class ExpertProfile < ApplicationRecord
    belongs_to :user, class_name: 'User'

    has_many :expert_assignments, foreign_key: :expert_id
end
