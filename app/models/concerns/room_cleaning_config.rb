module RoomCleaningConfig
  DEFAULTS = {
    quarantine_minutes: 30
  }.freeze

  module_function

  def config
    base = (Rails.application.credentials.room_cleaning || {}).to_h.symbolize_keys
    env_minutes = ENV["ROOM_CLEANING_QUARANTINE_MINUTES"]
    env_minutes = nil if env_minutes.nil? || env_minutes.strip.empty?
    { quarantine_minutes: env_minutes&.to_i || base[:quarantine_minutes] }.compact
  end

  def quarantine_minutes
    config[:quarantine_minutes] || DEFAULTS[:quarantine_minutes]
  end

  def quarantine_duration
    quarantine_minutes.minutes
  end
end
