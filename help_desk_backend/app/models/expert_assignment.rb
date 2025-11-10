class ExpertAssignment < ApplicationRecord
    belongs_to :expert, class_name: 'ExpertProfile'
    belongs_to :conversation
end
