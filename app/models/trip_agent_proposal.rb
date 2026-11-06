class TripAgentProposal < ApplicationRecord
  STATUSES = %w[pending applied discarded stale].freeze

  belongs_to :trip
  belongs_to :trip_agent_message
  belongs_to :resolved_by, class_name: "User", optional: true

  validates :status, inclusion: { in: STATUSES }

  def pending?
    status == "pending"
  end

  def resolve!(status, user, applied_change_ids: [])
    update!(status: status, resolved_by: user, resolved_at: Time.current, applied_change_ids: applied_change_ids)
  end

  # Strip the internal fingerprint fields before sending changes to the client
  def as_json(*)
    {
      id: id.to_s,
      status: status,
      changes: changes_list.map { |change| change.except("item_updated_at") },
      applied_change_ids: applied_change_ids,
      resolved_by: resolved_by && { id: resolved_by.id.to_s, name: resolved_by.name },
      resolved_at: resolved_at
    }
  end
end
