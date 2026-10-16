class CleaningLog < ApplicationRecord
  enum :status, { started: 0, finished: 1, approved: 2, rejected: 3 }

  belongs_to :room
  belongs_to :stay, optional: true
  belongs_to :cleaned_by, class_name: "User"
  belongs_to :inspected_by, class_name: "User", optional: true

  scope :recent, -> { order(created_at: :desc) }
  scope :for_room, ->(room) { where(room: room).recent }
  scope :pending_inspection, -> { where(status: :finished) }

  validates :room, :cleaned_by, presence: true
  validates :status, presence: true

  def finish!(user:, notes: nil)
    update!(
      status: :finished,
      finished_at: Time.current,
      cleaned_by: user,
      notes: notes
    )
    room.finish_cleaning! if room.may_finish_cleaning?
  end

  def approve!(user:, notes: nil)
    update!(
      status: :approved,
      inspected_at: Time.current,
      inspected_by: user,
      notes: notes
    )
    room.release_from_quarantine! if room.may_release_from_quarantine?
  end

  def reject!(user:, reason:)
    update!(
      status: :rejected,
      inspected_at: Time.current,
      inspected_by: user,
      rejection_reason: reason,
      notes: reason
    )
    room.start_cleaning! if room.may_start_cleaning?
  end

  def duration_minutes
    return nil unless started_at && finished_at
    ((finished_at - started_at) / 60).to_i
  end
end
