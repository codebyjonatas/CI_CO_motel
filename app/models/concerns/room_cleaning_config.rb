module RoomCleaningConfig
  DEFAULTS = {
    quarantine_minutes: 30
  }.freeze

  module_function

  def config
    Rails.application.credentials.room_cleaning || {}
  end

  def quarantine_minutes
    config[:quarantine_minutes] || DEFAULTS[:quarantine_minutes]
  end

  def quarantine_duration
    quarantine_minutes.minutes
  end
end
