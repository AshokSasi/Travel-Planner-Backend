class TripAgentMessage < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :trip
  belongs_to :user, optional: true
  has_one :proposal, class_name: "TripAgentProposal", dependent: :destroy

  validates :role, inclusion: { in: ROLES }

  def as_json(*)
    {
      id: id.to_s,
      role: role,
      content: content,
      user: user && { id: user.id.to_s, name: user.name, avatar_url: user.avatar_url },
      proposal: proposal&.as_json,
      created_at: created_at
    }
  end
end
