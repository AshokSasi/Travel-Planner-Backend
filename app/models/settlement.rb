class Settlement < ApplicationRecord
  belongs_to :trip
  belongs_to :user
  belongs_to :receiver, class_name: "User"
end
