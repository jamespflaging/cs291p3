class Message < ApplicationRecord
  belongs_to :sender, class_name: 'User'
  belongs_to :conversation

  enum :sender_role, {initiator: "initiator", expert: "expert"}
end
